require 'nokogiri'
require 'fileutils'
require 'pathname'
require 'tempfile'
require 'zip'
require 'unf'

module Visualforce
  module Builder
    module Package
      def self.clean(app)
        FileUtils.rm_rf File.join app.root, app.config[:build_dir], 'package.xml'
      end

      def self.run(app)
        meta_names = {pages: 'ApexPage', staticresources: 'StaticResource'}

        package_xml = File.join app.root, app.config[:build_dir], 'package.xml'
        manifest = Nokogiri::XML File.new package_xml
        meta_names.each do |dir_name, type_name|
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.types {
              path = Pathname.new File.join app.root, app.config[:build_dir], dir_name.to_s
              Dir[File.join path, '**', '*-meta.xml'].each { |f|
                xml.members Pathname.new(f).relative_path_from(path).to_s.sub(/\.[^\-]+-meta\.xml/i, '')
              }
              xml.name type_name
            }
          end
          manifest.root.children.first.add_previous_sibling builder.to_xml save_with: Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION
        end
        File.open package_xml, 'wb' do |out|
          out << manifest.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::AS_XML)
        end
      end
    end

    module StaticResource
      def self.clean(app)
        Dir[File.join app.root, app.config[:build_dir], app.config[:staticresources_dir], '*.resource'].each do |f|
          FileUtils.rm_rf f
        end
      end

      def self.run(app)
        Dir[File.join app.root, app.config[:build_dir], app.config[:staticresources_dir], '*.resource-meta.xml']
            .reject { |f| app.config[:assets_staticresource] == File.basename(f, '.resource-meta.xml') }
            .reject { |f| File.file?(File.basename f, '.resource-meta.xml') }
            .map { |f|
          path = Pathname.new File.join File.dirname(f), File.basename(f, '.resource-meta.xml')
          file = Pathname.new File.join File.dirname(f), File.basename(f, '-meta.xml')
          {path: path, file: file, files: Dir[File.join path, '**', '*']}
        }
            .tap { |a|
          dir = Pathname.new File.join app.root, app.config[:build_dir], app.config[:staticresources_dir]
          files = Dir[File.join dir, '*']
                      .reject { |f| File.basename(f) =~ /\.resource-meta\.xml\Z/ }
                      .reject { |f| File.basename(f) =~ /\.resource\Z/ && File.exist?("#{f}-meta.xml") }
                      .map { |f| [f] + Dir[File.join f, '**', '*'] }
                      .flatten
          a << {path: dir, file: dir + "#{app.config[:assets_staticresource]}.resource", files: files}
        }
            .each { |a|
          path, file, files = a[:path], a[:file], a[:files]
          Tempfile.create '' do |tmpfile|
            Zip::File.open tmpfile.path, Zip::File::CREATE do |zip_file|
              files.each do |e|
                zip_file.add UNF::Normalizer.normalize(Pathname.new(e).relative_path_from(path).to_s, :nfc), e
              end
            end
            FileUtils.rm_rf file
            FileUtils.cp tmpfile.path, file
          end
        }
        Dir[File.join app.root, app.config[:build_dir], app.config[:staticresources_dir], '*']
            .reject { |f| File.basename(f) =~ /\.resource-meta\.xml\Z/ || File.basename(f) =~ /\.resource\Z/ }
            .each { |f| FileUtils.rm_rf f }
      end
    end
  end
end

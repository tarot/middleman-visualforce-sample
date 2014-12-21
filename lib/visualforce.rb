require File.join File.dirname(__FILE__), 'middleware'
require File.join File.dirname(__FILE__), 'apexremote'
require File.join File.dirname(__FILE__), 'builder'

module Visualforce
  class Extension < Middleman::Extension
    def initialize(app, options_hash={}, &block)
      super

      app.config[:pages_dir] ||= 'pages'
      app.config[:staticresources_dir] ||= 'staticresources'
      app.config[:assets_staticresource] ||= 'assets'
      app.config[:apexremote] ||= 'apexremote'

      app.config[:layouts_dir] = "#{app.config[:pages_dir]}/layouts"
      app.config[:css_dir] = "#{app.config[:staticresources_dir]}/css"
      app.config[:js_dir] = "#{app.config[:staticresources_dir]}/js"

      app.configure :development do
        app.use Visualforce::Middleware::Development, app
        app.map('/apexremote') { run ::ApexRemote }
      end

      app.before_build do
        Visualforce::Builder::StaticResource.clean app
        Visualforce::Builder::Package.clean app
      end

      app.after_build do
        Visualforce::Builder::StaticResource.run app
        Visualforce::Builder::Package.run app
      end
    end

    def after_configuration
      app.page '*.xml', layout: false
      app.ignore File.join app.config[:layouts_dir], '*'
      Dir[File.join app.root, app.config[:source], app.config[:pages_dir], '*.page.*'].each do |f|
        name = File.basename(f).sub /\.page(\..+)?\Z/i, ''
        app.proxy "/#{app.config[:pages_dir]}/#{name}.page-meta.xml", "/#{app.config[:pages_dir]}/#{name}.page", layout: 'meta'
      end
    end
  end
end
::Middleman::Extensions.register(:visualforce, Visualforce::Extension)

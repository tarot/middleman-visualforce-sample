require './lib/visualforce'

activate :dotenv
activate :visualforce

bower_components = Pathname.new File.join root, 'bower_components'
sprockets.append_path bower_components
%w(fonts icons).each do |folder|
  dir = Pathname.new File.join bower_components, 'bootstrap-sf1', 'dist'
  Dir[File.join dir, folder, '**', '*'].reject { |f| File.directory? f }.each do |f|
    sprockets.import_asset(Pathname.new(f).relative_path_from(bower_components)) {
      Pathname.new(config[:css_dir]) + '..' + Pathname.new(f).relative_path_from(dir)
    }
  end
end

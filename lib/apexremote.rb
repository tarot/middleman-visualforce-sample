require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/json'
require 'uri'

class ApexRemote < Sinatra::Base
  configure do
    register Sinatra::Reloader
  end

  get '/' do
    coffee File.new(File.join File.dirname(__FILE__), 'apexremote.coffee').read
  end

  post '/:action/:seq' do |action, seq|
    puts File.join File.dirname(__FILE__), URI(request.referrer).path, action, "#{seq}"
    request.body.rewind
    p JSON.parse request.body.read
    json([{Id: '123', Name: 'One Two Three', Email: '123@example.com', Phone: seq},
          {Id: '456', Name: 'Four Five Six', Email: '456@example.com', Phone: seq}])
  end
end

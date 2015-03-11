module Visualforce
  module Middleware
    class Development
      def initialize(app, middleman)
        @app = app
        @middleman = middleman
      end

      def call(env)
        code, headers, body = @app.call env
        if env['PATH_INFO'] =~ /\.page\Z/
          body = ''.tap { |s| body.each { |e| s << e } }.tap { |s| s.strip! }
          body.sub! %r{(<head(\s[^>]*)?>)}i, "\\1<script src=\"/#{@middleman.config[:apexremote]}/\"></script>"
          body.sub! %r{\A<apex:page(\s[^>]*)?>}i, ''
          body.sub! %r{</apex:page\s*>\Z}i, ''
          body.gsub! %r{<apex:remoteObjects(\s[^>]*)?>.*</apex:remoteObjects\s*>}i, ''
          body.gsub! /\{!\s*\$Site\.Prefix\s*\}/i, ''
          body.gsub! /\{!\s*\$Site\.Prefix\s*&\s*\$Page\.([^}\s]+)\s*\}/i, "/#{@middleman.config[:pages_dir]}/\\1.page"
          body.gsub! /\{!\s*\$Page\.([^}\s]+)\s*\}/i, "/#{@middleman.config[:pages_dir]}/\\1.page"
          body.gsub! /\{!\s*URLFOR\s*\(\s*\$Resource\.#{@middleman.config[:assets_staticresource]}\s*,\s*["']([^"']+)["']\s*\)\s*\}/i, "/#{@middleman.config[:staticresources_dir]}/\\1"
          body.gsub! /\{!\s*URLFOR\s*\(\s*\$Resource\.([^,\s]+)\s*,\s*["']([^"']+)["']\s*\)\s*\}/i, "/#{@middleman.config[:staticresources_dir]}/\\1/\\2"
          body = "<!doctype html>#{body}"
          headers['Content-Type'] = 'text/html'
          headers['Content-Length'] = body.bytesize.to_s
          body = [body]
        end
        [code, headers, body]
      end
    end
  end
end

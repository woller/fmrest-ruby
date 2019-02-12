require "fmrest/v1/token_session"
require "fmrest/v1/raise_errors"
require "uri"

module FmRest
  module V1
    BASE_PATH = "/fmi/data/v1/databases".freeze

    class << self
      def build_connection(options = FmRest.config, &block)
        base_connection(options) do |conn|
          conn.use RaiseErrors
          conn.use TokenSession, options

          conn.request :json

          if options[:log]
            conn.response :logger, nil, bodies: true, headers: true
          end

          # Allow overriding the default response middleware
          if block_given?
            yield conn
          else
            conn.response :json
          end

          conn.adapter Faraday.default_adapter
        end
      end

      def base_connection(options = FmRest.config, &block)
        host = options.fetch(:host)

        # Default to HTTPS
        scheme = "https"

        if host.match(/\Ahttps?:\/\//)
          uri = URI(host)
          host = uri.hostname
          host += ":#{uri.port}" if uri.port != uri.default_port
          scheme = uri.scheme
        end

        Faraday.new("#{scheme}://#{host}#{BASE_PATH}/#{URI.escape(options.fetch(:database))}/".freeze, &block)
      end

      def session_path(token = nil)
        url = "sessions"
        url += "/#{token}" if token
        url
      end

      def record_path(layout, id = nil)
        url = "layouts/#{URI.escape(layout.to_s)}/records"
        url += "/#{id}" if id
        url
      end

      def find_path(layout)
        "layouts/#{URI.escape(layout.to_s)}/_find"
      end

      #def globals_path
      #end
    end
  end
end

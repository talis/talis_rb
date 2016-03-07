module Talis
  module Authentication
    class Client
      HOST = "https://users.talisaspire.com"

      attr_reader :host, :client_id, :client_secret

      def initialize(opts={})
        acquire_host!(opts)
        acquire_credentials!

        authenticate!
      end

      def authenticated?
      end

      private

      def authenticate!
        url = "#{host}/clients/#{client_id}"
      end

      def acquire_host!(opts)
        @host = opts[:host] || HOST
      end

      def acquire_credentials!
        @client_id     = ENV['PERSONA_OAUTH_CLIENT']
        @client_secret = ENV['PERSONA_OAUTH_SECRET']
      end

    end
  end
end

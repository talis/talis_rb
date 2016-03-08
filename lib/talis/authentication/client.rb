require 'httparty'

module Talis
  module Authentication
    class Client
      include HTTParty
      
      attr_reader :host, :client_id, :client_secret, :token, :authenticated
      def initialize(token, opts={})
        @token = token
        acquire_host!(opts)
        acquire_credentials!

        response = authenticate!
        @authenticated = response.code == 200
      end

      def authenticated?
        authenticated
      end

      private

      def authenticate!
        self.class.get("/clients/#{client_id}",
                       :headers => {"Authorization" => bearer_token})
      end

      def bearer_token
        "Bearer #{token}"
      end

      def acquire_host!(opts)
        if opts[:host].present?
          self.class.base_uri(opts[:host])
        else
          self.class.base_uri(PERSONA_HOST)
        end
      end

      def acquire_credentials!
        @client_id     = ENV['PERSONA_OAUTH_CLIENT']
        @client_secret = ENV['PERSONA_OAUTH_SECRET']
      end

    end
  end
end

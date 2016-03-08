require 'httparty'

module Talis
  module Authentication
    class Client
      include HTTParty
      debug_output $stdout

      attr_reader :host, :client_id, :client_secret

      def initialize(opts={})
        acquire_host!(opts)
        acquire_credentials!

        authenticate!
        self
      end

      def authenticated?
      end

      private

      def authenticate!
        self.class.get("/clients/#{client_id}",
                       :headers => {"Authorization" => bearer_token})
      end

      def bearer_token
        "Bearer #{client_secret}"
      end

      def acquire_host!(opts)
        if opts[:host].present?
          self.class.base_uri(opts[:host])
        else
          self.class.base_uri("https://users.talisaspire.com")
        end
      end

      def acquire_credentials!
        @client_id     = ENV['PERSONA_OAUTH_CLIENT']
        @client_secret = ENV['PERSONA_OAUTH_SECRET']
      end

    end
  end
end

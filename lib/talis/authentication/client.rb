require 'httparty'

module Talis
  module Authentication
    # Represents an OAuth client
    class Client
      include HTTParty

      attr_reader :host, :client_id, :client_secret, :token, :scopes
      def initialize(token, opts = {})
        @token = token
        acquire_host!(opts)
        acquire_credentials!

        response = authenticate!
        body = JSON.parse response.body
        @scopes = body['scope']
        raise Talis::AuthenticationFailedError unless
            response.code == 200
      end

      def add_scope(scope)
        if scope.is_a? String
          response = modify_scope(:add, scope)
          @scopes << scope if response.code == 204
        end
      end

      def remove_scope(scope)
        if scope.is_a? String
          response = modify_scope(:remove, scope)
          @scopes.delete(scope) if response.code == 204
        end
      end

      def modify_scope(action, scope)
        action = case action
                 when :add
                   '$add'
                 when :remove
                   '$remove'
                 else
                   raise 'Unknown action'
                 end
        patch_client_scope(action, scope)
      end

      private

      def authenticate!
        self.class.get("/clients/#{client_id}",
                       headers: { 'Authorization' => bearer_token })
      end

      def bearer_token
        "Bearer #{token}"
      end

      def patch_client_scope(action, scope)
        self.class.patch("/clients/#{client_id}",
                         headers: {
                           'Content-Type' => 'application/json',
                           'Authorization' => bearer_token
                         },
                         body: { scope: { action => scope } }.to_json)
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

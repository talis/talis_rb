require 'active_support'
require 'jwt'
require 'openssl'

module Talis
  module Authentication
    # Represents a JWT-based OAuth access token.
    #
    # Optionally configure an ActiveSupport-based cache store for caching the
    # public key and tokens. The default cache used is an in-memory one.
    # See http://api.rubyonrails.org/classes/ActiveSupport/Cache.html for
    # supported cache types.
    # @example Using an in-memory cache.
    #   store = ActiveSupport::Cache::MemoryStore.new
    #   Talis::Authentication::Token.cache_store = store
    class Token < Talis::Resource
      base_uri Talis::PERSONA_HOST
      cattr_accessor :cache_store
      Token.cache_store = ActiveSupport::Cache::MemoryStore.new

      # Create a new token object from an existing JWT.
      # @param jwt [String] the encoded JWT.
      # @param public_key [PublicKey] (nil) Only used in unit tests.
      def initialize(jwt:, public_key: nil)
        @jwt = jwt
        @public_key = public_key || PublicKey.new(Token.cache_store)
      end

      # Validate the token, optionally against one or more required scopes.
      #
      # Scope validation is performed locally unless there are too many tokens
      # to list inside the token payload. When this is the case, a remote
      # request is performed to validate the token against the scopes.
      #
      # The validation error returned can be one of the following:
      # - `:expired_token` if the token has expired.
      # - `:insufficient_scope` if the provided scopes are not in the token.
      # - `:invalid_token` if the token could not be verified by the public
      #   key.
      # - `:invalid_token` if the token could not be decoded.
      # - `:invalid_key` if the public key is corrupt.
      # @param request_id [String] (uuid) unique ID for the remote request.
      # @param scopes [Array] Scope(s) that the token needs in order to be
      #   valid.
      # @param all [Boolean] (true) Whether or not all scopes must be present
      #   within the token for validation to pass. If false, only one matching
      #   scope is required.
      # @return [Symbol, Nil] nil iff the token is valid else a symbol error.
      # @raise [Talis::ServerError] if the sever cannot validate the
      #   scope.
      # @raise [Talis::ServerCommunicationError] for network issues.
      def validate(request_id: self.class.new_req_id, scopes: [], all: true)
        decoded = JWT.decode(@jwt, p_key(request_id), true, algorithm: 'RS256')
        validate_scopes(request_id, scopes, decoded[0], all)
      rescue JWT::ExpiredSignature
        return :expired_token
      rescue JWT::VerificationError, JWT::DecodeError
        return :invalid_token
      rescue NoMethodError
        return :invalid_key
      rescue Talis::ClientError
        :insufficient_scope
      end

      # @return [String] the encoded version of the token - a JWT string.
      def to_s
        @jwt
      end

      private

      def p_key(req_id)
        @public_key.fetch(request_id: req_id)
      end

      def validate_scopes(request_id, wanted_scopes, token, all_must_match)
        # The existence of this key means there are too many scopes to fit
        # into an encoded token, it must be fetched from the server
        token = fetch_token(request_id) if token.key? 'scopeCount'

        return :invalid_token unless token.key? 'scopes'
        provided_scopes = token['scopes']
        return nil if wanted_scopes.empty?
        return nil if provided_scopes.include? 'su'
        compare_scope_intersect(wanted_scopes, provided_scopes, all_must_match)
      end

      def compare_scope_intersect(wanted_scope, provided_scope, all_must_match)
        intersect_scope = (wanted_scope & provided_scope)
        if (all_must_match && intersect_scope != wanted_scope) ||
           intersect_scope.empty?
          :insufficient_scope
        end
      end

      def fetch_token(request_id)
        token_url = "/oauth/tokens/#{@jwt}"
        headers = { headers: { 'X-Request-Id' => request_id } }
        self.class.handle_response(self.class.get(token_url, headers))
      end

      class << self
        # Generate a new token for the given client.
        # If a previous token has been generated for the client and has not
        # expired then this will be returned from the cache.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param client_id [String] the client for whom this token is for.
        # @param client_secret [String] secret belonging to the client.
        # @param host [String] Optional persona host override for service
        # @return [Talis::Authentication::Token] the generated or cached token.
        # @raise [Talis::ClientError] if the client ID/secret are
        #   invalid.
        # @raise [Talis::ServerError] if the generation failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def generate(request_id: new_req_id, client_id:, client_secret:,
                     host: base_uri)
          token = cached_token(client_id, host)
          if token
            new(jwt: token)
          else
            generate_remote_token(request_id, client_id, client_secret, host)
          end
        end

        private

        def generate_remote_token(request_id, client_id, client_secret, host)
          response = create_token(request_id, client_id, client_secret, host)
          parsed_response = handle_response(response)
          cache_token(parsed_response, client_id, host)
          new(jwt: parsed_response['access_token'])
        end

        def digest_data(data)
          md4 = OpenSSL::Digest::MD4.new
          Base64.encode64(md4.digest(data))
        end

        def cache_key(client_id, host)
          "token:#{digest_data(client_id)}_#{digest_data(host)}"
        end

        def cache_token(data, client_id, host)
          access_token = data['access_token']
          # Expire the cache slightly before the token expires to cater for
          # communication delay between server issuing and client receiving.
          expiry_time = data['expires_in'].to_i - 5.seconds
          Token.cache_store.write(cache_key(client_id, host), access_token,
                                  expires_in: expiry_time)
        end

        def cached_token(client_id, host)
          key = cache_key(client_id, host)
          Token.cache_store.fetch(key) if Token.cache_store.exist?(key)
        end

        def create_token(request_id, client_id, client_secret, host)
          post(host + '/oauth/tokens',
               headers: { 'X-Request-Id' => request_id },
               body: {
                 client_id: client_id,
                 client_secret: client_secret,
                 grant_type: 'client_credentials'
               })
        rescue
          raise Talis::ServerCommunicationError
        end
      end
    end
  end
end

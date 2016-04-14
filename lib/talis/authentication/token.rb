require 'active_support'
require 'jwt'
require 'openssl'

module Talis
  module Authentication
    ##
    # Represents a JWT-based OAuth access token.
    #
    # Optionally configure an ActiveSupport-based cache store for caching the
    # public key and tokens. The default cache used is an in-memory one.
    # See http://api.rubyonrails.org/classes/ActiveSupport/Cache.html for
    # supported cache types.
    #
    #   store = ActiveSupport::Cache::MemoryStore.new
    #   Talis::Authentication::Token.cache_store = store
    #
    class Token
      include HTTParty
      extend Talis::HTTPHelper
      format :json
      base_uri Talis::PERSONA_HOST
      cattr_accessor :cache_store
      Token.cache_store = ActiveSupport::Cache::MemoryStore.new
      ##
      # Create a new token object from an existing JWT.
      #
      # *Arguments*
      # - +jwt+:: +String+ the encoded JWT.
      #
      def initialize(jwt:, public_key: nil)
        @jwt = jwt
        @test_public_key = public_key
      end

      ##
      # Validate the token, optionally against one or more required scopes.
      #
      # Scope validation is performed locally unless there are too many tokens
      # to list inside the token payload. When this is the case, a remote
      # request is performed to validate the token against the scopes.
      #
      # The validation error returned can be one of the following:
      # - +:expired_token+
      # - +:insufficient_scope:+ If the provided +scopes+ are not in the token.
      # - +:invalid_token+ If the token could not be verified by the public key.
      # - +:invalid_token+ If the token could not be decoded.
      # - +:invalid_key+ If the public key is corrupt.
      #
      # *Arguments*
      # - +scopes+:: +Array+ Scope(s) that the token needs in order to be valid.
      #
      # *Returns*
      # - +Nil+ If the token is valid.
      # - +Symbol+ If the token is invalid.
      #
      # *Raises*
      # - +Talis::Errors::ServerError+ If the sever cannot validate the scope.
      # - +Talis::Errors::ServerCommunicationError+ For network issues.
      #
      def validate(scopes = [])
        decoded = JWT.decode(@jwt, public_key, true, algorithm: 'RS256')
        validate_scopes(scopes, decoded[0])
      rescue JWT::ExpiredSignature
        return :expired_token
      rescue JWT::VerificationError, JWT::DecodeError
        return :invalid_token
      rescue NoMethodError
        return :invalid_key
      rescue Talis::Errors::ClientError
        :insufficient_scope
      end

      ##
      # *Returns*
      # - +String+ The encoded version of the token which is a JWT string.
      #
      def to_s
        @jwt
      end

      private

      def public_key
        # This should only ever return when being run in unit tests
        return @test_public_key if @test_public_key.present?
        cache_options = {
          expires_in: 7.minutes,
          race_condition_ttl: 10.seconds
        }
        public_key = Token.cache_store.fetch('public_key', cache_options) do
          response = self.class.get('/oauth/keys', format: :plain)
          self.class.handle_response(response)
        end
        OpenSSL::PKey.read(public_key)
      end

      def validate_scopes(wanted_scopes, token)
        # The existence of this key means there are too many scopes to fit
        # into an encoded token, it must be fetched from the server
        token = fetch_token if token.key? 'scopeCount'

        return :invalid_token unless token.key? 'scopes'
        provided_scopes = token['scopes']
        return nil if wanted_scopes.empty?
        return nil if provided_scopes.include? 'su'
        # This operation returns the intersect of the array
        if (wanted_scopes & provided_scopes) != wanted_scopes
          :insufficient_scope
        end
      end

      def fetch_token
        token_url = "/oauth/tokens/#{@jwt}"
        token = self.class.handle_response(self.class.get(token_url))
        # Persona returns scopes as a space-separated string
        token['scopes'] = token['scope'].split ' '
        token
      end

      class << self
        ##
        # Generate a new token for the given client.
        # If a previous token has been generated for the client and has not
        # expired then this will be returned from the cache.
        #
        # *Params*
        # - +client_id+:: +String+ The client for whom this token is for.
        # - +client_secret+:: +String+ Secret belonging to the client.
        #
        # *Raises*
        # - +Talis::Errors::ClientError+ If the client ID/secret are invalid.
        # - +Talis::Errors::ServerError+ If the generation failed on the server.
        # - +Talis::Errors::ServerCommunicationError+ For network issues.
        #
        # *Returns*
        # - +Talis::Authentication::Token+ The generated or cached token.
        #
        def generate(client_id:, client_secret:)
          token = cached_token(client_id, client_secret)
          generate_remote_token(client_id, client_secret) if token.nil?
        end

        private

        def generate_remote_token(client_id, client_secret)
          response = create_token(client_id, client_secret)
          parsed_response = handle_response(response)
          cache_token(parsed_response, client_id, client_secret)
          new(jwt: parsed_response['access_token'])
        end

        def digest_data(data, secret)
          digest = OpenSSL::Digest.new('sha256')
          OpenSSL::HMAC.hexdigest(digest, data, secret)
        end

        def cache_token(data, client_id, client_secret)
          access_token = data['access_token']
          # Expire the cache slightly before the token expires to cater for
          # communication delay between server issuing and client receiving.
          expiry_time = data['expires_in'] - 5.seconds
          Token.cache_store.write(digest_data(client_id, client_secret),
                                  access_token, expires_in: expiry_time)
        end

        def cached_token(client_id, client_secret)
          key = digest_data(client_id, client_secret)
          Token.cache_store.fetch(key) if Token.cache_store.exist?(key)
        end

        def create_token(client_id, client_secret)
          post('/oauth/tokens',
               body: {
                 client_id: client_id,
                 client_secret: client_secret,
                 grant_type: 'client_credentials'
               }
              )
        rescue
          raise Talis::Errors::ServerCommunicationError
        end
      end
    end
  end
end

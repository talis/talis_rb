require 'active_support'
require 'talis/authentication/token'

module Talis
  module Authentication
    # Provides the ability to fetch a public key to verify tokens.
    # There is no need to use this class directly as it is used by the Token
    # class to verify tokens.
    class PublicKey < Talis::Resource
      base_uri Token.base_uri

      # Construct an empty public key object.
      # @param cache_store [ActiveSupport::Cache::MemoryStore] A cache
      #  store to use to fetch locally cached keys before trying remotely.
      def initialize(cache_store)
        @cache_store = cache_store
      end

      # Fetch a public key for use with token verification, either from
      # the provided cache or remotely.
      # @param request_id [String] (uuid) unique ID for the remote request.
      # @return [String] the public key.
      def fetch(request_id: self.class.new_req_id)
        # Token base URI may have changed after the class was loaded.
        self.class.base_uri(Token.base_uri)
        public_key = @cache_store.fetch(cache_key, cache_options) do
          opts = { format: :plain, headers: { 'X-Request-Id' => request_id } }
          response = self.class.get('/oauth/keys', opts)
          self.class.handle_response(response)
        end
        OpenSSL::PKey.read(public_key)
      end

      private

      def digest_data(data)
        md4 = OpenSSL::Digest::MD4.new
        Base64.encode64(md4.digest(data))
      end

      def cache_key
        "public_key:#{digest_data(self.class.base_uri)}"
      end

      def cache_options
        {
          expires_in: ENV.fetch('PUBLIC_KEY_EXPIRY_SECONDS', 7.minutes),
          race_condition_ttl: 10.seconds
        }
      end
    end
  end
end

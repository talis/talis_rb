require 'active_support/cache'
require 'jwt'
require 'openssl'
require_relative '../spec_helper'

describe Talis::Authentication::Token do
  let(:cache_store) do
    cache_store = ActiveSupport::Cache::MemoryStore.new
    Talis::Authentication::Token.cache_store = cache_store
    cache_store
  end

  before do
    Talis::Authentication::Token.base_uri(persona_base_uri)
    Talis::Authentication::Token.cache_store.clear
  end

  context 'generating tokens' do
    it 'is able to generate a valid token' do
      token = generate_token

      expect(token.validate).to be_nil
    end

    it 'raises the correct error given an invalid client ID' do
      expected_error = Talis::Errors::ClientError
      msg = 'The client credentials are invalid'
      options = {
        client_id: 'invalid',
        client_secret: client_secret
      }

      expect { generate_token(options) }.to raise_error expected_error, msg
    end

    it 'raises the correct error given an invalid client secret' do
      expected_error = Talis::Errors::ClientError
      msg = 'The client credentials are invalid'
      options = {
        client_id: client_id,
        client_secret: 'invalid'
      }

      expect { generate_token(options) }.to raise_error expected_error, msg
    end

    it 'raises the correct error when unable to communicate with the server' do
      Talis::Authentication::Token.base_uri('http://foo')

      expected_error = Talis::Errors::ServerCommunicationError
      options = {
        client_id: client_id,
        client_secret: client_secret
      }

      expect { generate_token(options) }.to raise_error expected_error
    end

    it 'caches tokens securely' do
      digest = OpenSSL::Digest.new('sha256')
      cache_key = OpenSSL::HMAC.hexdigest(digest, client_id, client_secret)

      expect(cache_store.fetch(cache_key)).to be_nil

      generate_token

      expect(cache_store.fetch(cache_key)).not_to be_nil

      generate_token

      expected_url = "#{persona_base_uri}/oauth/tokens"
      expect(a_request(:post, expected_url)).to have_been_made.once
    end
  end

  context 'caching public keys' do
    it 'uses the cache to retrieve the key when it is present' do
      expect(cache_store.fetch('public_key')).to be_nil

      generated_token = generate_token
      token = Talis::Authentication::Token.new(jwt: generated_token.to_s)

      # Cache is cold - the key will be fetched remotely.
      # Asserting that validation passes also means the key is correct.
      expect(token.validate).to be_nil

      # Now the cache should be warm.
      expect(cache_store.fetch('public_key')).not_to be_nil

      # Now validate again, the cache should be used, not a remote request.
      expect(token.validate).to be_nil
      expected_url = "#{persona_base_uri}/oauth/keys"
      expect(a_request(:get, expected_url)).to have_been_made.once
    end
  end

  context 'retrieving tokens' do
    pending
  end

  context 'revoking tokens' do
    pending
  end

  context 'verifying tokens remotely' do
    pending
  end

  private

  def generate_token(options = nil)
    if options.nil?
      options = {
        client_id: client_id,
        client_secret: client_secret
      }
    end
    Talis::Authentication::Token.generate(options)
  end

  def fetch_token(token)
    Talis::Authentication::Token.fetch(token: token)
  end

  def persona_base_uri
    ENV['PERSONA_TEST_HOST']
  end

  def client_id
    ENV['PERSONA_OAUTH_CLIENT']
  end

  def client_secret
    ENV['PERSONA_OAUTH_SECRET']
  end
end

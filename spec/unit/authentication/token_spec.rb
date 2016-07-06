require 'jwt'
require 'openssl'
require_relative '../spec_helper'

describe Talis::Authentication::Token do
  let(:private_key) { OpenSSL::PKey::RSA.generate 2048 }
  let(:public_key) { private_key.public_key }
  let(:cache_store) do
    cache_store = ActiveSupport::Cache::NullStore.new
    Talis::Authentication::Token.cache_store = cache_store
    cache_store
  end

  before do
    Talis::Authentication::Token.cache_store.clear
  end

  context 'generating tokens' do
    it 'raises the correct error when the server responds with an error' do
      stub_request(:post, %r{oauth/tokens}).to_return(status: [500])

      expect { generate_token }.to raise_error Talis::Errors::ServerError
    end

    it 'raises the correct error when the response is an unknown error' do
      stub_request(:post, %r{oauth/tokens}).to_return(status: [0])

      expected_error = Talis::Errors::ServerCommunicationError
      expect { generate_token }.to raise_error expected_error
    end
  end

  context 'verifying valid tokens locally' do
    it 'returns no error when the token is valid' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate).to be_nil
    end

    it 'returns no error when the token contains the provided scope' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate(scopes: ['abc123'])).to be_nil
    end

    it 'returns no error when the token contains all of the provided scopes' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123', 'def:345']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate(scopes: ['abc123', 'def:345'])).to be_nil
    end

    it 'returns no error when the token contains one of the provided scopes' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123', 'def:345']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)
      result = token.validate(scopes: ['abc123', 'another:scope'], all: false)

      expect(result).to be_nil
    end

    it 'returns no error when the token contains su scope asking for another' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['su']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate(scopes: ['abc123', 'def:345'])).to be_nil
    end
  end

  context 'verifying invalid tokens locally' do
    it 'returns expiration error when the token has expired' do
      payload = {
        exp: Time.now.to_i - 60,
        scopes: ['abc123']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate).to eq :expired_token
      true
    end

    it 'returns validation error when the token has been tampered with' do
      tampered_key = OpenSSL::PKey::RSA.generate 2048
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123']
      }
      jwt = JWT.encode(payload, tampered_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate).to eq :invalid_token
      true
    end

    it 'returns validation error when the token scopes are invalid' do
      payload = {
        exp: Time.now.to_i + 60,
        scpes: ['abc123']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate(scopes: ['abc123'])).to eq :invalid_token
      true
    end

    it 'returns key error when the public key is invalid' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: 'invalid'
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate).to eq :invalid_key
      true
    end

    it 'returns validation error when the token is not a token' do
      options = {
        jwt: 'invalid',
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate).to eq :invalid_token
      true
    end

    it 'returns scope error when the token does not have the provided scope' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      expect(token.validate(scopes: ['def:456'])).to eq :insufficient_scope
    end

    it 'returns an error when token doesn`t have all of the provided scopes' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123', 'def:456']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      error = token.validate(scopes: ['def:456', 'another:scope'])
      expect(error).to eq :insufficient_scope
    end

    it 'returns an error when token doesn`t have any of the provided scopes' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123', 'def:456']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }

      token = Talis::Authentication::Token.new(options)

      error = token.validate(scopes: ['ghi:789', 'another:scope'], all: false)
      expect(error).to eq :insufficient_scope
    end

    it 'raises an error when there is a problem fetching the public key' do
      payload = {
        exp: Time.now.to_i + 60,
        scopes: ['abc123']
      }
      jwt = JWT.encode(payload, private_key, 'RS256')

      token = Talis::Authentication::Token.new(jwt: jwt)

      stub_request(:get, %r{oauth/keys}).to_return(status: [500])

      expected_error = Talis::Errors::ServerError
      expect { token.validate }.to raise_error expected_error
    end
  end

  context 'validating tokens with too many scopes' do
    it 'returns no error when the token contains the provided scope' do
      payload = {
        exp: Time.now.to_i + 60,
        scopeCount: 26
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }
      scopes = random_scopes
      required_scope = scopes.split(' ').first

      token = Talis::Authentication::Token.new(options)

      fake_token_body = {
        expires: payload[:exp],
        scope: scopes,
        access_token: token
      }.to_json
      fake_response = {
        headers: { 'Content-Type' => 'application/json' },
        body: fake_token_body
      }
      stub_request(:get, %r{oauth/tokens}).to_return(fake_response)

      expect(token.validate(scopes: [required_scope])).to be_nil
    end

    it 'raises an error when the server returns an error' do
      payload = {
        exp: Time.now.to_i + 60,
        scopeCount: 26
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }
      scopes = random_scopes
      required_scope = { scopes: [scopes.split(' ').first] }

      token = Talis::Authentication::Token.new(options)

      stub_request(:get, %r{oauth/tokens}).to_return(status: [503])

      expected_error = Talis::Errors::ServerError
      expect { token.validate(required_scope) }.to raise_error expected_error
    end

    it 'returns scope error when the server returns a bad request' do
      payload = {
        exp: Time.now.to_i + 60,
        scopeCount: 26
      }
      jwt = JWT.encode(payload, private_key, 'RS256')
      options = {
        jwt: jwt,
        public_key: public_key
      }
      scopes = random_scopes
      required_scope = scopes.split(' ').first

      token = Talis::Authentication::Token.new(options)

      stub_request(:get, %r{oauth/tokens}).to_return(status: [400])

      expect(token.validate(scopes: [required_scope])).to be :insufficient_scope
    end
  end

  private

  def generate_token
    options = {
      client_id: client_id,
      client_secret: client_secret
    }
    Talis::Authentication::Token.generate(options)
  end

  def random_scopes(n = 26)
    (0..n).map { ('a'..'z').to_a.sample(5).join }.join(' ')
  end
end

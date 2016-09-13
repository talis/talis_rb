require 'base64'
require 'digest'
require 'ostruct'
require_relative '../spec_helper'

describe Talis::Authentication::Login do
  let(:user_double) { class_double('Talis::User').as_stubbed_const }

  context 'when correctly configured' do
    before do
      Talis::Authentication::Login.base_uri 'http://persona'
      options = {
        app_id: 'test-app',
        secret: 'sssh',
        provider: 'trapdoor',
        redirect_uri: 'http://example.com'
      }
      @login = Talis::Authentication::Login.new(options)
    end

    context 'before login' do
      it 'returns the correct login URL for the given provider and app' do
        expected_url = %r{
          http:\/\/persona\/auth\/providers\/trapdoor\/login
          \?app=test-app&redirectUri=http%3A%2F%2Fexample\.com&state=.*
        }x
        expect(@login.generate_url).to match expected_url
      end

      it 'returns the correct login URL when a user profile is required' do
        expected_url = %r{
          http:\/\/persona\/auth\/providers\/trapdoor\/login
          \?app=test-app&redirectUri=http%3A%2F%2Fexample\.com
          &require=profile&state=.*
        }x
        expect(@login.generate_url(require: :profile)).to match expected_url
      end

      it 'returns the redirect URI' do
        expect(@login.redirect_uri).to eq 'http://example.com'
      end
    end

    context 'after a successful login' do
      it 'validates the login given a valid payload' do
        allow(user_double).to receive(:build)

        options = generate_post_login_options(valid_login_data)

        @login.validate!(options)

        expect(@login.valid?).to be true
        expect(@login.error).to be_nil
      end

      it 'validates the login give a payload with an empty profile' do
        allow(user_double).to receive(:build)

        data = valid_login_data
        data[:profile] = nil

        options = generate_post_login_options(data)

        @login.validate!(options)

        expect(@login.valid?).to be true
        expect(@login.error).to be_nil
      end

      it 'returns the logged-in user' do
        expect(user_double).to receive(:build) do |login_data|
          # Shortcut the work Talis::Authentication::Token would do for real.
          login_data[:token] = login_data[:access_token]
          OpenStruct.new(login_data)
        end

        options = generate_post_login_options(valid_login_data)

        @login.validate!(options)

        expect(@login.user.guid).to eq 'abc123'
        expect(@login.user.token.to_s).to eq 'jwt_token'
        expect(@login.user.first_name).to eq 'Jane'
        expect(@login.user.surname).to eq 'Doe'
        expect(@login.user.email).to eq 'jane.doe@example.com'
      end

      it 'returns the redirect URI' do
        allow(user_double).to receive(:build)

        options = generate_post_login_options(valid_login_data)

        @login.validate!(options)

        expect(@login.redirect_uri).to eq 'http://example.com'
      end

      it 'handles bad user data with nil values' do
        expect(user_double).to receive(:build) do |login_data|
          guid_only = login_data.select { |key| !['guid'].include?(key) }
          OpenStruct.new(guid_only)
        end

        login_data = {
          guid: 'abc123',
          redirect: 'http://example.com'
        }

        options = generate_post_login_options(login_data)

        @login.validate!(options)

        expect(@login.user.guid).to eq 'abc123'
        expect(@login.user.token).to be_nil
        expect(@login.user.first_name).to be_nil
        expect(@login.user.surname).to be_nil
        expect(@login.user.email).to be_nil
      end
    end

    context 'after an invalid login' do
      before do
        expect(user_double).not_to receive(:build)
      end

      it 'invalidates the login when the provided payload is not a hash' do
        options = { payload: 'invalid', state: 'not testing here' }
        @login.validate!(options)

        expect(@login.valid?).to be false
        expect(@login.error).to eq 'payload is not a hash'
      end

      it 'invalidates the login when the payload has an incorrect key' do
        options = {
          payload: { 'invalid:key' => 'invalid' }, state: 'not testing here'
        }
        @login.validate!(options)

        expect(@login.valid?).to be false
        expect(@login.error).to eq 'payload missing key persona:payload'
      end

      it 'invalidates the login when the decoded payload is not JSON' do
        options = {
          payload: { 'persona:payload' => 'invalid' }, state: 'not testing here'
        }
        @login.validate!(options)

        expect(@login.valid?).to be false
        expect(@login.error).to eq 'payload is not valid JSON'
      end

      it 'invalidates when the payload state does not match the provided' do
        # There is more data that is provided from persona but we only care
        # about these attributes here
        login_data = {
          guid: 'abc123',
          token: {
            access_token: 'jwt_token'
          },
          profile: {
            first_name: 'Jane',
            surname: 'Doe',
            email: 'jane.doe@example.com'
          },
          redirect: 'http://example.com',
          state: 'imposter'
        }
        invalid_payload = Base64.encode64(login_data.to_json)
        options = {
          payload: { 'persona:payload' => invalid_payload }, state: 'def345'
        }

        @login.validate!(options)

        expect(@login.valid?).to be false
        expect(@login.error).to eq 'payload state does not match provided'
      end

      it 'invalidates when the payload signature does not match the provided' do
        # There is more data that is provided from persona but we only care
        # about these attributes here
        login_data = {
          guid: 'abc123',
          token: {
            access_token: 'jwt_token'
          },
          profile: {
            first_name: 'Jane',
            surname: 'Doe',
            email: 'jane.doe@example.com'
          },
          redirect: 'http://example.com',
          state: 'def345',
          signature: 'fake'
        }
        invalid_payload = Base64.encode64(login_data.to_json)
        options = {
          payload: { 'persona:payload' => invalid_payload }, state: 'def345'
        }

        @login.validate!(options)

        expect(@login.valid?).to be false
        expect(@login.error).to eq 'payload signature does not match expected'
      end

      it 'returns no logged-in user' do
        options = { payload: 'invalid', state: 'not testing here' }
        @login.validate!(options)

        expect(@login.user).to be_nil
      end
    end

    context 'logging out' do
      it 'returns the correct logout URL for the given redirect parameter' do
        expected_url = 'http://persona/auth/logout?redirectUri=http://foo.bar'
        redirect_url = 'http://foo.bar'

        expect(@login.logout_url(redirect_url)).to eq expected_url
      end
    end
  end

  context 'when missing mandatory options' do
    variations = [
      {
        options: {
          secret: 'sssh', provider: 'trapdoor', redirect_uri: 'http://r.com'
        },
        missing_option: 'app_id'
      },
      {
        options: {
          app_id: 'test-app', provider: 'trapdoor', redirect_uri: 'http://r.com'
        },
        missing_option: 'secret'
      },
      {
        options: {
          app_id: 'test-app', secret: 'sssh', redirect_uri: 'http://r.com'
        },
        missing_option: 'provider'
      },
      {
        options: {
          app_id: 'test-app', secret: 'sssh', provider: 'trapdoor'
        },
        missing_option: 'redirect_uri'
      }
    ]
    variations.each do |variation|
      option = variation[:missing_option]
      it "raises an error when the option #{option} is missing" do
        expect { Talis::Authentication::Login.new(variation[:options]) }.to(
          raise_error(ArgumentError)
        )
      end
    end
  end

  private

  def generate_post_login_options(login_data)
    @login.generate_url
    # User goes off to complete login with the provider and Persona calls us
    # with the payload...
    # state will be stored in a session before logging in then retrieved
    # after.
    login_data[:state] = @login.state

    # Persona signs the login request
    digest = OpenSSL::Digest.new('sha256')

    # When Persona encodes the JSON, forward slashes are escaped
    signature = OpenSSL::HMAC.hexdigest(
      digest, 'sssh', login_data.to_json.gsub('/', '\/')
    )
    login_data[:signature] = signature

    valid_payload = Base64.encode64(login_data.to_json.gsub('/', '\/'))
    { payload: { 'persona:payload' => valid_payload }, state: @login.state }
  end

  def valid_login_data
    {
      guid: 'abc123',
      token: { access_token: 'jwt_token' },
      profile: {
        first_name: 'Jane',
        surname: 'Doe',
        email: 'jane.doe@example.com'
      },
      redirect: 'http://example.com'
    }
  end
end

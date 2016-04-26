require 'base64'
require 'date'
require 'digest'
require 'multi_json'
require 'uuid'

module Talis
  module Authentication
    # Represents the user login flow for server-side applications.
    # A prerequisite to using this class is having an application registered
    # with Persona in order to obtain an app ID and secret. Application
    # registration also provides Persona a callback URL to POST the login
    # response back to the application.
    # @example Redirect user to authentication provider.
    #  # First create a login object and redirect the user, storing the state:
    #  options = {
    #    app_id: 'my_app',
    #    app_secret: 'my_secret',
    #    provider: 'google',
    #    redirect_uri: 'https://my_app/secret_area'
    #  }
    #  login = Talis::Authentication::Login.new(options)
    #  url = login.generate_url
    #  session[:state] = login.state
    #  redirect_to url
    # @example Handle data after user has logged in.
    #  # After the user has logged in, handle the POST callback:
    #  state = session.delete(:state)
    #  login.validate!(payload: params, state: state)
    #  if login.valid?
    #    session[:current_user_id] = login.user.guid
    #    redirect_to login.redirect_uri
    #  else
    #    # handle invalid login
    #    puts login.error
    #  end
    # @example Logging out a user.
    #  # When a user logs out, make sure to clean up the session:
    #  session.delete(:current_user_id)
    #  redirect_to login.logout_url('some/logout/path')
    class Login
      include HTTParty
      # @return [String] a non-guessable alphanumeric string used to prevent
      #   CSRF attacks. Store this in the user session after generating a
      #   login URL.
      attr_reader :state
      # @return [Talis::User] the logged-in user. This will be nil unless
      #   validation has passed.
      attr_reader :user
      # @return [String] if present, this will be the reason why the login
      #   failed.
      attr_reader :error

      base_uri Talis::PERSONA_HOST

      # Creates a new login object to manage the login flow.
      # @param app_id [String] ID of the application registered to Persona.
      # @param secret [String] secret of the application registered to Persona.
      # @param provider [String] name of the auth provider to use for login.
      # @param redirect_uri [String] where to redirect back to after login.
      def initialize(app_id:, secret:, provider:, redirect_uri:)
        @uuid = UUID.new

        @app = app_id
        @secret = secret
        @provider = provider
        @redirect_uri = redirect_uri
      end

      # Use this URL to redirect the user wishing to login to their auth
      # provider. After generating the URL the state will be available to
      # store in a session.
      # @return [String] the generated URL.
      def generate_url
        @state = Digest::MD5.hexdigest("#{@app}::#{@uuid.generate}")
        params = URI.encode_www_form(
          app: @app,
          state: @state,
          redirectUri: @redirect_uri
        )
        "#{self.class.base_uri}/auth/providers/#{@provider}/login?#{params}"
      end

      # Validate a login request after the user has logged in to their auth
      # provider. Validation will fail if the provided payload:
      # - Is not a hash.
      # - When decoded, contains invalid JSON.
      # - Has no state or the state it contains does not match the param state.
      # - Has an invalid signature.
      # If validation succeeds, the #user attribute will return the
      # logged-in user. If it fails, check the #error attribute for the
      # reason why.
      # @param payload [Hash] the payload POSTed to the application server.
      # @param state [String] use the value stored at the start of the session.
      def validate!(payload:, state:)
        return @error = 'payload is not a hash' unless payload.is_a? Hash

        key = 'persona:payload'
        return @error = "payload missing key #{key}" unless payload.key? key

        @payload = decode_and_parse_payload(payload)
        return @error = 'payload is not valid JSON' if @payload.nil?

        state_error = 'payload state does not match provided'
        return @error = state_error if @payload['state'] != state

        signature_error = 'payload signature does not match expected'
        return @error = signature_error unless signature_valid?(@payload)

        @user = build_user(@payload)
      end

      # Indicate whether or not the login succeeded.
      # @return [Boolean] true if the login is valid, otherwise false.
      def valid?
        @error.nil?
      end

      # The redirect to follow once login has successfully completed.
      # @return [String] the URL to redirect to.
      def redirect_uri
        @payload.present? ? @payload['redirect'] : @redirect_uri
      end

      # Logs a user out by terminating the session with Persona.
      # @param redirect_url [String] where to return the user on logout.
      # @return [String] the URL to redirect the user to when logging out.
      def logout_url(redirect_url)
        "#{self.class.base_uri}/auth/logout?redirectUri=#{redirect_url}"
      end

      private

      def build_user(data)
        profile = data.fetch('profile', {})
        Talis::User.build(guid: data['guid'],
                          first_name: profile['first_name'],
                          surname: profile['surname'],
                          email: profile['email'],
                          access_token: data.fetch('token', {})['access_token']
                         )
      end

      def decode_and_parse_payload(payload)
        begin
          json = MultiJson.load(Base64.decode64(payload['persona:payload']))
        rescue MultiJson::LoadError
          return nil
        end
        json
      end

      def signature_valid?(payload)
        received_signature = payload.delete('signature')

        # Persona PHP code escapes forward slashes when encoding JSON
        json_payload = payload.to_json.gsub('/', '\/')

        digest = OpenSSL::Digest.new('sha256')
        signature = OpenSSL::HMAC.hexdigest(digest, @secret, json_payload)
        received_signature == signature
      end
    end
  end
end

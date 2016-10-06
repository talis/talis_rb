require 'active_support'
require 'talis/authentication/token'

module Talis
  # Represents a user known by Talis.
  class User < Talis::Resource
    base_uri Talis::PERSONA_HOST
    # @return [String] the globally unique identifier for the user.
    attr_reader :guid
    # @return [String] the user's first name.
    attr_reader :first_name
    # @return [String] the user's surname.
    attr_reader :surname
    # @return [String] the user's E-mail address.
    attr_reader :email
    # @return [Talis::Authentication::Token] to use for user authentication
    #   with other Talis primitive services.
    attr_reader :token

    private_class_method :new

    # Creates a new user object. For internal use only, use {User.build}.
    # @param guid [String] the globally unique identifier for the user.
    # @param first_name [String] the user's first name.
    # @param surname [String] the user's surname.
    # @param email [String] the user's E-mail address.
    # @param token [Talis::Authentication::Token] (nil) valid user token.
    def initialize(guid:, first_name:, surname:, email:, token: nil)
      @guid = guid
      @first_name = first_name
      @surname = surname
      @email = email
      @token = token
    end

    # Return the combination of the user's first and surname.
    # @return [String] the user's full name
    def full_name
      "#{@first_name} #{@surname}"
    end

    # Returns a URL that will resolve to an avatar image belonging to the
    # user when fetched. This URL is cached by browsers when called.
    # @param size [Integer] (nil) size in pixels (defaults to 70x70).
    # @param colour [String] (nil) background hex colour (defaults to 000000).
    # @return [String] the URL of the user's avatar.
    def avatar_url(size: nil, colour: nil)
      if size.present? && colour.present?
        params = "?#{URI.encode_www_form(size: size, colour: colour)}"
      elsif size.present?
        params = "?#{URI.encode_www_form(size: size)}"
      elsif colour.present?
        params = "?#{URI.encode_www_form(colour: colour)}"
      end
      "#{self.class.base_uri}/users/#{guid}/avatar#{params}"
    end

    class << self
      # Find a single user given the search criterion.
      # In order to perform this search, the client must be configured with a
      # valid OAuth client that is allowed to search for users:
      #
      #  Talis::Authentication.client_id = 'client_id'
      #  Talis::Authentication.client_secret = 'client_secret'
      #
      # @param request_id [String] ('uuid') unique ID for the remote request.
      # @param guid [String] the globally unique ID of the user to find.
      # @return [User]
      def find(request_id: new_req_id, guid:)
        response = get("/users/#{guid}",
                       headers: {
                         'X-Request-Id' => request_id,
                         'Authorization' => "Bearer #{token}"
                       })
        new(extract_user_data(handle_response(response)))
      rescue Talis::NotFoundError
        nil
      end

      # Builds a new user object. This is for creating user objects as a
      # result of a successful login request.
      # @param guid [String] the globally unique identifier for the user.
      # @param first_name [String] the user's first name.
      # @param surname [String] the user's surname.
      # @param email [String] the user's E-mail address.
      # @param access_token [String] (nil) valid user JWT.
      # @return [User]
      def build(guid:, first_name:, surname:, email:, access_token: nil)
        options = {
          guid: guid,
          first_name: first_name,
          surname: surname,
          email: email,
          token: Talis::Authentication::Token.new(jwt: access_token)
        }
        new(options)
      end

      private

      def extract_user_data(data)
        profile = data.fetch('profile', {})
        {
          guid: data['guid'],
          first_name: profile['first_name'],
          surname: profile['surname'],
          email: profile['email']
        }
      end
    end
  end
end

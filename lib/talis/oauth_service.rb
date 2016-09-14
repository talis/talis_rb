module Talis
  # Allows an individual primitive service to set its own Persona environment
  module OAuthService
    attr_accessor :oauth_host, :client_id, :client_secret

    protected

    # Overrides Talis::Resource.token
    def token
      options = {
        client_id: client_id || Talis::Authentication.client_id,
        client_secret: client_secret || Talis::Authentication.client_secret
      }
      options[:host] = oauth_host if oauth_host
      Talis::Authentication::Token.generate(options)
    end
  end
end

module Talis
  module Authentication
    class Token
      include HTTParty

      def self.generate(opts={})
        acquire_host!(opts)
        token_request = post("/oauth/tokens",
                             :body => {
                               :client_id => ENV['PERSONA_OAUTH_CLIENT'],
                               :client_secret => ENV['PERSONA_OAUTH_SECRET'],
                               :grant_type => "client_credentials"}
                            )
        token_request = JSON.parse(token_request.body)
        return token_request['access_token']
      end

      def self.acquire_host!(opts={})
        if opts[:host].present?
          base_uri(opts[:host])
        else
          base_uri(PERSONA_HOST)
        end
      end

    end
  end
end

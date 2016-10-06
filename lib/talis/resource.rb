require 'httparty'
require 'ostruct'
require 'securerandom'

module Talis
  # Extend this class when in order to interact with Talis HTTP APIs.
  # Each sub class should set base_uri to whatever Talis primitive it needs
  # to talk to.
  class Resource
    include HTTParty
    format :json
    headers 'User-Agent' => "talis-ruby-client/#{Talis::VERSION} "\
      "ruby/#{RUBY_VERSION}"

    class << self
      def handle_response(response, expected_status_code = 200)
        if response.code == expected_status_code
          response.parsed_response
        elsif response.code >= 400 && response.code < 500
          build_client_error(response)
        elsif response.code >= 500
          raise Talis::ServerError
        else
          raise Talis::ServerCommunicationError
        end
      end

      def new_req_id
        SecureRandom.hex(13)
      end

      protected

      def token
        options = {
          client_id: Talis::Authentication.client_id,
          client_secret: Talis::Authentication.client_secret
        }
        Talis::Authentication::Token.generate(options)
      end

      private

      def build_client_error(response)
        raise Talis::NotFoundError if response.code == 404
        error_description = safe_error_description(response)
        raise Talis::ClientError, error_description
      end

      def safe_error_description(response)
        if response.respond_to? :parsed_response
          parsed_response = response.parsed_response
        end
        parsed_response['error_description'] if parsed_response.present?
      end
    end
  end
end

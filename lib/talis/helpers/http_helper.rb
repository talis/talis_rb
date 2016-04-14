module Talis
  # Extend classes with this module that interact with Talis HTTP APIs
  module HTTPHelper
    def handle_response(response, expected_status_code = 200)
      if response.code == expected_status_code
        response.parsed_response
      elsif response.code >= 400 && response.code < 500
        error_description = safe_error_description(response.parsed_response)
        raise Talis::Errors::ClientError, error_description
      elsif response.code >= 500
        raise Talis::Errors::ServerError
      else
        raise Talis::Errors::ServerCommunicationError
      end
    end

    private

    def safe_error_description(parsed_response)
      parsed_response['error_description'] if parsed_response.present?
    end
  end
end

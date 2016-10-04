module Talis
  module Analytics
    # Represents an event for analytical purposes.
    class Event < Talis::Resource
      base_uri Talis::ECHO_HOST

      class << self
        # Create a single analytics event.
        # In order to send events, the client must be configured with a
        # valid OAuth client that is allowed to search for users:
        #
        #  Talis::Authentication.client_id = 'client_id'
        #  Talis::Authentication.client_secret = 'client_secret'
        #
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param event [Hash] The event to send. It must contain the
        #  minimum keys:
        #     {
        #       class: 'my.class.name',
        #       source: 'my.source.name'
        #     }
        #  Other valid keys include: timestamp, user and props. Props can
        #  contain any key-value pair of custom data. All other keys will be
        #  ignored.
        # @raise [Talis::Errors::ClientError] if the request was invalid.
        # @raise [Talis::Errors::ServerError] if the search failed on the
        #   server.
        # @raise [Talis::Errors::ServerCommunicationError] for network issues.
        def create(request_id: new_req_id, event:)
          request_id = new_req_id unless request_id
          validate_event event
          payload = whitelist_event event
          begin
            response = post_event(request_id, payload)
            handle_response(response, 204)
          rescue SocketError
            raise Talis::Errors::ServerCommunicationError
          end
        end

        private

        def post_event(request_id, payload)
          post('/1/events',
               headers: {
                 'X-Request-Id' => request_id,
                 'Authorization' => "Bearer #{token}"
               },
               body: [payload].to_json)
        end

        def validate_event(event)
          error_message = 'event must contain class and source'
          required = [:class, :source]
          provided = event.select { |attr| required.include? attr }.keys
          raise ArgumentError, error_message unless required == provided
        end

        def whitelist_event(event)
          valid = [:class, :source, :timestamp, :user, :props]
          event.select { |attribute| valid.include? attribute }
        end
      end
    end
  end
end

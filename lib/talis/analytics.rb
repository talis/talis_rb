require_relative 'analytics/event'

module Talis
  # Use this as a mixin within your classes to be able to send analytics events.
  module Analytics
    # Create a single analytics event.
    # In order to send events, the client must be configured with a
    # valid OAuth client that is allowed to search for users:
    #
    #  Talis::Authentication.client_id = 'client_id'
    #  Talis::Authentication.client_secret = 'client_secret'
    #
    # @param event [Hash] The event to send. It must contain the
    #  minimum keys:
    #     {
    #       class: 'my.class.name',
    #       source: 'my.source.name'
    #     }
    #  Other valid keys include: timestamp, user and props. Props can
    #  contain any key-value pair of custom data. All other keys will be
    #  ignored.
    # @param request_id [String] ('uuid') unique ID for the remote request.
    # @raise [Talis::ClientError] if the request was invalid.
    # @raise [Talis::ServerError] if the search failed on the
    #   server.
    # @raise [Talis::ServerCommunicationError] for network issues.
    def send_analytics_event(event, request_id: nil)
      Event.create(request_id: request_id, event: event)
    end
  end
end

module Talis
  module Feeds
    # Represents a feed, as a way of bringing back a collection of annotations.
    class Feed < Talis::Resource
      base_uri Talis::BABEL_HOST

      class << self
        # Returns a collection of annotations matching the provided target.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param target_uri [String] The URI uniquely identifying the target.
        # @return [Array<Talis::Feeds::Annotation>] An array of annotations
        #  or an empty array if the feed was not found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if there was a problem with the request.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def find(request_id: new_req_id, target_uri:)
          md5_target_uri = Digest::MD5.hexdigest(target_uri)
          response = fetch_feed(request_id, md5_target_uri)
          begin
            build handle_response(response)
          rescue Talis::NotFoundError
            []
          end
        rescue SocketError
          raise Talis::ServerCommunicationError
        end

        private

        def fetch_feed(request_id, md5_target_uri)
          get("/feeds/targets/#{md5_target_uri}/activity/annotations/hydrate",
              headers: {
                'Content-Type' => 'application/json',
                'X-Request-Id' => request_id,
                'Authorization' => "Bearer #{token}"
              })
        end

        def build(response)
          annotations = response['annotations']
          annotations.map do |annotation|
            Annotation.new(annotation, user: hydrate_user(annotation, response))
          end
        end

        def hydrate_user(annotation_data, feed_data)
          profiles = feed_data['userProfiles']
          return unless profiles
          guid = annotation_data['annotatedBy']
          user = profiles[guid]
          return unless user
          Talis::User.build(guid: guid, first_name: user['first_name'],
                            surname: user['surname'], email: user['email'])
        end
      end
    end
  end
end

module Talis
  module Feeds
    # Represents an annotation, for example, a video resource comment.
    class Annotation < Talis::Resource
      base_uri Talis::BABEL_HOST
      attr_reader :id, :body, :target, :annotated_by, :motivated_by,
                  :expires_at, :user

      # Creates a new annotation object. For internal use only,
      # use {Annotation.create}.
      # @param data [Hash] The incoming annotation data to construct
      #  a new annotation object with.
      # @param user [Talis::User](nil) The user that created the annotation.
      #  This will be nil for an annotation that has not been hydrated.
      #  Hydrated data is provided by feeds.
      def initialize(data, user: nil)
        # Symbolise all keys for consistency between what was provided
        # and what is returned.
        data = JSON.parse(JSON[data], symbolize_names: true)
        @id = data[:_id]
        @body = data[:hasBody]
        @target = data[:hasTarget].map { |target| underscore(target) }
        @annotated_by = data[:annotatedBy]
        @motivated_by = data[:motivatedBy]
        @expires_at = data[:expiresAt]
        @user = user
      end

      private

      def underscore(payload)
        payload.map { |key, value| [key.to_s.underscore.to_sym, value] }.to_h
      end

      class << self
        # Create a new annotation that is persisted.
        # @param opts [Hash] The annotation data used to create the annotation:
        #  {
        #    request_id: 'optional unique ID for the remote request'
        #    body: {
        #      format: 'e.g: text/plain',
        #      type: 'e.g: Text',
        #      chars: 'annotation content',
        #      details: {} # optional hash to provide additional details.
        #    },
        #    target: [
        #      {
        #        uri: 'location of target being annotated',
        #        as_referenced_by: 'optional reference location',
        #        fragment: 'optional fragment within location'
        #      }
        #    ]
        #    annotated_by: 'Talis user GUID performing the annotation',
        #    motivated_by: 'optional motivation string',
        #    expires_at: 'optional ISO 8601 date time string'
        #  }
        # @return [Talis::Feeds::Annotation] The persisted annotation.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if there was a problem with the request.
        # @raise [Talis::ServerCommunicationError] for network issues.
        # @raise [ArgumentError] for validation errors against opts.
        def create(opts)
          validate_annotation opts
          new handle_response(post_annotation(opts))
        rescue SocketError
          raise Talis::ServerCommunicationError
        end

        private

        def validate_annotation(annotation)
          min_required = 'annotation must contain body, target and annotated_by'
          required = [:body, :target, :annotated_by]
          provided = annotation.select { |attr| required.include? attr }.keys
          raise ArgumentError, min_required unless required == provided
          validate_targets(annotation)
          validate_expiry(annotation)
        end

        def validate_targets(annotation)
          targets = annotation[:target]
          raise ArgumentError,
                'annotation target must be an array' unless targets.is_a? Array
          targets.each do |target|
            raise ArgumentError,
                  'annotation targets must contain uri' unless target[:uri]
            raise ArgumentError,
                  'target uri must be a string' unless target[:uri].is_a? String
          end
        end

        def validate_expiry(annotation)
          expiry = annotation[:expires_at]
          Time.iso8601(expiry) if expiry
        rescue StandardError
          raise ArgumentError, 'expired_at must be a valid ISO 8601 date'
        end

        def post_annotation(opts)
          request_id = opts[:request_id] || new_req_id
          post('/annotations',
               headers: {
                 'Content-Type' => 'application/json',
                 'X-Request-Id' => request_id,
                 'Authorization' => "Bearer #{token}"
               },
               body: body(opts).to_json)
        end

        def body(opts)
          min_body = {
            hasBody: opts[:body],
            hasTarget: opts[:target].map { |target| camelize(target) },
            annotatedBy: opts[:annotated_by]
          }
          min_body[:expiresAt] = opts[:expires_at] if opts[:expires_at]
          min_body[:motivatedBy] = opts[:motivated_by] if opts[:motivated_by]
          min_body
        end

        def camelize(payload)
          payload.map do |key, value|
            [key.to_s.camelize(:lower).to_sym, value]
          end.to_h
        end
      end
    end
  end
end

module Talis
  module Hierarchy
    # Common functionality to Hierarchy resources (Node, Asset)
    module Resource
      # The methods defined within this module are available to instances of,
      # and the class itself that extends Talis::Hierarchy::Resource.
      module Helpers
        # @return [String] The hierarchy namespace.
        attr_accessor :namespace
        # @return [String] The ID of the resource.
        attr_reader :id
        # @return [String] The type of resource.
        attr_reader :type
        # @return [Hash] key-value pair attributes belonging to the resource.
        attr_accessor :attributes

        @new_resource = false
        @deleted = false

        # Manages the current & stored resource type so resources can be edited/
        # deleted properly
        # @param resource_type [String] the new type of the hierarchy resource
        def type=(resource_type)
          @original_type = type if persisted?
          @type = resource_type
        end

        # Manages the current & stored resource id so resources can be edited/
        # deleted properly
        # @param resource_id [String] the new id of the hierarchy resource
        def id=(resource_id)
          @original_id = id if persisted?
          @id = resource_id
        end

        # The resource type the API thinks the resource has
        # (if it has been saved)
        # @return [String]
        def stored_type
          persisted? ? @original_type || type : type
        end

        # The resource id the API thinks the resource has (if it has been saved)
        # @return [String]
        def stored_id
          persisted? ? @original_id || id : id
        end

        # A boolean indicating if the resource exists in the remote Blueprint
        # instance
        # @return [Boolean]
        def persisted?
          !(@new_resource || @deleted)
        end

        protected

        # Query for assets using HTTParty and not blueprint_rb in order to get
        # around the Swagger limitation of not being able to choose between
        # AND and IN queries.
        # @param request_id [String] unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        # @return [Array<Talis::Hierarchy::Asset>] or an empty array if no
        #   assets are found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the search failed on the server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def search_assets(request_id, namespace, opts)
          response = get("/1/#{namespace}/assets",
                         query: build_query(opts),
                         headers: {
                           'X-Request-Id' => request_id,
                           'Authorization' => "Bearer #{token}"
                         })
          convert_to_blueprint_api_client_model(handle_response(response))
        rescue SocketError
          raise Talis::ServerCommunicationError
        end

        def mark_persisted
          @new_resource = false
          @deleted = false
          @original_id = id
          @original_type = type
        end

        def mark_deleted
          @deleted = true
          @original_id = id
          @original_type = type
        end

        private

        def build_query(opts)
          query = []
          opts.each do |key, value|
            if key.to_s.start_with?('filter')
              filter = key.to_s.gsub('filter_', '')
              build_collection_query(query, filter, value)
            else
              query << [key, value]
            end
          end
          URI.encode_www_form(query)
        end

        def build_collection_query(params, key, value)
          filter_key = "filter[#{key.camelize(:lower)}]"
          if value.is_a? Array
            value.each do |item|
              params << [filter_key, item]
            end
          elsif value.is_a? Hash
            build_collection_query_from_hash(params, filter_key, value)
          else
            raise ArgumentError, 'filter value must be an array or hash'
          end
        end

        def build_collection_query_from_hash(params, key, hash)
          mode = hash.keys.first
          values = hash.values.first
          if mode == :all
            values.each do |item|
              params << [key, item]
            end
          else
            params << [key, values.join(',')]
          end
        end

        def convert_to_blueprint_api_client_model(response)
          response['data'].map! do |item|
            OpenStruct.new(type: item['type'], id: item['id'],
                           attributes: item.fetch('attributes', {}))
          end
        end

        def configure_blueprint
          BlueprintClient.configure do |config|
            config.scheme = base_uri[/https?/]
            config.host = base_uri
            config.access_token = token
          end
        end
      end

      # Callback invoked whenever the receiver is included in another module or
      # class. Receiver here is whoever includes Resource
      def self.included(base)
        base.extend(Helpers)
      end

      include Helpers
    end
  end
end

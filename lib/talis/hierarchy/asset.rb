require 'blueprint_ruby_client'

module Talis
  module Hierarchy
    # Represents hierarchy asset API operations provided by the Blueprint gem:
    # {https://github.com/talis/blueprint_rb}
    #
    # In order to perform remote operations, the client must be configured
    # with a valid OAuth client that is allowed to query assets:
    #
    #  Talis::Authentication.client_id = 'client_id'
    #  Talis::Authentication.client_secret = 'client_secret'
    #
    # @example Create an asset with attributes.
    #  node_options = {
    #    namespace: 'mynamespace',
    #    type: 'module',
    #    id: '1'
    #  }
    #  node = Talis::Hierarchy::Node.get(node_options)
    #  asset_options = {
    #    namespace: 'mynamespace',
    #    type: 'list',
    #    id: '1',
    #    nodes: [ node ]
    #  }
    #  asset = Talis::Hierarchy::Asset.new(asset_options)
    #  asset.save # Will raise an exception if this fails
    #  asset.attributes = { attr_key: 'my_attr_value' }
    #  asset.update
    # @example Create an asset and associate it with multiple nodes.
    #  node1_options = {
    #    namespace: 'mynamespace',
    #    type: 'module',
    #    id: '1'
    #  }
    #  node2_options = {
    #    namespace: 'mynamespace',
    #    type: 'module',
    #    id: '2'
    #  }
    #  node1 = Talis::Hierarchy::Node.get(node1_options)
    #  node2 = Talis::Hierarchy::Node.get(node2_options)
    #  asset_options = {
    #    namespace: 'mynamespace',
    #    type: 'list',
    #    id: '1',
    #    nodes: [ node1, node2 ]
    #  }
    #  asset = Talis::Hierarchy::Asset.new(asset_options)
    #  asset.save
    class Asset < Talis::Resource
      extend Talis::OAuthService
      include Talis::Hierarchy::Resource

      base_uri Talis::BLUEPRINT_HOST

      # @return [Array<BlueprintClient::Node>] An array of nodes an
      #   asset can belong to.
      attr_accessor :nodes

      # Create a non-persisted asset.
      # @param namespace [String] the namespace of the hierarchy.
      # @param type [String] the type of asset.
      # @param id [String] the ID of the asset.
      # @param nodes [Array<BlueprintClient::Node>] an array of nodes
      #   an asset can belong to.
      # @param attributes [Hash]({}) key-value pair attributes belonging to the
      #   asset.
      def initialize(namespace:, type:, id:, nodes: [], attributes: {})
        @namespace = namespace
        @id = id
        @type = type
        @nodes = nodes
        @attributes = attributes
        @new_resource = true
      end

      # Persist the asset to the hierarchy.
      # @param request_id [String] ('uuid') unique ID for the remote request.
      # @return [Array<BlueprintClient::Asset>] the created asset.
      # @raise [Talis::ClientError] if the request was invalid.
      # @raise [Talis::ServerError] if the save failed on the
      #   server.
      # @raise [Talis::ServerCommunicationError] for network issues.
      def save(request_id: self.class.new_req_id)
        add_to_nodes request_id
        mark_persisted if @nodes.count > 1
      rescue BlueprintClient::ApiError => error
        self.class.handle_response(error)
      end

      # Update an existing asset.
      # @param request_id [String] ('uuid') unique ID for the remote request.
      # @raise [Talis::ClientError] if the request was invalid.
      # @raise [Talis::ServerError] if the update failed on the server.
      # @raise [Talis::ServerCommunicationError] for network issues.
      def update(request_id: self.class.new_req_id)
        body = BlueprintClient::AssetBody.new(data: {
                                                id: @id,
                                                type: @type,
                                                attributes: @attributes
                                              })
        self.class.api_client(request_id).replace_asset(@namespace, stored_id,
                                                        stored_type, body: body)
        mark_persisted
      rescue BlueprintClient::ApiError => error
        self.class.handle_response(error)
      end

      # Delete an existing asset.
      # @param request_id [String] ('uuid') unique ID for the remote request.
      # @raise [Talis::ClientError] if the request was invalid.
      # @raise [Talis::ServerError] if the delete failed on the server.
      # @raise [Talis::ServerCommunicationError] for network issues.
      def delete(request_id: self.class.new_req_id)
        self.class.api_client(request_id).delete_asset(@namespace, stored_id,
                                                       stored_type)
        mark_deleted
      rescue BlueprintClient::ApiError => error
        self.class.handle_response(error)
      end

      private

      # Internal part of save method. Adds asset to nodes
      # @param request_id [String] ('uuid') unique ID for the remote request.
      def add_to_nodes(request_id)
        @nodes.each { |node| add_to_node(request_id, node) }
      end

      # Internal part of save method. Adds asset to node
      # @param request_id [String] ('uuid') unique ID for the remote request.
      # @param node [BlueprintClient::Node] The node the asset should be
      #   added to.
      def add_to_node(request_id, node)
        self.class.api_client(request_id).add_asset_to_node(@namespace,
                                                            node.type,
                                                            node.id,
                                                            @type,
                                                            @id)
      rescue BlueprintClient::ApiError => error
        raise error unless error.code == 409
        # Already associated with node - do not error
      end

      # rubocop:disable Metrics/LineLength
      class << self
        # Search for assets in the hierarchy for the given namespace and node.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of node the assets belong to.
        # @param id [String] the ID of the node the assets belong to.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/AssetsApi.md#get_assets_in_node}
        # @return [Array<Talis::Hierarchy::Asset>] or an empty array if no
        #   assets are found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the search failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def find_by_node(request_id: new_req_id, namespace:, type:, id:, opts: {})
          data = api_client(request_id).get_assets_in_node(namespace, type,
                                                           id, opts).data
          data.map! { |asset| build(asset, namespace) }
        rescue BlueprintClient::ApiError => error
          handle_blueprint_api_error(error)
        end

        # Search for assets in the hierarchy for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/AssetsApi.md#search_assets}
        #   One exception to the options listed above are filters which take
        #   the following format, for example:
        #   Return assets that are related to any nodes specified in the array.
        #
        #     filter_node: ['type/id', 'type/id']
        #
        #   As above but explicitly requesting an any match:
        #
        #     filter_node: { any: ['type/id', 'type/id'] }
        #
        #   Return assets that are related to all nodes specified in the array.
        #
        #     filter_node: { all: ['type/id', 'type/id'] }
        # @return [Array<Talis::Hierarchy::Asset>] or an empty array if no
        #   assets are found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the search failed on the server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def where(request_id: new_req_id, namespace:, opts: {})
          # search_assets method in resource module uses HTTParty not
          # blueprint_rb to call the API to get around the Swagger limitation
          # of not being able to choose between AND and IN queries.
          data = search_assets(request_id, namespace, opts)
          data.map! { |asset| build(asset, namespace) }
        rescue Talis::NotFoundError
          []
        end

        # Return all assets in the hierarchy for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @return [Array<Talis::Hierarchy::Asset>] or an empty array if no
        #   assets are found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the search failed on the server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def all(request_id: new_req_id, namespace:)
          where(request_id: request_id, namespace: namespace)
        end

        # Fetch a single asset from the hierarchy for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of asset to fetch.
        # @param id [String] the ID of the asset to fetch.
        # @return Talis::Hierarchy::Asset or nil if the asset cannot be found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def find(request_id: new_req_id, namespace:, type:, id:)
          data = api_client(request_id).get_asset(namespace, type, id).data
          build(data, namespace)
        rescue BlueprintClient::ApiError => error
          handle_blueprint_api_error(error, false)
        end

        # Exposes the underlying Blueprint assets API client.
        # @param request_id [String] ('uuid') unique ID for remote requests.
        # @return BlueprintClient::AssetsApi
        def api_client(request_id = new_req_id)
          configure_blueprint

          api_client = BlueprintClient::ApiClient.new
          api_client.default_headers = {
            'X-Request-Id' => request_id,
            'User-Agent' => "talis-ruby-client/#{Talis::VERSION} "\
            "ruby/#{RUBY_VERSION}"
          }

          BlueprintClient::AssetsApi.new(api_client)
        end

        private

        def build(data, namespace)
          asset = new(namespace: namespace, type: data.type, id: data.id,
                      attributes: data.attributes ? data.attributes : {})
          asset.instance_variable_set(:@new_resource, false)
          asset
        end

        def handle_blueprint_api_error(error, return_empty_array = true)
          handle_response(error)
        rescue Talis::NotFoundError
          return_empty_array ? [] : nil
        end
      end
    end
  end
end

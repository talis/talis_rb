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
    #    node: node
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
    #    node: node
    #  }
    #  asset = Talis::Hierarchy::Asset.new(asset_options)
    #  asset.save
    #  # Associates the asset with an additional node
    #  asset.node = node2
    #  asset.save
    class Asset < Talis::Resource
      extend Talis::OAuthService

      base_uri Talis::BLUEPRINT_HOST

      # @return [String] The hierarchy namespace.
      attr_accessor :namespace
      # @return [String] The ID of the asset.
      attr_accessor :id
      # @return [String] The type of asset.
      attr_accessor :type
      # @return [BlueprintClient::Node] A node an asset can belong to.
      #   Note that an asset can belong to multiple nodes (see examples).
      attr_accessor :node
      # @return [Hash] key-value pair attributes belonging to the asset.
      attr_accessor :attributes

      # Create a non-persisted asset.
      # @param namespace [String] the namespace of the hierarchy.
      # @param type [String] the type of asset.
      # @param id [String] the ID of the asset.
      # @param node [BlueprintClient::Node] a node an asset can belong to.
      #   Note that an asset can belong to multiple nodes (see examples).
      # @param attributes [Hash]({}) key-value pair attributes belonging to the
      #   asset.
      def initialize(namespace:, type:, id:, node: nil, attributes: {})
        @namespace = namespace
        @id = id
        @type = type
        @node = node
        @attributes = attributes
      end

      # Persist the asset to the hierarchy.
      # @param request_id [String] ('uuid') unique ID for the remote request.
      # @return [Array<BlueprintClient::Asset>] the created asset.
      # @raise [Talis::Errors::ClientError] if the request was invalid.
      # @raise [Talis::Errors::ServerError] if the save failed on the
      #   server.
      # @raise [Talis::Errors::ServerCommunicationError] for network issues.
      def save(request_id: self.class.new_req_id)
        self.class.api_client(request_id).add_asset_to_node(@namespace,
                                                            @node.type,
                                                            @node.id,
                                                            @type,
                                                            @id)
      rescue BlueprintClient::ApiError => error
        self.class.handle_response(error)
      end

      # Update an existing asset.
      # @param request_id [String] ('uuid') unique ID for the remote request.
      # @raise [Talis::Errors::ClientError] if the request was invalid.
      # @raise [Talis::Errors::ServerError] if the update failed on the
      #   server.
      # @raise [Talis::Errors::ServerCommunicationError] for network issues.
      def update(request_id: self.class.new_req_id)
        body = BlueprintClient::AssetBody.new(data: {
                                                id: @id,
                                                type: @type,
                                                attributes: @attributes
                                              })
        self.class.api_client(request_id).replace_asset(@namespace, @id, @type,
                                                        body: body)
      rescue BlueprintClient::ApiError => error
        self.class.handle_response(error)
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
        # @raise [Talis::Errors::ClientError] if the request was invalid.
        # @raise [Talis::Errors::ServerError] if the search failed on the
        #   server.
        # @raise [Talis::Errors::ServerCommunicationError] for network issues.
        def find_by_node(request_id: new_req_id, namespace:, type:, id:, opts:{})
          data = api_client(request_id).get_assets_in_node(namespace, type,
                                                           id, opts).data
          data.map { |asset| build(asset, namespace) }
        rescue BlueprintClient::ApiError => error
          begin
            handle_response(error)
          rescue Talis::Errors::NotFoundError
            []
          end
        end

        # Fetch a single asset from the hierarchy for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of asset to fetch.
        # @param id [String] the ID of the asset to fetch.
        # @return Talis::Hierarchy::Asset or nil if the asset cannot be found.
        # @raise [Talis::Errors::ClientError] if the request was invalid.
        # @raise [Talis::Errors::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::Errors::ServerCommunicationError] for network issues.
        def get(request_id: new_req_id, namespace:, type:, id:)
          data = api_client(request_id).get_asset(namespace, type, id).data
          build(data, namespace)
        rescue BlueprintClient::ApiError => error
          begin
            handle_response(error)
          rescue Talis::Errors::NotFoundError
            nil
          end
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
          new(namespace: namespace, type: data.type, id: data.id,
              attributes: data.attributes ? data.attributes : {})
        end

        def configure_blueprint
          BlueprintClient.configure do |config|
            config.scheme = base_uri[/https?/]
            config.host = base_uri
            config.access_token = token
          end
        end
      end
    end
  end
end

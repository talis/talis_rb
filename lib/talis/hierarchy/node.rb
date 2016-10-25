require 'blueprint_ruby_client'

module Talis
  module Hierarchy
    # Represents hierarchy node API operations provided by the Blueprint gem:
    # {https://github.com/talis/blueprint_rb}
    #
    # In order to perform remote operations, the client must be configured
    # with a valid OAuth client that is allowed to query nodes:
    #
    #  Talis::Authentication.client_id = 'client_id'
    #  Talis::Authentication.client_secret = 'client_secret'
    #
    class Node < Talis::Resource
      extend Talis::OAuthService

      base_uri Talis::BLUEPRINT_HOST

      # rubocop:disable Metrics/LineLength
      class << self
        # Search for nodes in the hierarchy for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/HierarchyApi.md#search_nodes}
        # @return [Hash] containing data and meta attributes. The structure
        #   as follows:
        #     {
        #       data: [node1, node2, node3, node4, node5],
        #       meta: { offset: 0, count: 20, limit: 5 }
        #     }
        #  where nodes are of type BlueprintClient::Node
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the search failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def find(request_id: new_req_id, namespace:, opts: {})
          api_client(request_id).search_nodes(namespace, opts)
        rescue BlueprintClient::ApiError => error
          handle_response(error)
        end

        # Fetch a single node from the hierarchy for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of node to fetch.
        # @param id [String] the ID of the node to fetch.
        # @return BlueprintClient::Node or nil if the node cannot be found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def get(request_id: new_req_id, namespace:, type:, id:)
          api_client(request_id).get_node(namespace, id, type).data
        rescue BlueprintClient::ApiError => error
          begin
            handle_response(error)
          rescue Talis::NotFoundError
            nil
          end
        end

        # Fetch all parents belonging to the specified node from the hierarchy
        # for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of node whose parents are to be fetched.
        # @param id [String] the ID of the node whose parents are to be fetched.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/HierarchyApi.md#get_parents}
        # @return BlueprintClient::Node or nil if the node cannot be found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def parents(request_id: new_req_id, namespace:, type:, id:, opts: {})
          api_client(request_id).get_parents(id, namespace, type, opts).data
        rescue BlueprintClient::ApiError => error
          handle_response(error)
        end

        # Fetch all children belonging to the specified node from the hierarchy
        # for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of node whose children are to be
        #   fetched.
        # @param id [String] the ID of the node whose children are to be
        #   fetched.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/HierarchyApi.md#get_children}
        # @return BlueprintClient::Node or nil if the node cannot be found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def children(request_id: new_req_id, namespace:, type:, id:, opts: {})
          api_client(request_id).get_children(id, namespace, type, opts).data
        rescue BlueprintClient::ApiError => error
          handle_response(error)
        end

        # Fetch all ancestors belonging to the specified node from the hierarchy
        # for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of node whose ancestors are to be
        #   fetched.
        # @param id [String] the ID of the node whose ancestors are to be
        #   fetched.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/HierarchyApi.md#get_ancestors}
        # @return BlueprintClient::Node or nil if the node cannot be found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def ancestors(request_id: new_req_id, namespace:, type:, id:, opts: {})
          api_client(request_id).get_ancestors(id, namespace, type, opts).data
        rescue BlueprintClient::ApiError => error
          handle_response(error)
        end

        # Fetch all descendants belonging to the specified node from the hierarchy
        # for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of node whose descendants are to be
        #   fetched.
        # @param id [String] the ID of the node whose descendants are to be
        #   fetched.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/HierarchyApi.md#get_descendants}
        # @return BlueprintClient::Node or nil if the node cannot be found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def descendants(request_id: new_req_id, namespace:, type:, id:, opts: {})
          api_client(request_id).get_descendants(id, namespace, type, opts).data
        rescue BlueprintClient::ApiError => error
          handle_response(error)
        end

        # Create a new node
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of hierarchy.
        # @param type [String]
        # @param id [String]
        # @param attributes [Hash]
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/HierarchyApi.md#add_node}
        # @return [NodeBody]
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/NodeBody.md}
        def add(request_id: new_req_id, namespace:, type:, id:, attributes: {})
          new_node = {
            data: {
              id: id,
              type: type,
              attributes: attributes
            }
          }

          api_client(request_id).add_node(namespace, new_node, {}).data
        rescue BlueprintClient::ApiError => error
          handle_response(error)
        end

        # Exposes the underlying Blueprint nodes API client.
        # @param request_id [String] ('uuid') unique ID for remote requests.
        # @return BlueprintClient::HierarchyApi
        def api_client(request_id = new_req_id)
          configure_blueprint

          api_client = BlueprintClient::ApiClient.new
          api_client.default_headers = {
            'X-Request-Id' => request_id,
            'User-Agent' => "talis-ruby-client/#{Talis::VERSION} "\
            "ruby/#{RUBY_VERSION}"
          }

          BlueprintClient::HierarchyApi.new(api_client)
        end

        private

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

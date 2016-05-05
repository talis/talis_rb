require 'blueprint_ruby_client'

module Talis
  module Hierarchy
    # Represents hierarchy asset API operations provided by the Blueprint gem:
    # {https://github.com/talis/blueprint_rb}
    #
    # In order to perform remote operations, the class must be configured with a
    # valid OAuth client that is allowed to query assets:
    #
    #  Talis::Hierarchy::Asset.client_id = 'client_id'
    #  Talis::Hierarchy::Asset.client_secret = 'client_secret'
    #
    class Asset < Talis::Resource
      base_uri Talis::BLUEPRINT_HOST

      # The ID of the OAuth client to allow requests for asset resources.
      cattr_accessor :client_id
      # The secret of the OAuth client to allow requests for asset resources.
      cattr_accessor :client_secret

      # rubocop:disable Metrics/LineLength
      class << self
        # Search for assets in the hierarchy for the given namespace.
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param namespace [String] the namespace of the hierarchy.
        # @param type [String] the type of node the assets belong to.
        # @param id [String] the ID of the node the assets belong to.
        # @param opts [Hash] ({}) optional filter and pagination criteria.
        #   see {https://github.com/talis/blueprint_rb/blob/master/docs/AssetsApi.md#get_assets_in_node}
        # @return [Array<BlueprintClient::Asset>] or an empty array if no
        #   assets are found.
        # @raise [Talis::Errors::ClientError] if the request was invalid.
        # @raise [Talis::Errors::ServerError] if the search failed on the
        #   server.
        # @raise [Talis::Errors::ServerCommunicationError] for network issues.
        def find(request_id: new_req_id, namespace:, type:, id:, opts:{})
          api_client(request_id).get_assets_in_node(namespace, type, id, opts)
                                .data
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
        # @return BlueprintClient::Asset or nil if the asset cannot be found.
        # @raise [Talis::Errors::ClientError] if the request was invalid.
        # @raise [Talis::Errors::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::Errors::ServerCommunicationError] for network issues.
        def get(request_id: new_req_id, namespace:, type:, id:)
          api_client(request_id).get_asset(namespace, type, id).data
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

        def configure_blueprint
          BlueprintClient.configure do |config|
            config.scheme = base_uri[/https?/]
            config.host = base_uri
            config.access_token = token
          end
        end

        def token
          options = {
            client_id: Asset.client_id,
            client_secret: Asset.client_secret
          }
          Talis::Authentication::Token.generate(options)
        end
      end
    end
  end
end

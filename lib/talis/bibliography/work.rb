require 'metatron_ruby_client'
require 'forwardable'

module Talis
  module Bibliography
    # Represents bibliographic works API operations provided by the Metatron gem
    # {https://github.com/talis/metatron_rb}
    #
    # In order to perform remote operations, the client must be configured
    # with a valid OAuth client that is allowed to query nodes:
    #
    #  Talis::Authentication.client_id = 'client_id'
    #  Talis::Authentication.client_secret = 'client_secret'
    #
    class Work < Talis::Resource
      extend Forwardable, Talis::OAuthService, Talis::Bibliography
      base_uri Talis::METATRON_HOST
      attr_reader :manifestations, :assets, :work_data
      attr_accessor :id, :type, :title
      def_delegators :@work_data, :id, :type

      # rubocop:disable Metrics/LineLength
      class << self
        # Search for bibliographic works
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param query [String] the query to filter works on
        # @param offset [Integer] the page offset
        # @param limit [Integer] the number of works per page
        # @param include [Array] the related resources to associate with each work
        #   see {https://github.com/talis/metatron_rb/blob/master/docs/DefaultApi.md#2_works_get}
        # @return [MetatronClient::WorkResultSet] containing data and meta attributes.
        #   The structure is as follows:
        #     {
        #       data: [work1, work2, work3, work4, work5],
        #       meta: { offset: 0, count: 20, limit: 5 }
        #       included: [manifestation|assset1, manifestation|assset2]
        #     }
        #  where works are of type Talis::Bibliography::Work, which are also available
        # directly via the Enumerable methods: each, find, find_all, first, last
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the search failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def find(request_id: new_req_id, query:, offset: 0, limit: 20, include: [])
          api_client(request_id).work(token, query, limit, offset,
                                      include: include)
                                .extend(ResultSet).hydrate
        rescue MetatronClient::ApiError => error
          begin
            handle_response(error)
          rescue Talis::NotFoundError
            empty_result_set(MetatronClient::WorkResultSet,
                             offset: offset, limit: limit, count: 0)
          end
        end

        # Fetch a single work by id
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param id [String] the ID of the work to fetch.
        # @return Talis::Bibliography::Work or nil if the work cannot be found.
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the fetch failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def get(request_id: new_req_id, id:)
          new api_client(request_id).works_work_id_assets_get(id, token).data
        rescue MetatronClient::ApiError => error
          begin
            handle_response(error)
          rescue Talis::NotFoundError
            nil
          end
        end
      end

      def initialize(work_data = nil)
        if work_data.is_a? MetatronClient::WorkData
          parse_work_data work_data
        else
          @work_data = MetatronClient::WorkData.new
        end
      end

      # TODO: call manifestation route if not set
      def manifestations
        @manifestations ||= []
      end

      # TODO: call assets route if not set
      def assets
        @assets ||= []
      end

      # By default, the metatron client returns generic ResourceLink objects
      # as the related resources.  When passed an array of Metatron::ResourceData
      # objects, it will replace the ResourceLink objects with more appropriately
      # typed objects
      # @param resources [Array] an array of Metatron::ResourceData objects
      def hydrate_relationships(resources)
        manifestations.map! do |m|
          resource = find_relationship_in_included m.manifestation_data.to_hash,
                                                   resources
          return m unless resource
          hydrate_manifestation_assets resource, resources
          Manifestation.new(MetatronClient::ManifestationData.new(
                              resource.to_hash
          ))
        end
        nil
      end

      private

      def hydrate_manifestation_assets(manifestation, resources)
        if manifestation_has_assets? manifestation
          manifestation.relationships[:assets][:data].each do |asset_data|
            asset = find_relationship_in_included asset_data.to_hash, resources
            assets << MetatronClient::AssetData.new(asset.to_hash) if asset
          end
        end
        nil
      end

      def manifestation_has_assets?(manifestation)
        manifestation.try(:relationships) &&
          manifestation.relationships[:assets] &&
          manifestation.relationships[:assets][:data]
      end

      def find_relationship_in_included(resource_data, included)
        included.find do |resource|
          resource.id == resource_data[:id] && resource.type == resource_data[:type]
        end
      end

      def parse_work_data(work_data)
        @work_data = work_data
        @title = work_data.try(:attributes).try(:titles)

        if work_data.try(:relationships).try(:manifestations).try(:data)
          work_data.relationships.manifestations.data.each do |manifestation|
            manifestations << Manifestation.new(
              MetatronClient::ManifestationData.new(manifestation.to_hash)
            )
          end
        end
      end
    end
  end
end

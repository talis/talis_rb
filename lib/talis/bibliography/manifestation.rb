require 'metatron_ruby_client'
require 'forwardable'

module Talis
  module Bibliography
    # Represents bibliographic manifestations API operations provided by the
    # Metatron gem
    # {https://github.com/talis/metatron_rb}
    #
    # In order to perform remote operations, the client must be configured
    # with a valid OAuth client that is allowed to query nodes:
    #
    #  Talis::Authentication.client_id = 'client_id'
    #  Talis::Authentication.client_secret = 'client_secret'
    #
    class Manifestation < Talis::Resource
      extend Forwardable, Talis::OAuthService, Talis::Bibliography
      base_uri Talis::METATRON_HOST
      attr_reader :contributors, :assets, :manifestation_data, :work
      attr_accessor :id, :type, :title
      def_delegators :@manifestation_data, :id, :type

      # rubocop:disable Metrics/LineLength
      class << self
        # Search for bibliographic manifestations
        # @param request_id [String] ('uuid') unique ID for the remote request.
        # @param opts [Hash] the query parameters: currently supported: work_id and isbn
        #   see {https://github.com/talis/metatron_rb/blob/metatron-swagger-updates/docs/DefaultApi.md#manifestation}
        # @return [MetatronClient::ManifestationResultSet] containing data and meta attributes.
        #   The structure is as follows:
        #     {
        #       data: [manifestation1, manifestation2, manifestation3],
        #       meta: { count: 3 }
        #       included: [contributor1]
        #     }
        #  where manifestations are of type Talis::Bibliography::Manifestation, which are also available
        # directly via the Enumerable methods: each, find, find_all, first, last
        # @raise [Talis::ClientError] if the request was invalid.
        # @raise [Talis::ServerError] if the search failed on the
        #   server.
        # @raise [Talis::ServerCommunicationError] for network issues.
        def find(request_id: new_req_id, opts: {})
          api_client(request_id).manifestation(token, opts)
                                .extend(ResultSet).hydrate
        rescue MetatronClient::ApiError => error
          begin
            handle_response(error)
          rescue Talis::NotFoundError
            empty_result_set(MetatronClient::ManifestationResultSet, count: 0)
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
          new api_client(request_id).get_manifestation(token, id).data
        rescue MetatronClient::ApiError => error
          begin
            handle_response(error)
          rescue Talis::NotFoundError
            nil
          end
        end
      end

      def initialize(manifestation_data = nil)
        if manifestation_data.is_a? MetatronClient::ManifestationData
          parse_manifestation_data manifestation_data
        else
          @manifestation_data = MetatronClient::ManifestationData.new
        end
      end

      def contributors
        @contributors ||= []
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
      def hydrate_relationships(included_resources)
        contributors.map! do |contributor|
          find_relationship_in_included(contributor,
                                        included_resources)
        end
      end

      private

      def find_relationship_in_included(resource_data, included)
        included.find do |resource|
          resource.id == resource_data.id && resource.type == resource_data.type
        end
      end

      def parse_manifestation_data(manifestation_data)
        @manifestation_data = manifestation_data
        @title = manifestation_data.try(:attributes).try(:title)

        unless manifestation_data.relationships.nil?
          add_relationships(manifestation_data)
        end
      end

      def add_relationships(manifestation_data)
        [:contributors, :work].each do |rel|
          next unless manifestation_data.relationships.try(rel).try(:data)
          if rel == :contributors
            add_related_contributors(manifestation_data)
          else
            add_related_work(manifestation_data)
          end
        end
      end

      def add_related_contributors(manifestation_data)
        @contributors ||= []
        @contributors += manifestation_data.relationships.contributors.data
      end

      def add_related_work(manifestation_data)
        @work = MetatronClient::WorkData.new(
          manifestation_data.relationships.work.data.to_hash
        )
      end
    end
  end
end

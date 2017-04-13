require 'metatron_ruby_client'
require 'forwardable'

module Talis
  module Bibliography
    # Represents an eBook which is a type of asset associated with
    # works and their manifestations.
    #
    # In order to perform remote operations, the client must be configured
    # with a valid OAuth client that is allowed to query nodes:
    #
    #  Talis::Authentication.client_id = 'client_id'
    #  Talis::Authentication.client_secret = 'client_secret'
    #
    class EBook < Talis::Resource
      extend Forwardable, Talis::OAuthService, Talis::Bibliography
      base_uri Talis::METATRON_HOST
      attr_accessor :id, :vbid, :title, :author, :format, :digital_list_price,
                    :publisher_list_price, :store_price
      private_class_method :new

      def initialize(asset_data)
        attrs = asset_data.try(:attributes) || {}
        @id = asset_data.id
        @vbid = attrs[:vbid]
        @title = attrs[:title]
        @author = attrs[:author]
        @format = attrs[:'book-format']
        price_list = attrs.fetch(:pricelist, {})
        @digital_list_price = price_list[:'digital-list-price']
        @publisher_list_price = price_list[:'publisher-list-price']
        @store_price = price_list.fetch(:'store-price', {})[:value]
      end

      class << self
        def find_by_manifestation_id(manifestation_id, request_id = new_req_id)
          id = manifestation_id.gsub('nbd:', '')
          begin
            set = api_client(request_id).get_manifestation_assets(token, id)
          rescue MetatronClient::ApiError => error
            return [] if error.code == 404
            handle_response(error)
          end
          set.data.select { |asset| asset.type == Talis::EBOOK_TYPE }
             .map { |asset| new(asset) }
        end
      end
    end
  end
end

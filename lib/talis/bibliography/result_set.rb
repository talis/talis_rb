require 'forwardable'
module Talis
  module Bibliography
    # Provides convenience methods for working with MetatronClient::*ResultSets
    # TODO: eventually this will be replaced with PaginatedJsonApiArray from
    # Atlas
    module ResultSet
      include Enumerable
      extend Forwardable
      def_delegators :@data, :[], :each, :first, :last, :find, :find_all

      # Replaces the MetatronClient objects with more intuitive DSL objects
      # and hydrates the relationships from the included array, if available
      def hydrate
        model_data
        self
      end

      private

      def model_data
        data.each_with_index do |data, i|
          if is_a? MetatronClient::WorkResultSet
            resource = Work.new data
          elsif is_a? MetatronClient::ManifestationResultSet
            resource = Manifestation.new data
          end
          resource.hydrate_relationships(included) if included
          self.data[i] = resource
        end
      end
    end
  end
end

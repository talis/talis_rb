module Talis
  module Hierarchy
    # Common functionality to Hierarchy resources (Node, Asset)
    module Resource
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

      def type=(resource_type)
        @original_type = type if persisted?
        @type = resource_type
      end

      def id=(resource_id)
        @original_id = id if persisted?
        @id = resource_id
      end

      def stored_type
        persisted? ? @original_type || type : type
      end

      def stored_id
        persisted? ? @original_id || id : id
      end

      def persisted?
        !(@new_resource || @deleted)
      end
    end
  end
end

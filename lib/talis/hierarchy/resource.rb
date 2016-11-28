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
      attr_reader :attributes

      @new_resource = false
      @deleted = false
      @modified = false

      # Manages the current & stored resource type so resources can be edited/
      # deleted properly
      # @param resource_type [String] the new type of the hierarchy resource
      def type=(resource_type)
        @original_type = type if persisted?
        @type = resource_type
        @modified = true
      end

      # Manages the current & stored resource id so resources can be edited/
      # deleted properly
      # @param resource_id [String] the new id of the hierarchy resource
      def id=(resource_id)
        @original_id = id if persisted?
        @id = resource_id
        @modified = true
      end

      # The resource type the API thinks the resource has (if it has been saved)
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

      # A boolean indicating if the resource has been modified
      # @return [Boolean]
      def modified?
        @modified
      end

      def attributes=(attributes)
        @attributes = attributes
        @modified = true
      end

      protected

      def mark_persisted
        @new_resource = false
        @deleted = false
        @modified = false
        @original_id = id
        @original_type = type
      end

      def mark_deleted
        @deleted = true
        @original_id = id
        @original_type = type
      end
    end
  end
end

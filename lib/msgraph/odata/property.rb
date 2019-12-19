require 'date'

class Msgraph
  module Odata
    class Property
      attr_reader :name
      attr_reader :nullable
      attr_reader :type

      def initialize(**args)
        @name     = args[:name]
        @nullable = args[:nullable]
        @type     = args[:type]
      end

      def collection?
        OData::CollectionType === type
      end

      def coerce_to_type(value)
        return nil if value.nil?
        type.coerce(value)
      end

      def collection_type_match?(value)
        collection = type
        collection.valid_value?(value)
      end

      def type_match?(value)
        type.valid_value?(value) || (value.nil? && nullable)
      end

      def nullable_match?(value)
        nullable || !value.nil?
      end

    end
  end
end

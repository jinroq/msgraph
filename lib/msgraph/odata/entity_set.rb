class Msgraph
  module Odata
    class EntitySet
      attr_reader :name
      attr_reader :member_type

      def initialize(options = {})
        @name        = options[:name]
        @member_type = options[:member_type]
        @dispatcher  = options[:dispatcher]
      end

      def collection?
        true
      end

      def type
        @dispatcher.get_type_by_name("Collection(#{member_type})")
      end
    end
  end
end

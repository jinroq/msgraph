class Msgraph
  module Odata
    module Types
      # Data definition of elements that can be Collection.
      class CollectionType < BaseType
        attr_reader :member_type

        def initialize(options = {})
          super
          @member_type = options[:member_type]
        end

        def valid_value?(value)
          member_type.valid_value?(value)
        end

        def primitive_type?
          Odata::Types::PrimitiveType === member_type
        end

        def enum_type?
          Odata::Types::EnumType === member_type
        end

        def collection?
          true
        end

        def properties
          member_type.properties
        end
      end
    end
  end
end

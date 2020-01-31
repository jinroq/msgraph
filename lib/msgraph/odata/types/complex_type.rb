class Msgraph
  module Odata
    module Types
      class ComplexType < BaseType
        attr_reader :base_type

        def initialize(args = {})
          super
          @base_type  = args[:base_type]
          @dispatcher = args[:dispatcher]
        end

        def properties
          @properties ||= @dispatcher.properties_for_type(name)
        end

        def valid_value?(value)
          value.respond_to?(:odata_type) && self.name == value.odata_type
        end

      end
    end
  end
end

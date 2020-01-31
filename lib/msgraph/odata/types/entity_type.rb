class Msgraph
  module Odata
    module Types
      class EntityType < BaseType
        attr_reader :base_type
        attr_reader :abstract

        def initialize(args = {})
          super
          @abstract   = args[:abstract]
          @base_type  = args[:base_type]
          @open_type  = args[:open_type]
          @has_stream = args[:has_stream]
          @dispatcher = args[:dispatcher]
        end

        # 
        def properties
          @properties ||= @dispatcher.properties_for_type(name)
        end

        # 
        def navigation_properties
          @navigation_properties ||= @dispatcher.navigation_properties_for_type(name)
        end

        def navigation_property_by_name(name)
          navigation_properties.find do |navigation_property|
            navigation_property.name == name
          end
        end

        def valid_value?(value)
          value.respond_to?(:odata_type) && (name == value.odata_type || name == value.class.superclass.odata_type.name)
        end
      end
    end
  end
end

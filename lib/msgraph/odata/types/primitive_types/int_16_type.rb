class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class Int16Type < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            Integer === value &&
              value <= 2**15 &&
              value > -(2**15)
          end

          def coerce(value)
            val = value.respond_to?(:to_i) ? value.to_i : value
            raise TypeError, "Cannot convert #{value.inspect} into an Int16" unless valid_value?(val)
            val
          end

          def name
            "Edm.Int16"
          end
        end
      end
    end
  end
end


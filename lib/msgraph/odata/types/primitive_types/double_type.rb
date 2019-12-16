class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class DoubleType < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            Numeric === value
          end

          def coerce(value)
            unless value.respond_to? :to_f
              raise TypeError.new("Cannot convert #{value.inspect} into a float.")
            end
            value.to_f
          end

          def name
            "Edm.Double"
          end
        end
      end
    end
  end
end

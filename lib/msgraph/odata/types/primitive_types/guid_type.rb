class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class GuidType < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            String === value
          end

          def coerce(value)
            case value
            when Symbol
              value.to_s
            when Numeric
              value.to_s
            when String
              value
            else
              raise TypeError, "Cannot convert #{value.inspect} into a Guid."
            end
          end

          def name
            "Edm.Guid"
          end
        end
      end
    end
  end
end

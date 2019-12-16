class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class BooleanType < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            TrueClass === value || FalseClass === value
          end

          def coerce(value)
            value
          end

          def name
            "Edm.Boolean"
          end
        end
      end
    end
  end
end

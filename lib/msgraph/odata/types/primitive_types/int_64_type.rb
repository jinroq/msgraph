class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class Int64Type < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            Integer === value
          end

          def coerce(value)
            value.to_i
          end

          def name
            "Edm.Int64"
          end
        end
      end
    end
  end
end

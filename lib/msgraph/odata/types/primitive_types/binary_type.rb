class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class BinaryType < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            String === value
          end

          def coerce(value)
            value
          end

          def name
            "Edm.Binary"
          end
        end
      end
    end
  end
end

class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class StringType < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            String === value
          end

          def coerce(value)
            value.to_s
          end

          def name
            "Edm.String"
          end
        end
      end
    end
  end
end

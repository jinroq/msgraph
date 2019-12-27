class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class DateTimeOffsetType < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            DateTime === value || Time === value
          end

          def coerce(value)
            DateTime.parse(value)
          end

          def name
            "Edm.DateTimeOffset"
          end
        end
      end
    end
  end
end

class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class DateType < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            Date === value
          end

          def coerce(value)
            begin
              if Date === value
                value
              else
                Date.parse(value.to_s)
              end
            rescue ArgumentError
              raise TypeError.new("Cannot convert #{value.inspect} into a date.")
            end
          end

          def name
            "Edm.Date"
          end
        end
      end
    end
  end
end

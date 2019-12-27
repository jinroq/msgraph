class Msgraph
  module Odata
    module Types
      module PrimitiveTypes
        class StreamType < Msgraph::Odata::Types::BaseType
          def valid_value?(value)
            true
          end

          def coerce(value)
            raise RuntimeError
          end

          def name
            "Edm.Stream"
          end
        end
      end
    end
  end
end

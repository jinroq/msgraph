class Msgraph
  module Odata
    module Types
      # Base class for Types
      class BaseType
        # Name attribute of Type
        attr_reader :name

        def initialize(**args)
          @name = args[:name]
        end

        def coerce(value)
          value
        end

        def collection?
          false
        end
      end
    end
  end
end

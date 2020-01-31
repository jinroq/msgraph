class Msgraph
  module Odata
    # Operations
    #   Custom operations (Actions and Functions) are represented as Action, ActionImport, 
    #   Function, and FunctionImport elements in [OData-CSDL].
    # @see http://docs.oasis-open.org/odata/odata/v4.0/errata03/os/complete/part1-protocol/odata-v4.0-errata03-os-part1-protocol-complete.html#_Toc453752307
    class Operation
      attr_reader :name
      attr_reader :binding_type
      attr_reader :entity_set_type
      attr_reader :parameters
      attr_reader :return_type

      def initialize(args = {})
        @name            = args[:name]
        @entity_set_type = args[:entity_set_type]
        @binding_type    = args[:binding_type]
        @parameters      = args[:parameters]
        @return_type     = args[:return_type]
      end
    end
  end
end

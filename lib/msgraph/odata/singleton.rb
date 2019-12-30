class Msgraph
  module Odata
    # @see https://www.odata.org/getting-started/advanced-tutorial/#singleton
    class Singleton
      attr_reader :name
      attr_reader :type_name

      def initialize(options = {})
        @name       = options[:name]
        @type_name  = options[:type]
        @dispatcher = options[:dispatcher]
      end

      def collection?
        false
      end

      def type
        @dispatcher.get_type_by_name(type_name)
      end
    end
  end
end

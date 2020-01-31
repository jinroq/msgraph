class Msgraph
  module Odata
    module Types
      # EnumType property
      class EnumType < BaseType
        # Member attribute array
        attr_reader :members

        def initialize(args = {})
          super
          @members = args[:members]
        end

        def valid_value?(value)
          member_names.include?(value) || member_values.include?(value)
        end

        def type
          name
        end

        def coerce(value)
          if value && value.is_a?(Integer)
            member = @members.find { |m| m[:value] == value }
            member && member[:name]
          else
            super
          end
        end

        private

        def member_names
          members.map { |m| m[:name] }
        end

        def member_values
          members.map { |m| m[:value] }
        end
      end
    end
  end
end

require 'oga'

require 'msgraph/odata/types'

class Msgraph
  module Odata
    class Dispatcher
      # @see https://docs.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/data-entities/odata#odata-services
      attr_reader :context_url
      attr_reader :metadata

      # 
      def initialize(**args)
        # service root URL
        @context_url = args[:context_url]
        # token
        @token = args[:token]
        # 
        @type_names = {}
        # 
        @metadata = fetch_metadata(args[:metadata_filepath])
        # 
        populate_types_from_metadata
      end

      # Schema attribute's namespace
      def schema_namespace
        'microsoft.graph'
      end

      def entity_types
        @entity_types
      end

      def complex_types
        @complex_types
      end

      def entity_sets
        @entity_sets
      end

      private

      def fetch_metadata(metadata_filepath = nil)
        file =
          if metadata_filepath
            File.read(metadata_filepath)
          else
            # From internet
            client = HTTPClient.new
            client.get("#{context_url}$metadata?detailed=true").body
          end
        Oga::parse_xml(file)
      end
      
      def populate_types_from_metadata
        populate_enum_types
        populate_primitive_types
        populate_complex_types
        populate_entity_types

        populate_entity_sets
      end

      # Populate EnumTypes
      def populate_enum_types
        @enum_types ||= metadata.xpath("//EnumType").map do |type|
          members = type.xpath("./Member").map do |m, i|
            value = m['Value'] && m['Value'].to_i || i
            {
              name:  m["Name"],
              value: value,
            }
          end
          @type_names["#{schema_namespace}.#{type["Name"]}"] =
            Odata::Types::EnumType.new(
              name:    "#{schema_namespace}.#{type["Name"]}",
              members: members
            )
        end
      end

      # Populate PrimitiveTypes
      def populate_primitive_types
        @type_names.merge!(
          "Edm.Binary"         => Odata::Types::PrimitiveTypes::BinaryType.new,
          "Edm.Date"           => Odata::Types::PrimitiveTypes::DateType.new,
          "Edm.Double"         => Odata::Types::PrimitiveTypes::DoubleType.new,
          "Edm.Guid"           => Odata::Types::PrimitiveTypes::GuidType.new,
          "Edm.Int16"          => Odata::Types::PrimitiveTypes::Int16Type.new,
          "Edm.Int32"          => Odata::Types::PrimitiveTypes::Int32Type.new,
          "Edm.Int64"          => Odata::Types::PrimitiveTypes::Int64Type.new,
          "Edm.Stream"         => Odata::Types::PrimitiveTypes::StreamType.new,
          "Edm.String"         => Odata::Types::PrimitiveTypes::StringType.new,
          "Edm.Boolean"        => Odata::Types::PrimitiveTypes::BooleanType.new,
          "Edm.DateTimeOffset" => Odata::Types::PrimitiveTypes::DateTimeOffsetType.new
        )
      end

      # Populate ComplexTypes
      def populate_complex_types
        @complex_types ||= metadata.xpath("//ComplexType").map do |complex_type|
          @type_names["#{schema_namespace}.#{complex_type["Name"]}"] =
            Odata::Types::ComplexType.new(
              name:      "#{schema_namespace}.#{complex_type["Name"]}",
              base_type: complex_type["BaseType"],
              service:   self,
            )
        end
      end

      # Populate EntityTypes
      def populate_entity_types
        @entity_types ||= metadata.xpath("//EntityType").map do |entity|
            @type_names["#{schema_namespace}.#{entity["Name"]}"] =
              Odata::Types::EntityType.new(
                name:                  "#{schema_namespace}.#{entity["Name"]}",
                abstract:              entity["Abstract"] == "true",
                base_type:             entity["BaseType"],
                open_type:             entity["OpenType"] == "true",
                has_stream:            entity["HasStream"] == "true",
                service:               self,
              )
        end
      end

      # Populate EntitySets
      def entity_sets
        @entity_sets ||= metadata.xpath("//EntitySet").map do |entity_set|
          Odata::EntitySet.new(
            name:        entity_set["Name"],
            member_type: entity_set["EntityType"],
            service:     self
          )
        end
      end

    end
  end
end

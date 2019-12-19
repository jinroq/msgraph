require 'ox'

require 'msgraph/odata/types'
require 'msgraph/odata/entity_set'
require 'msgraph/odata/property'

class Msgraph
  module Odata
    class Dispatcher
      # @see https://docs.microsoft.com/en-us/dynamics365/fin-ops-core/dev-itpro/data-entities/odata#odata-services
      attr_reader :context_url
      attr_reader :metadata

      def initialize(**args)
        # service root URL
        @context_url = args[:context_url]
        # token
        @token = args[:token]
        # Names of type
        @type_names = {}
        # Microsoft Graph's metadata
        @metadata = fetch_metadata(args[:metadata_filepath])
        # Populate EnumType/PrimitiveType/ComplexType/EntityType
        # from Microsoft Graph's metadata
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

      # Get properties for type
      def properties_for_type(type_name)
        # Remove the string 'microsoft.graph.' from type_name to get the type's name.
        raw_type_name = remove_namespace(type_name)
        # Get <EntityType Name="#{raw_type_name}"> or <ComplexType Name="#{raw_type_name}">
        type_definition = metadata.locate("//EntityType[@Name='#{raw_type_name}']|//ComplexType[@Name='#{raw_type_name}']")

        # Get Property element of EntityType or ComplexType.
        type_definition.locate('./Property').map do |property|
          options = {
            name:      property['Name'],
            nullable:  property['Nullable'] != 'false',
            type:      get_type_by_name(property['Type']),
          }
          Odata::Property.new(options)
        end
      end

      private

      # Fetch Microsoft Graph's metadata.
      def fetch_metadata(metadata_filepath = nil)
        file =
          if metadata_filepath
            f = File.read(metadata_filepath)
            Ox.dump(f)
          else
            # Fetch metadata over the Internet.
            client = HTTPClient.new
            client.get("#{context_url}$metadata?detailed=true").body
          end
        Ox.parse(file)
      end
      
      # Populate types from metadata.
      def populate_types_from_metadata
        populate_enum_types
        populate_primitive_types
        populate_complex_types
        populate_entity_types

        #populate_entity_sets
      end

      # Populate EnumTypes
      def populate_enum_types
        @enum_types ||= metadata.locate('//EnumType').map do |type|
          members = type.locate('./Member').map do |member|
            value = member['Value'] && member['Value'].to_i || -1 # -1:illegal number
            { name:  member['Name'],
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
          'Edm.Binary'         => Odata::Types::PrimitiveTypes::BinaryType.new,
          'Edm.Date'           => Odata::Types::PrimitiveTypes::DateType.new,
          'Edm.Double'         => Odata::Types::PrimitiveTypes::DoubleType.new,
          'Edm.Guid'           => Odata::Types::PrimitiveTypes::GuidType.new,
          'Edm.Int16'          => Odata::Types::PrimitiveTypes::Int16Type.new,
          'Edm.Int32'          => Odata::Types::PrimitiveTypes::Int32Type.new,
          'Edm.Int64'          => Odata::Types::PrimitiveTypes::Int64Type.new,
          'Edm.Stream'         => Odata::Types::PrimitiveTypes::StreamType.new,
          'Edm.String'         => Odata::Types::PrimitiveTypes::StringType.new,
          'Edm.Boolean'        => Odata::Types::PrimitiveTypes::BooleanType.new,
          'Edm.DateTimeOffset' => Odata::Types::PrimitiveTypes::DateTimeOffsetType.new
        )
      end

      # Populate ComplexTypes
      def populate_complex_types
        @complex_types ||= metadata.locate('//ComplexType').map do |complex_type|
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
        @entity_types ||= metadata.locate('//EntityType').map do |entity|
          @type_names["#{schema_namespace}.#{entity["Name"]}"] =
            Odata::Types::EntityType.new(
              name:       "#{schema_namespace}.#{entity["Name"]}",
              abstract:   entity['Abstract'] == 'true',
              base_type:  entity['BaseType'],
              open_type:  entity['OpenType'] == 'true',
              has_stream: entity['HasStream'] == 'true',
              service:    self,
            )
        end
      end

      # Populate EntitySets
      def entity_sets
        @entity_sets ||= metadata.locate('//EntitySet').map do |entity_set|
          Odata::EntitySet.new(
            name:        entity_set['Name'],
            member_type: entity_set['EntityType'],
            service:     self
          )
        end
      end

      # Remove namespace
      # @param name [String]
      def remove_namespace(name)
        name.gsub("#{schema_namespace}.", '')
      end
    end
  end
end

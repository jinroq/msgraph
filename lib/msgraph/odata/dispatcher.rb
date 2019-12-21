require 'oga'

require 'msgraph/odata/types'
require 'msgraph/odata/entity_set'
require 'msgraph/odata/property'
require 'msgraph/odata/operation'
require 'msgraph/odata/singleton'

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
        populate_types
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

      def actions
        @actions
      end

      def functions
        @functions
      end

      def singletons
        @singletons
      end

      # Get properties for type
      def properties_for_type(type_name)
        # Remove the string 'microsoft.graph.' from type_name to get the type's name.
        raw_type_name = remove_namespace(type_name)
        # Get <EntityType Name="#{raw_type_name}"> or <ComplexType Name="#{raw_type_name}">
        type_definition = metadata.xpath("//EntityType[@Name='#{raw_type_name}']|//ComplexType[@Name='#{raw_type_name}']")

        # Get Property element of EntityType or ComplexType.
        type_definition.xpath('./Property').map do |property|
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
            File.read(metadata_filepath)
          else
            # Fetch metadata over the Internet.
            client = HTTPClient.new
            client.get("#{context_url}$metadata?detailed=true").body
          end

        Oga.parse_xml(file)
      end
      
      # Populate types from metadata.
      def populate_types
        populate_enum_types
        populate_primitive_types
        populate_complex_types
        populate_entity_types

        populate_entity_sets
        populate_actions
        populate_functions
        populate_singletons
      end

      # Populate EnumTypes
      def populate_enum_types
        @enum_types ||= metadata.xpath('//EnumType').map do |type|
          members = type.xpath('./Member').map do |member|
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
        @complex_types ||= metadata.xpath('//ComplexType').map do |complex_type|
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
        @entity_types ||= metadata.xpath('//EntityType').map do |entity|
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
      def populate_entity_sets
        @entity_sets ||= metadata.xpath('//EntitySet').map do |entity_set|
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

      # Populate Actions
      def populate_actions
        @actions ||= metadata.xpath("//Action").map do |action|
          build_operation(action)
        end
      end

      # Build Msgraph::Odata::Operation
      def build_operation(operation_xml)
        # <Action Name="createSession" IsBound="true">
        #   <Parameter Name="this" Type="microsoft.graph.workbook"/>
        #   <Parameter Name="persistChanges" Type="Edm.Boolean" Nullable="false"/>
        #   <ReturnType Type="microsoft.graph.workbookSessionInfo"/>
        # </Action>
        operation_xml.xpath("./Parameter[@Name='bindingParameter']|./Parameter[@Name='bindingparameter']")
        binding_type =
          if operation_xml["IsBound"] == "true"
            binding_parameter = operation_xml.xpath("./Parameter[@Name='bindingParameter']|./Parameter[@Name='bindingparameter']")
            if !binding_parameter.empty?
              type_name = binding_parameter.first["Type"]
              get_type_by_name(type_name)
            else
              # do nohing...
              #
              # Actions and Functions MAY be bound to an entity type, primitive type,
              # complex type, or a collection. 
              # The first parameter of a bound operation is the binding parameter.
              #
              # But...
              #
              # <Action Name="createSession" IsBound="true">
              #    <Parameter Name="this" Type="microsoft.graph.workbook"/>
              #   <Parameter Name="persistChanges" Type="Edm.Boolean" Nullable="false"/>
              #   <ReturnType Type="microsoft.graph.workbookSessionInfo"/>
              # </Action>
            end
          end

        # Get EntitySetType from metadata.
        entity_set_type =
          if operation_xml["EntitySetType"]
            entity_set_by_name(operation_xml["EntitySetType"])
          end

        # Add Parameter elements to array.
        parameters = operation_xml.xpath("./Parameter").inject([]) do |result, parameter|
          unless parameter["Name"] == 'bindingParameter' # outside bindingParameter
            result.push(
              { name:     parameter["Name"],
                type:     get_type_by_name(parameter["Type"]),
                nullable: parameter["Nullable"],
              }
            )
          end
          result
        end

        # Get ReturnType from metadata.
        return_type =
          if return_type_node = operation_xml.xpath("./ReturnType").first
            get_type_by_name(return_type_node["Type"])
          end

        # Setings Msgraph::Odata::Operation
        params = {
          name:            operation_xml["Name"],
          entity_set_type: entity_set_type,
          binding_type:    binding_type,
          parameters:      parameters,
          return_type:     return_type
        }
        Odata::Operation.new(params)
      end

      # 
      def get_type_by_name(type_name)
        # If type_name exists as a key in @type_names, build the corresponding value,
        # otherwise build collection.
        @type_names[type_name] || build_collection(type_name)
      end

      # Build Msgraph::Odata::Types::CollectionType
      def build_collection(collection_name)
        # Collection(microsoft.graph.assignedPlan) -> microsoft.graph.assignedPlan
        member_type_name = collection_name.gsub(/Collection\(([^)]+)\)/, "\\1")

        Odata::Types::CollectionType.new(
          name: collection_name,
          member_type: @type_names[member_type_name]
        )
      end

      # 
      def entity_set_by_name(name)
        # entity_sets is an array, so it looks for a match in name from each element.
        entity_sets.find { |entity_set| entity_set.name == name }
      end

      # Populate Functions
      def populate_functions
        @functions ||= metadata.xpath("//Function").map do |function|
          build_operation(function)
        end
      end

      # Populate Singletons
      def populate_singletons
        @singletons ||= metadata.xpath("//Singleton").map do |singleton|
          Odata::Singleton.new(
            name:    singleton["Name"],
            type:    singleton["Type"],
            service: self
          )
        end
      end

    end
  end
end

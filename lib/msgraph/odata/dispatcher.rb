require 'nokogiri'

require 'msgraph/odata/errors'
require 'msgraph/odata/request'

require 'msgraph/odata/types'
require 'msgraph/odata/entity_set'
require 'msgraph/odata/property'
require 'msgraph/odata/operation'
require 'msgraph/odata/singleton'
require 'msgraph/odata/property'
require 'msgraph/odata/navigation_property'


class Msgraph
  module Odata
    class Dispatcher
      attr_reader :context_url
      attr_reader :metadata

      attr_reader :entity_types,
                  :complex_types,
                  :entity_sets,
                  :actions,
                  :functions,
                  :singletons

      def initialize(args = {})
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

      # Get properties for type
      def properties_for_type(type_name)
        # Remove the string 'microsoft.graph.' from type_name to get the type's name.
        raw_type_name = remove_namespace(type_name)
        # Get <EntityType Name="#{raw_type_name}"> or <ComplexType Name="#{raw_type_name}">
        type_definition = metadata.xpath("//EntityType[@Name='#{raw_type_name}']|//ComplexType[@Name='#{raw_type_name}']")

        # Get Property element of EntityType or ComplexType.
        type_definition.xpath('./Property').map do |property|
          Odata::Property.new(
            name:      property['Name'],
            nullable:  property['Nullable'] != 'false',
            type:      get_type_by_name(property['Type'])
          )
        end
      end

      # 
      def navigation_properties_for_type(type_name)
        # Delete 'microsoft.graph.' from type_name.
        raw_type_name = remove_namespace(type_name)
        # Get <EntityType Name="#{raw_type_name}"> or <ComplexType Name="#{raw_type_name}">
        type_definition = metadata.xpath("//EntityType[@Name='#{raw_type_name}']|//ComplexType[@Name='#{raw_type_name}']")

        # Get Property element of EntityType or NavigationProperty.
        type_definition.xpath('./NavigationProperty').map do |property|
          Odata::NavigationProperty.new(
            name:            property['Name'],
            nullable:        property['Nullable'] != 'false',
            type:            get_type_by_name(property['Type']),
            contains_target: property['ContainsTarget'],
            partner:         property['Partner']
          )
        end
      end

      def request(args = {})
        parsed_uri = URI(args[:uri])
        query = URI.decode_www_form(parsed_uri.query || '')
        parsed_uri.query = URI.encode_www_form(query)
        uri = parsed_uri.to_s

        req = Request.new(args[:method], uri, args[:token], args[:params])
        req.perform
      end

      # HTTP GET
      def get(path, *select_properties)
        camel_case_select_properties = select_properties.map do |property|
          Utils.snake_case_to_camel_case(property)
        end

        unless camel_case_select_properties.empty?
          encoded_select_properties = URI.encode_www_form(
            '$select' => camel_case_select_properties.join(',')
          )
          path = "#{path}?#{encoded_select_properties}"
        end

        response = request(
          method: :get,
          uri:    "#{context_url}#{path}",
          token:  @token
        )
        { etype: get_type_for_odata_response(response), attributes: response }
      end

      # HTTP POST
      def create(path, params)
        request(
          method: :post,
          uri: "  #{context_url}#{path}",
          token:  @token,
          params: params
        )
      end

      # HTTP PATCH
      def update(path, params)
        request(
          method: :patch,
          uri:    "#{context_url}#{path}",
          token:  @token,
          params: params
        )
      end

      # HTTP DELETE
      def delete(path)
        request(
          method: :delete,
          uri:    "#{context_url}#{path}",
          token:  @token
        )
      end

      # 
      def get_type_for_odata_response(resopnse)
        if odata_type_string = resopnse['@odata.type']
          get_type_by_name(type_name_from_odata_type_field(odata_type_string))
        elsif context = resopnse['@odata.context']
          singular, segments = segments_from_odata_context_field(context)
          first_entity_type =
            get_type_by_name("Collection(#{entity_set_by_name(segments.shift).member_type})")
          entity_type = segments.reduce(first_entity_type) do |last_entity_type, segment|
            last_entity_type.member_type.navigation_property_by_name(segment).type
          end
          if singular && entity_type.respond_to?(:member_type)
            entity_type.member_type
          else
            entity_type
          end
        end
      end

      # 
      def get_type_by_name(type_name)
        # If type_name exists as a key in @type_names, build the corresponding value,
        # otherwise build collection.
        @type_names[type_name] || build_collection(type_name)
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

        ::Nokogiri::XML(file).remove_namespaces!
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
        @enum_types ||= metadata.xpath('//EnumType').map do |enum_type|
          members = enum_type.xpath('./Member').map do |member|
            value = member['Value'] && member['Value'].to_i || -1 # -1:illegal number
            { name:  member['Name'],
              value: value,
            }
          end
          @type_names["#{schema_namespace}.#{enum_type["Name"]}"] =
            Odata::Types::EnumType.new(
              name:    "#{schema_namespace}.#{enum_type["Name"]}",
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
              name:       "#{schema_namespace}.#{complex_type["Name"]}",
              base_type:  complex_type['BaseType'],
              dispatcher: self,
            )
        end
      end

      # Populate EntityTypes
      def populate_entity_types
        @entity_types ||= metadata.xpath('//EntityType').map do |entity_type|
          @type_names["#{schema_namespace}.#{entity_type['Name']}"] =
            Odata::Types::EntityType.new(
              name:       "#{schema_namespace}.#{entity_type['Name']}",
              abstract:   entity_type['Abstract'] == 'true',
              base_type:  entity_type['BaseType'],
              open_type:  entity_type['OpenType'] == 'true',
              has_stream: entity_type['HasStream'] == 'true',
              dispatcher: self
            )
        end
      end

      # Populate EntitySets
      def populate_entity_sets
        @entity_sets ||= metadata.xpath('//EntitySet').map do |entity_set|
          Odata::EntitySet.new(
            name:        entity_set['Name'],
            member_type: entity_set['EntityType'],
            dispatcher:  self
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
        @actions ||= metadata.xpath('//Action').map do |action|
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
          if operation_xml['IsBound'] == 'true'
            binding_parameter = operation_xml.xpath("./Parameter[@Name='bindingParameter']|./Parameter[@Name='bindingparameter']")
            if !binding_parameter.empty?
              type_name = binding_parameter.first['Type']
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
          if operation_xml['EntitySetType']
            entity_set_by_name(operation_xml['EntitySetType'])
          end

        # Add Parameter elements to array.
        parameters = operation_xml.xpath('./Parameter').inject([]) do |result, parameter|
          unless parameter['Name'] == 'bindingParameter' # outside bindingParameter
            result.push(
              { name:     parameter['Name'],
                type:     get_type_by_name(parameter['Type']),
                nullable: parameter['Nullable'],
              }
            )
          end
          result
        end

        # Get ReturnType from metadata.
        return_type =
          if return_type_node = operation_xml.xpath('./ReturnType').first
            get_type_by_name(return_type_node['Type'])
          end

        # Setings Msgraph::Odata::Operation
        params = {
          name:            operation_xml['Name'],
          entity_set_type: entity_set_type,
          binding_type:    binding_type,
          parameters:      parameters,
          return_type:     return_type
        }
        Odata::Operation.new(params)
      end

      # Build Msgraph::Odata::Types::CollectionType
      def build_collection(collection_name)
        # Collection(microsoft.graph.assignedPlan) -> microsoft.graph.assignedPlan
        member_type_name = collection_name.gsub(/Collection\(([^)]+)\)/, '\\1')

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
        @functions ||= metadata.xpath('//Function').map do |function|
          build_operation(function)
        end
      end

      # Populate Singletons
      def populate_singletons
        @singletons ||= metadata.xpath('//Singleton').map do |singleton|
          Odata::Singleton.new(
            name:       singleton['Name'],
            type:       singleton['Type'],
            dispatcher: self
          )
        end
      end

      def type_name_from_odata_type_field(odata_type_field)
        odata_type_field.sub('#', '')
      end

      def segments_from_odata_context_field(odata_context_field)
        segments = odata_context_field.split('$metadata#').last.split('/').map do |s|
          s.split("(").first
        end
        segments.pop if singular = (segments.last == '$entity')
        [singular, segments]
      end

    end
  end
end

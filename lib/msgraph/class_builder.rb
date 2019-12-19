class MicrosoftGraph
  class ClassBuilder

    def initialize
      @loaded = false
      @dispatcher_namespace = nil
    end

    # 
    def load(dispatcher)
      if !loaded?
        # Schema attribute's namespace
        @dispatcher_namespace = dispatcher.schema_namespace

        # 
        dispatcher.entity_types.each do |entity_type|
          create_class(entity_type)
        end

=begin
        #
        dispatcher.complex_types.each do |complex_type|
          create_class(complex_type)
        end

        # 
        dispatcher.entity_sets.each do |entity_set|
          add_graph_association(entity_set)
        end

        # 
        dispatcher.actions.each do |action|
          add_action_method(action)
        end

        # 
        dispatcher.functions.each do |function|
          add_function_method(function)
        end

        # 
        dispatcher.singletons.each do |singleton|
          class_name = classify(singleton.type_name)
          MicrosoftGraph.instance_eval do
            resource_name = singleton.name
            define_method(OData.convert_to_snake_case(resource_name)) do
              MicrosoftGraph
                .const_get(class_name)
                .new(
                  graph:         self,
                  resource_name: resource_name,
                  parent:        self
                ).tap(&:fetch)
            end
          end
        end

        # 
        MicrosoftGraph.instance_eval do
          define_method(:navigation_properties) do
            dispatcher
              .entity_sets
              .concat(dispatcher.singletons)
              .map { |navigation_property|
                [navigation_property.name.to_sym, navigation_property]
              }.to_h
          end
        end
=end

        @loaded = true
      end
    end

    def loaded?
      @loaded
    end

    private

    # Create class.
    #
    # @param type [Msgraph::Odata::Types::EntityType]
    def create_class(type)
      superklass = get_superklass(type)
      klass = MicrosoftGraph.const_set(classify(type.name), Class.new(superklass))
      klass.const_set("ODATA_TYPE", type)

      klass.instance_eval do
        def self.odata_type
          const_get("ODATA_TYPE")
        end
      end

      create_properties(klass, type)
      create_navigation_properties(klass, type) if type.respond_to?(:navigation_properties)
    end

    # humm...
    def get_superklass(type)
      if type.base_type.nil?
        (type.class == Msgraph::Odata::Types::ComplexType) ?
          Msgraph::Base :
          Msgraph::BaseEntity
      else
        Object.const_get("Msgraph::" + classify(type.base_type))
      end
    end

    # 
    def classify(name)
      raw_name = name.gsub("#{@dispatcher_namespace}.", "")
      raw_name.to_s.slice(0, 1).capitalize + raw_name.to_s.slice(1..-1)
    end

    def create_properties(klass, type)
      property_map = type.properties.map { |property|
        puts "[#{self.class.name}] - [#{__method__}] klass1 => #{klass}"
        puts "[#{self.class.name}] - [#{__method__}] property1 => #{property.inspect}"
        define_getter_and_setter(klass, property)
        [ OData.convert_to_snake_case(property.name).to_sym,
          property
        ]
      }.to_h

      klass.class_eval do
        define_method(:properties) do
          super().merge(property_map)
        end
      end
    end

    def remove_dispatcher_namespace(name)
      name.gsub("#{@dispatcher_namespace}.", "")
    end

    # 
    def self.add_graph_association(entity_set)
      klass = get_namespaced_class(entity_set.member_type)
      resource_name = entity_set.name.gsub("#{@dispatcher_namespace}.", "")
      odata_collection =
        OData::CollectionType.new(member_type: klass.odata_type, name: entity_set.name)
      MicrosoftGraph.send(:define_method, resource_name) do
        @association_collections[entity_set.name] ||=
          MicrosoftGraph::CollectionAssociation
            .new(
              type:          odata_collection,
              resource_name: resource_name,
              parent:        self
            )
            .tap do |collection|
              collection.graph = self
            end
      end
    end

    # 
    def self.create_properties(klass, type)
      property_map = type.properties.map { |property|
        define_getter_and_setter(klass, property)
        [
          OData.convert_to_snake_case(property.name).to_sym,
          property
        ]
      }.to_h

      klass.class_eval do
        define_method(:properties) do
          super().merge(property_map)
        end
      end
    end

    def self.define_getter_and_setter(klass, property)
      klass.class_eval do
        property_name = OData.convert_to_snake_case(property.name)
        define_method(property_name.to_sym) do
          get(property_name.to_sym)
        end
        define_method("#{property_name}=".to_sym) do |value|
          set(property_name.to_sym, value)
        end
      end
    end

    def self.create_navigation_properties(klass, type)
      klass.class_eval do
        type.navigation_properties.each do |navigation_property|
          navigation_property_name = OData.convert_to_snake_case(navigation_property.name).to_sym
          define_method(navigation_property_name.to_sym) do
            get_navigation_property(navigation_property_name.to_sym)
          end
          unless navigation_property.collection?
            define_method("#{navigation_property_name}=".to_sym) do |value|
              set_navigation_property(navigation_property_name.to_sym, value)
            end
          end
        end

        define_method(:navigation_properties) do
          type.navigation_properties.map { |navigation_property|
            [
              OData.convert_to_snake_case(navigation_property.name).to_sym,
              navigation_property
            ]
          }.to_h
        end
      end
    end

    def self.add_function_method!(function)
      klass = get_namespaced_class(function.binding_type.name)
      klass.class_eval do
        define_method(OData.convert_to_snake_case(function.name).to_sym) do |params={}|
          raise NoAssociationError unless parent
          raise_no_graph_error! unless graph
          function_params = params.map do |param_key, param_value|
            "#{OData.convert_to_camel_case(param_key)}='#{param_value}'"
          end
          response = graph.dispatcher.get("#{path}/microsoft.graph.#{function.name}(#{function_params.join(',')})")
          if function.return_type
            if function.return_type.collection?
              Collection.new(function.return_type, response[:attributes]['value'])
            else
              ClassBuilder.get_namespaced_class(function.return_type.name).new(attributes: response[:attributes]['value'])
            end
          end
        end
      end
    end

    def self.add_action_method!(action)
      klass = get_namespaced_class(action.binding_type.name)
      klass.class_eval do
        define_method(OData.convert_to_snake_case(action.name).to_sym) do |args={}|
          raise NoAssociationError unless parent
          raise_no_graph_error! unless graph
          response = graph.dispatcher.post("#{path}/#{action.name}", OData.convert_keys_to_camel_case(args).to_json)
          if action.return_type
            if action.return_type.collection?
              Collection.new(action.return_type, response['value'])
            else
              ClassBuilder.get_namespaced_class(action.return_type.name).new(attributes: response['value'])
            end
          end
        end
      end
    end

    def self.get_namespaced_class(property_name)
      klass_name = classify(property_name)
      klass      = begin
        MicrosoftGraph.const_get(klass_name) if MicrosoftGraph.const_defined?(klass_name)
      rescue NameError
        return false
      end
      klass && MicrosoftGraph::BaseEntity != klass.superclass && klass
    end
  end
end

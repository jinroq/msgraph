class Msgraph
  class ClassBuilder
    def self.get_namespaced_class(property_name)
      klass_name = classify(property_name)
      klass      = begin
        Msgraph.const_get(klass_name) if Msgraph.const_defined?(klass_name)
      rescue NameError
        return false
      end
      klass && Msgraph::BaseEntity != klass.superclass && klass
    end

    # 
    def self.classify(name)
      raw_name = name.gsub("#{@dispatcher_namespace}.", '')
      raw_name.to_s.slice(0, 1).capitalize + raw_name.to_s.slice(1..-1)
    end

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
          class_name = self.class.classify(singleton.type_name)
          Msgraph.instance_eval do
            resource_name = singleton.name
            define_method(Utils.camel_case_to_snake_case(resource_name)) do
              Msgraph
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
        Msgraph.instance_eval do
          define_method(:navigation_properties) do
            dispatcher
              .entity_sets
              .concat(dispatcher.singletons)
              .map { |navigation_property|
                [navigation_property.name.to_sym, navigation_property]
              }.to_h
          end
        end

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
      klass = Msgraph.const_set(self.class.classify(type.name), Class.new(superklass))
      klass.const_set('ODATA_TYPE', type)

      klass.instance_eval do
        def self.odata_type
          const_get('ODATA_TYPE')
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
        Object.const_get("Msgraph::#{self.class.classify(type.base_type)}")
      end
    end

    # 
    def create_properties(klass, type)
      property_map = type.properties.map { |property|
        define_getter_and_setter(klass, property)
        [ Utils.camel_case_to_snake_case(property.name).to_sym,
          property
        ]
      }.to_h

      klass.class_eval do
        define_method(:properties) do
          super().merge(property_map)
        end
      end
    end

    def create_navigation_properties(klass, type)
      klass.class_eval do
        type.navigation_properties.each do |navigation_property|
          navigation_property_name = Utils.camel_case_to_snake_case(navigation_property.name).to_sym
          define_method(navigation_property_name) do
            get_navigation_property(navigation_property_name)
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
              Utils.camel_case_to_snake_case(navigation_property.name).to_sym,
              navigation_property
            ]
          }.to_h
        end
      end
      klass
    end

    # 
    def remove_dispatcher_namespace(name)
      name.gsub("#{@dispatcher_namespace}.", '')
    end

    # 
    def add_graph_association(entity_set)
      klass = self.class.get_namespaced_class(entity_set.member_type)
      resource_name = entity_set.name.gsub("#{@dispatcher_namespace}.", '')
      odata_collection =
        Odata::Types::CollectionType.new(member_type: klass.odata_type, name: entity_set.name)
      Msgraph.send(:define_method, resource_name) do
        @association_collections[entity_set.name] ||=
          Msgraph::CollectionAssociation
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

    def define_getter_and_setter(klass, property)
      klass.class_eval do
        property_name = Utils.camel_case_to_snake_case(property.name)
        define_method(property_name.to_sym) do
          get(property_name.to_sym)
        end
        define_method("#{property_name}=".to_sym) do |value|
          set(property_name.to_sym, value)
        end
      end
    end

    def add_action_method(action)
      klass = self.class.get_namespaced_class(action.binding_type.name)
      klass.class_eval do
        define_method(Utils.camel_case_to_snake_case(action.name).to_sym) do |args={}|
          raise NoAssociationError unless parent
          raise_no_graph_error! unless graph
          response = graph.dispatcher.post("#{path}/#{action.name}", Utils.to_camel_case_keys(args).to_json)
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

    def add_function_method(function)
      klass = self.class.get_namespaced_class(function.binding_type.name)
      klass.class_eval do
        define_method(Utils.camel_case_to_snake_case(function.name).to_sym) do |params={}|
          raise NoAssociationError unless parent
          raise_no_graph_error! unless graph
          function_params = params.map do |param_key, param_value|
            "#{Utils.camel_case_to_snake_case(param_key)}='#{param_value}'"
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
  end
end

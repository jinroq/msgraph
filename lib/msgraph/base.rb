# frozen_string_literal: true
class Msgraph
  class Base
  def initialize(**args)
    @cached_navigation_property_values = {}
    @cached_property_values            = {}
    if args[:attributes]
      initialize_serialized_properties(args[:attributes], args[:persisted])
    end
    @dirty = !args[:persisted]
    @dirty_properties =
      if @dirty
        @cached_property_values.keys.inject({}) do |result, key|
          result[key] = true
          result
        end
      else
        {}
      end
  end

  def properties
    {}
  end

  def odata_type
    self.class.const_get("ODATA_TYPE").name
  end

  def as_json(**args)
    (if args[:only]
     @cached_property_values.select { |key,v| args[:only].include? key }
    elsif args[:except]
      @cached_property_values.reject { |key,v| args[:except].include? key }
    else
      @cached_property_values
     end).inject({}) do |result, (k,v)|
      k = Utils.snake_case_to_camel_case(k) if args[:snake_case_to_camel_case]
      result[k.to_s] = v.respond_to?(:as_json) ? v.as_json(args) : v
      result
    end
  end

  def to_json(**args)
    as_json(args).to_json
  end

  def dirty?
    @dirty || @cached_property_values.any? { |key, value|
      value.respond_to?(:dirty?) && value.dirty?
    }
  end

  def mark_clean
    @dirty = false
    @dirty_properties = {}
    @cached_property_values.each { |key, value|
      value.respond_to?(:mark_clean) && value.mark_clean
    }
  end

  private

  def get(property_name)
    if properties[property_name].collection?
      @cached_property_values[property_name] ||= Collection.new(properties[property_name].type)
    else
      @cached_property_values[property_name]
    end
  end

  def set(property_name, value)
    property = properties[property_name]

    raise NonNullableError unless property.nullable_match?(value)
    if property.collection?
      raise TypeError unless value.all? { |v| property.collection_type_match?(v) }
      @cached_property_values[property_name] = Collection.new(property.type, value)
    else
      raise TypeError unless property.type_match?(value)
      @cached_property_values[property_name] = property.coerce_to_type(value)
    end
    @dirty = true
    @dirty_properties[property_name] = true
  end

  def initialize_serialized_properties(raw_attributes, from_server = false)
    unless raw_attributes.respond_to? :keys
      raise TypeError.new("Cannot initialize #{self.class} with attributes: #{raw_attributes.inspect}")
    end
    attributes = Utils.to_snake_case_keys(raw_attributes)
    properties.each do |property_key, property|
      if attributes.keys.include?(property_key.to_s)
        value = attributes[property_key.to_s]
        @cached_property_values[property_key] =
          if property.collection?
            Collection.new(property.type, value)
          elsif klass = Msgraph::ClassBuilder.get_namespaced_class(property.type.name)
            klass.new(attributes: value)
          else
            if from_server && ! property.type_match?(value) && Odata::Types::EnumType === property.type
              value.to_s
            else
              property.coerce_to_type(value)
            end
          end
      end
    end
  end
end
end

class Msgraph::BaseError < StandardError; end

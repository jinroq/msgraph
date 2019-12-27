class Msgraph
  module Utils
    # convert camelCase -> snake_case
    def self.camel_case_to_snake_case(str)
      return str unless str.is_a?(String)

      first_letter, rest = str.to_s.split('', 2)
      "#{first_letter}#{rest.gsub(/([A-Z])/, '_\1')}".downcase
    end

    # convert snake_case -> camelCase
    def self.snake_case_to_camel_case(str)
      return str unless str.is_a?(String)

      first_letter, rest = str.to_s.split('', 2)
      cameled_rest = rest.gsub(/_(.)/) { |l| l[1].upcase }
      first_letter.downcase.concat(cameled_rest)
    end

    #
    def self.to_snake_case_keys(properties)
      if properties.respond_to? :keys
        results = {}
        properties.each do |key, value|
          results[camel_case_to_snake_case(key)] = to_snake_case_keys(value)
        end
        results
      else
        properties
      end
    end

    # 
    def self.to_camel_case_keys(properties)
      if properties.respond_to? :keys
        results = {}
        properties.each do |key, value|
          results[snake_case_to_camel_case(key)] = to_camel_case_keys(value)
        end
        results
      elsif properties.is_a? Array
        properties.map { |m| to_camel_case_keys(m) }
      else
        properties
      end
    end
  end
end

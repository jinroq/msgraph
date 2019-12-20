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
  end
end

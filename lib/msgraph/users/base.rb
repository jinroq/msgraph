module Msgraph::Users
  require 'httpclient'

  require 'msgraph/properties'

  class Base
    # OData query parameters
    # @see https://docs.microsoft.com/en-us/graph/query-parameters?context=graph%2Fapi%2F1.0&view=graph-rest-1.0#odata-system-query-options
    attr_accessor :count
    attr_accessor :expand
    attr_accessor :filter
    attr_accessor :format
    attr_accessor :orderby
    attr_accessor :search
    attr_accessor :select
    attr_accessor :skip
    attr_accessor :top

    attr_accessor :skip_token

    SYSTEM_QUERY_OPTIONS = [
      # OData system query options
      :count,
      :expand,
      :filter,
      :format,
      :orderby,
      :search,
      :select,
      :skip,
      :top,
      # Other query parameters
      :skip_token
    ]

    def self.camel_case_to_snake_case(str)
      return str unless str.is_a?(String)

      first_letter, rest = str.to_s.split("", 2)
      "#{first_letter}#{rest.gsub(/([A-Z])/, '_\1')}".downcase
    end

    def self.snake_case_to_camel_case(str)
      return str unless str.is_a?(String)

      first_letter, rest = str.to_s.split("", 2)
      cameled_rest = rest.gsub(/_(.)/) { |l| l[1].upcase }
      first_letter.downcase.concat(cameled_rest)
    end

    def initialize(args = {})
      @base_url = "#{args[:msgraph_api_endpoint]}/#{args[:api_ver]}/users/"
    end

  end

  class BaseError < StandardError; end

end

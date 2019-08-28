module Msgraph
  module User
    require 'httpclient'

    require 'msgraph/properties'

    class Base
      attr_accessor :token

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

    end

    class BaseError < StandardError; end

  end
end

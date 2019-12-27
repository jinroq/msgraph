class Msgraph
  module Odata
    class Request

      # 
      def initialize(method = :get, uri = '', token = nil, params = nil)
        @method  = method.to_s.downcase.to_sym
        @uri     = URI(uri)
        @params  = params.nil? ? {} : params
        # HTTP HEADER
        @headers = {
          'Authorization' => "Bearer #{token}",
          'Content-Type'  => 'application/json',
        }
      end

      # send request
      def perform
        client = HTTPClient.new
        response = client.send(@method, @uri, @params, @headers)

        raise ServerError.new(response)         unless response.code <  500
        raise AuthenticationError.new(response) if     response.code == 401
        raise AuthorizationError.new(response)  if     response.code == 403
        raise ClientError.new(response)         unless response.code <  400

        if response.body
          begin
            Utils.to_snake_case_keys(JSON.parse(response.body))
          rescue JSON::ParserError => e
            # 
            {}
          end
        else
          # 
          {}
        end
      end

      private

    end
  end
end

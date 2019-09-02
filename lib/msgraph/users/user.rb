module Msgraph
  module Users
    class User < Base

      def initialize(args = {})
        raise UserError.new("Does not exist ':token'.") unless args.key?(:token)
        @token = args[:token]

        @count   = args[:count]   || false # unsupport
        @expand  = args[:expand]  || []
        @filter  = args[:filter]  || []
        @format  = args[:format]  || []
        @orderby = args[:orderby] || []
        @search  = args[:search]  || []
        @select  = args[:select]  || []
        @skip    = args[:skip]    || []

        @skip_token = args[:skip_token] || []
      end

      def list
        query = {}
        # $select parameter
        #query.merge!({ '$select' => @select.join(',') }) if @select.size > 0
        if @select.size > 0
          query.merge!({ '$select' => @select.map { |key_name|
                           if key_name.is_a?(Symbol)
                             self.class.snake_case_to_camel_case(key_name.to_s)
                           elsif key_name.is_a?(String)
                             key_name
                           else
                             raise UserError.new("'#{key_name}' is invalid value.")
                           end
                         }.join(',') })
        end

        client = HTTPClient.new
        response = client.get("#{Msgraph::BASE_URL}/v1.0/users/", query, header)
        case response.code
        when 200
          body = JSON.parse(response.body)
        else
          raise UserError.new(response.inspect)
        end

        users = body['value']

        return users.map do |user|
          result = Msgraph::Properties::USER_PROPERTIES.inject({}) do |element, property|
            element.merge!({ self.class.camel_case_to_snake_case(property).to_sym => user[property] }) unless user[property].nil?
            element
          end
          result[:odata_context] = body['@odata.context']
          result
        end
      end

      def get(args = {})
        raise UserError.new("Does not exist ':id' or ':user_principal_name'.") unless args.key?(:id) || args.key?(:user_principal_name)
        id = args[:id] || args[:user_principal_name]
        client = HTTPClient.new
        query = {}
        response = client.get("#{Msgraph::BASE_URL}/v1.0/users/#{id}", query, header)
        case response.code
        when 200
          #puts "body['@odata.context'] => #{body['@odata.context']}"
          body = JSON.parse(response.body)
        when 202
        # when the request has been processed successfully
        # but the server requires more time to complete related background operations.
        else
          raise UserError.new(response.inspect)
        end

        return { id:                  body['id'],
                 user_principal_name: body['userPrincipalName'],
                 display_name:        body['displayName'],
                 given_name:          body['givenName'],
                 job_title:           body['jobTitle'],
                 mail:                body['mail'],
                 mobile_phone:        body['mobilePhone'],
                 business_phones:     body['businessPhones'].inspect,
                 office_location:     body['officeLocation'],
                 preferred_language:  body['preferredLanguage'],
                 surname:             body['surname'],
        }
      end

      def create
      end

      def update
      end

      def delete
      end

      def delta
      end

      private

      def header
        { 'Authorization' => "Bearer #{token}",
          'Content-Type'  => 'application/json',
        }
      end

      def body
      end

    end

    class UserError < StandardError; end

  end
end

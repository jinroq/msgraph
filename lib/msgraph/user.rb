module Msgraph
  require 'httpclient'

  class User

    attr_accessor :token

    def initialize(args = {})
      raise UserError.new("Does not exist ':token'.") unless args.key?(:token)
      @token = args[:token]
    end

    def list
      client = HTTPClient.new
      query = {}
      response = client.get("#{Msgraph::BASE_URL}/v1.0/users/", query, header)
      raise UserError.new(response.inspect) unless response.code == 200
      body = JSON.parse(response.body)

      #puts "body['@odata.context'] => #{body['@odata.context']}"
      users = body['value']
      return users.map { |user|
        { id:                  user['id'],
          user_principal_name: user['userPrincipalName'],
          display_name:        user['displayName'],
          given_name:          user['givenName'],
          job_title:           user['jobTitle'],
          mail:                user['mail'],
          mobile_phone:        user['mobilePhone'],
          business_phones:     user['businessPhones'].inspect,
          office_location:     user['officeLocation'],
          preferred_language:  user['preferredLanguage'],
          surname:             user['surname'],
        }
      }
    end
    alias_method :users, :list

    def get(args = {})
      raise UserError.new("Does not exist ':id' or ':user_principal_name'.") unless args.key?(:id) || args.key?(:user_principal_name)
      id = args[:id] || args[:user_principal_name]
      client = HTTPClient.new
      query = {}
      response = client.get("#{Msgraph::BASE_URL}/v1.0/users/#{id}", query, header)
      raise UserError.new(response.inspect) unless response.code == 200
      body = JSON.parse(response.body)

      #puts "body['@odata.context'] => #{body['@odata.context']}"
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

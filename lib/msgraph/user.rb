module Msgraph
  require 'httpclient'

  class User

    attr_accessor :token

    def initialize(args = {})
      raise UserError.new("Does not exist access token.") unless args.key?(:token)
      @token = args[:token]
    end

    def list
      client = HTTPClient.new
      query = {}
      response = client.get("#{Msgraph::BASE_URL}/v1.0/users/", query, header)
      raise UserError.new("#{response.message}") unless response.code == 200
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

    def get
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

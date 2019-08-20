require 'msgraph/version'
require 'httpclient'
require 'json'

module Msgraph
  class Error < StandardError; end

  TOKEN_BASE_URL = 'https://login.microsoftonline.com'.freeze
  TOKEN_REQUEST_PATH = 'oauth2/v2.0/token'.freeze

  BASE_URL = 'https://graph.microsoft.com'.freeze

  def self.run(args = {})
    client_id = args[:client_id] || args[:application_id]
    client_secret = args[:client_secret]
    tenant_id = args[:tenant_id] || args[:directory_id]

    client = HTTPClient.new
    token_response = client.post(
      "#{TOKEN_BASE_URL}/#{tenant_id}/#{TOKEN_REQUEST_PATH}",
      {
        body: {
          client_id: client_id,
          client_secret: client_secret,
          scope: 'https://graph.microsoft.com/.default',
          grant_type: 'client_credentials',
        },
        'Content-Type' => 'application/json',
        multipart: true,
      }
    )
    raise "#{token_response.message}" unless token_response.code == 200
    token = JSON.parse(token_response.body)['access_token']

    query = {}
    header = { 'Authorization' => "Bearer #{token}",
               'Content-Type' => 'application/json',
             }
    response = client.get("#{BASE_URL}/v1.0/users/", query, header)
    raise "#{response.message}" unless response.code == 200
    body = JSON.parse(response.body)

    # @odata.context
    puts "body['@odata.context'] => #{body['@odata.context']}"
    # value
    users = body['value']
    users.each do |user|
      puts "id => #{user['id']}"
      puts "userPrincipalName => #{user['userPrincipalName']}"
      puts "displayName => #{user['displayName']}"
      puts "givenName => #{user['givenName']}"
      puts "jobTitle => #{user['jobTitle']}"
      puts "mail => #{user['mail']}"
      puts "mobilePhone => #{user['mobilePhone']}"
      puts "businessPhones => #{user['businessPhones'].inspect}"
      puts "officeLocation => #{user['officeLocation']}"
      puts "preferredLanguage => #{user['preferredLanguage']}"
      puts "surname => #{user['surname']}"
    end

  end
end

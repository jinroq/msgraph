require 'msgraph/version'
require 'httpclient'
require 'json'

require 'msgraph/token'

module Msgraph
  class Error < StandardError; end

  BASE_URL = 'https://graph.microsoft.com'.freeze

  def self.run(args = {})
    client_id = args[:client_id] || args[:application_id]
    client_secret = args[:client_secret]
    tenant_id = args[:tenant_id] || args[:directory_id]

    token = Msgraph::Token.new(
      { client_id: client_id,
        client_secret: client_secret,
        tenant_id: tenant_id }
    ).token

    client = HTTPClient.new
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

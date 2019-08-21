require 'msgraph/version'
require 'msgraph/token'
require 'msgraph/user'

require 'httpclient'
require 'json'

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
    ).access_token

    user = Msgraph::User.new(token: token)
    puts "user.list => #{user.list.inspect}"

  end
end

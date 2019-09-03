# frozen_string_literal: true

require 'msgraph/version'
require 'access_token/entity'

require 'msgraph/users'
#require 'msgraph/users/base'
#require 'msgraph/users/user'

module Msgraph
  class Error < StandardError; end

  MSGRAPH_API_ENDPOINT = 'https://graph.microsoft.com'

  def self.run(args = {})
    client_id     = args[:client_id] || args[:application_id]
    client_secret = args[:client_secret]
    tenant_id     = args[:tenant_id] || args[:directory_id]

    token = AccessToken::Entity.new(
      { client_id:     client_id,
        client_secret: client_secret,
        tenant_id:     tenant_id,
      }
    ).access_token

    user = Msgraph::Users::User.new(token: token)
    puts "user.public_methods => #{user.public_methods}.inspect"
#    user = Msgraph::Users::User.new(token: token, select: [:display_name, :user_principal_name])
#    user = Msgraph::Users::User.new(token: token, select: ['displayName', 'userPrincipalName'])
    users = user.list
    puts "users => #{users.inspect}"
#    puts "user.list => #{user.list.inspect}"
#    puts "user.get(id: args[:id]) => #{user.get(id: args[:id]).inspect}"

  end
end

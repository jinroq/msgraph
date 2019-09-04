# frozen_string_literal: true
require 'msgraph/version'
require 'access_token/entity'

require 'msgraph/config'
require 'msgraph/users'

class Msgraph
  def initialize(api_ver: Config::API_VERSION_1)
    @msgraph_api_endpoint = Config::MSGRAPH_API_ENDPOINT
    @api_ver = api_ver
  end

  def user(args = {})
    args.merge!(msgraph_api_endpoint: @msgraph_api_endpoint,
                api_ver: @api_ver)
    Users::User.new(args)
  end

  def debug(args = {})
    client_id     = args[:client_id] || args[:application_id]
    client_secret = args[:client_secret]
    tenant_id     = args[:tenant_id] || args[:directory_id]

    token = AccessToken::Entity.new(
      { client_id:     client_id,
        client_secret: client_secret,
        tenant_id:     tenant_id,
      }
    ).access_token

    msgraph = Msgraph.new
    user = msgraph.user(token: token)
#    user = msgraph.user(token: token, select: [:display_name, :user_principal_name])
#    user = msgraph.user(token: token, select: ['displayName', 'userPrincipalName'])
    users = user.list
    puts "users => #{users.inspect}"
#    puts "user.get(id: args[:id]) => #{user.get(id: args[:id]).inspect}"

  end
end

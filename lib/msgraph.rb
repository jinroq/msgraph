# frozen_string_literal: true
require 'msgraph/version'
require 'access_token/entity'

require 'msgraph/config'
require 'msgraph/users'

class Msgraph
  def initialize(args = {})
    raise "Does not exist ':token' in arguments." unless args.key?(:token)
    @msgraph_api_endpoint = Config::MSGRAPH_API_ENDPOINT
    @api_ver = args[:api_ver] || Config::API_VERSION_1
    @token = args[:token]
  end

  def users(args = {})
    args.merge!(msgraph_api_endpoint: @msgraph_api_endpoint,
                api_ver: @api_ver,
                token: @token)
    Msgraph::Users.new(args)
  end

  def debug
    user_list = self.users.user.list
    puts "user_list => #{user_list.inspect}"
#    users = msgraph.users
#    user = msgraph.user(token: token, select: [:display_name, :user_principal_name])
#    user = msgraph.user(token: token, select: ['displayName', 'userPrincipalName'])
#    users = user.list
#    puts "users => #{users.inspect}"
#    puts "user.get(id: args[:id]) => #{user.get(id: args[:id]).inspect}"

  end
end

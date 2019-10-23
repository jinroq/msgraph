# frozen_string_literal: true
require 'msgraph/version'
require 'access_token/entity'

require 'msgraph/config'
require 'msgraph/users'

class Msgraph
  def initialize(token = nil, options = {})
    raise "Does not exist 'token' argument." unless token
    @token = token
    if options.key?(:api_ver)
      @api_ver = options.delete(:api_ver)
    else
      @api_ver = Config::API_VERSION_1
    end
    @msgraph_api_endpoint = Config::MSGRAPH_API_ENDPOINT
  end

  def users
    Msgraph::Users.new(
      @token,
      @msgraph_api_endpoint,
      @api_ver
    )
  end

  def groups
  end

  def calendars
  end

  def mail
  end

end

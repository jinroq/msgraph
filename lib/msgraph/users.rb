# frozen_string_literal: true
require 'msgraph/base'

class Msgraph::Users < Msgraph::Base
  def initialize(token, endpoint, api_ver, options = {})
    raise Msgraph::UsersError.new("Does not exist 'token' argument.") unless token
    @token = token
    @base_url = "#{endpoint}/#{api_ver}/users/"

    @count   = options[:count]   || false # unsupport
    @expand  = options[:expand]  || []
    @filter  = options[:filter]  || []
    @format  = options[:format]  || []
    @orderby = options[:orderby] || []
    @search  = options[:search]  || []
    @select  = options[:select]  || []
    @skip    = options[:skip]    || []

    @skip_token = options[:skip_token] || []

  end

  # GET /users
  #   Retrieve a list of users.
  # GET /users/{id | userPrincipalName}
  #   Retrieve the properties and relationships of user.
  def get(id = nil, options = {})
    id.nil? ? _list(options) : _get(id, options)
  end

  # GET /users
  #   Retrieve a list of users.
  def list(options = {})
    get(nil, options)
  end

  # POST /users
  #  Create a new user.
  def create(options = {})
  end

  # PATCH /users/{id | userPrincipalName}
  #   Update the properties of a user.
  def update(id, options = {})
  end

  # DELETE /users/{id | userPrincipalName}
  #   Delete user.
  def delete(id, options = {})
  end

  # GET /users/delta
  #   Get newly created, updated, or deleted users without having to perform a full read
  #   of the entire user collection.
  def delta(options = {})
  end

  private

  # GET /users
  def _list(options)
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
                         raise Msgraph::UsersError.new("'#{key_name}' is invalid value.")
                       end
                     }.join(',') })
    end

    client = HTTPClient.new
    response = client.get("#{@base_url}", query, _header)
    case response.code
    when 200
      body = JSON.parse(response.body)
    else
      raise Msgraph::Users::UserError.new(response.inspect)
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

  # GET /users/{id | userPrincipalName}
  def _get(id, options)
    client = HTTPClient.new
    query = {}
    response = client.get("#{@base_url}/#{id}", query, _header)
    case response.code
    when 200
      body = JSON.parse(response.body)
    when 202
      # when the request has been processed successfully
      # but the server requires more time to complete related background operations.
    else
      raise Msgraph::UsersError.new(response.inspect)
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

  def _header
    { 'Authorization' => "Bearer #{@token}",
      'Content-Type'  => 'application/json',
    }
  end

  def _body
  end

end

class Msgraph::UsersError < StandardError; end

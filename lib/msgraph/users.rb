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
    query = {}

    raise Msgraph::UsersError.new('Required parameter `password_profile`') if options[:password_profile].nil?
    password_profile = {
      'forceChangePasswordNextSignIn'        => options[:password_profile][:force_change_password_next_sign_in] || false,
      'forceChangePasswordNextSignInWithMfa' => options[:password_profile][:force_change_password_next_sign_in_with_mfa] || false,
      'password'                             => options[:password_profile][:password],
    }

    raise Msgraph::UsersError.new('Required parameter `body`') if options.keys.size == 0
    request_body = {
      'accountEnabled'        => options[:account_enabled] || true,
      'displayName'           => options[:display_name],
      'onPremisesImmutableId' => options[:on_premises_immutable_id],
      'mailNickname'          => options[:mail_nick_name],
      'passwordProfile'       => password_profile,
      'userPrincipalName'     => options[:user_principal_name],
    }

    client = HTTPClient.new
    response = client.post("#{@base_url}",
                           query:  query,
                           body:   request_body.to_json,
                           header: _header
                          )

    case response.code
    when 201
      response_body = JSON.parse(response.body)
    else
      raise Msgraph::UsersError.new(response.inspect)
    end

    user = response_body['value']

    return { id:                  response_body['id'],
             user_principal_name: response_body['userPrincipalName'],
             display_name:        response_body['displayName'],
             given_name:          response_body['givenName'],
             job_title:           response_body['jobTitle'],
             mail:                response_body['mail'],
             mobile_phone:        response_body['mobilePhone'],
             business_phones:     response_body['businessPhones'].inspect,
             office_location:     response_body['officeLocation'],
             preferred_language:  response_body['preferredLanguage'],
             surname:             response_body['surname'],
    }
  end

  # PATCH /users/{id | userPrincipalName}
  #   Update the properties of a user.
  def update(id, options = {})
    raise Msgraph::UsersError.new('Required argument `id`.') if id.nil?

    query = {}
    request_body = {}
    raise Msgraph::UsersError.new('Required parameter `password_profile`') if options.keys.size == 0
    unless options[:birthday].nil?
      birthday = DateTime.parse(options[:birthday])
      request_body['birthday'] = birthday
    end

    # required
    request_body['displayName'] = options[:display_name] unless options[:display_name].nil?

    request_body['aboutMe'] = options[:about_me] unless options[:about_me].nil?
    request_body['accountEnabled'] = options[:account_enabled] unless options[:account_enabled].nil?
    request_body['businessPhones'] = options[:business_phones] unless options[:business_phones].nil? && options[:business_phones].size > 0

    client = HTTPClient.new
    response = client.post("#{@base_url}",
                           query:  query,
                           body:   request_body.to_json,
                           header: _header
                          )

    case response.code
    when 204
      # do nothing
    else
      raise Msgraph::UsersError.new(response.inspect)
    end

    return true
  end

  # DELETE /users/{id | userPrincipalName}
  #   Delete user.
  def delete(id, options = {})
    raise Msgraph::UsersError.new('Required argument `id`.') if id.nil?
    query = {}
    header = { 'Authorization' => "Bearer #{@token}" }

    client = HTTPClient.new
    response = client.post("#{@base_url}/{id}", query: query, header: header)

    case response.code
    when 204
      # do nothing
    else
      raise Msgraph::UsersError.new(response.inspect)
    end

    return true
  end

  # GET /users/delta
  #   Get newly created, updated, or deleted users without having to perform a full read
  #   of the entire user collection.
  def delta(options = {})
  end

  private

  # GET /users
  def _list(options)
    query = _query(options)

    client = HTTPClient.new
    response = client.get("#{@base_url}", query: query, header: _header)
    case response.code
    when 200
      body = JSON.parse(response.body)
    else
      raise Msgraph::UsersError.new(response.inspect)
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
    query = _query(options)
    response = client.get("#{@base_url}/#{id}", query: query, header: _header)
    case response.code
    when 200
      body = JSON.parse(response.body)
    when 202
      # when the request has been processed successfully
      # but the server requires more time to complete related background operations.

      # not implement
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

  def _query(odata_params = {})
    query = {}

    # $select
    if odata_params.has_key?(:select)
      query.merge!({ '$select' => odata_params[:select].map { |key_name|
                       if key_name.is_a?(Symbol)
                         self.class.snake_case_to_camel_case(key_name.to_s)
                       elsif key_name.is_a?(String)
                         key_name
                       else
                         raise Msgraph::UsersError.new("'#{key_name}' is invalid value.")
                       end
                     }.join(',') })
    end

    return query
  end

end

class Msgraph::UsersError < StandardError; end

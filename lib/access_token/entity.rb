# frozen_string_literal: true

module AccessToken
  require 'httpclient'
  require 'json'

  class Entity
    BASE_URL           = 'https://login.microsoftonline.com'
    OAUTH2_TOKEN_PATH  = 'oauth2/v2.0/token'
    DEFAULT_SCOPE      = 'https://graph.microsoft.com/.default'
    DEFAULT_GRANT_TYPE = 'client_credentials'

    attr_accessor :client_id, :client_secret, :tenant_id
    attr_accessor :grant_type

    def initialize(args = {})
      raise EntityError.new("Does not exist Client ID or Application ID") unless args.key?(:client_id) || args.key?(:application_id)
      @client_id = args[:client_id] || args[:application_id]

      raise EntityError.new("Does not exist ClientSecret") unless args.key?(:client_secret)
      @client_secret = args[:client_secret]

      raise EntityError.new("Does not exist Tenant ID or Directory ID") unless args.key?(:tenant_id) || args.key?(:directory_id)
      @tenant_id = args[:tenant_id] || args[:directory_id]

      @grant_type = args[:grant_type]
    end

    def access_token
      body['access_token']
    end

    def token_type
      body['token_type']
    end

    def expires_in
      body['expires_in']
    end

    def ext_expires_in
      body['ext_expires_in']
    end

    private

    def body
      client = HTTPClient.new
      response = client.post(
        "#{BASE_URL}/#{tenant_id}/#{OAUTH2_TOKEN_PATH}",
        {
          body: {
            client_id: client_id,
            client_secret: client_secret,
            scope: DEFAULT_SCOPE,
            grant_type: grant_type || DEFAULT_GRANT_TYPE,
          },
          'Content-Type' => 'application/json',
          multipart: true,
        }
      )
      raise EntityError.new(response.inspect) unless response.code == 200

      return JSON.parse(response.body)
    end

  end

  class EntityError < StandardError; end
end

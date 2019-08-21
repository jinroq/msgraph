module Msgraph
  require 'httpclient'

  class Token
    BASE_URL     = 'https://login.microsoftonline.com'.freeze
    REQUEST_PATH = 'oauth2/v2.0/token'.freeze

    attr_accessor :client_id, :client_secret, :tenant_id

    def initialize(args = {})
      raise TokenError.new("Does not exist Client ID or Application ID") unless args.key?(:client_id) || args.key?(:application_id)
      client_id = args[:client_id] || args[:application_id]

      raise TokenError.new("Does not exist ClientSecret") unless args.key?(:client_secret)
      client_secret = args[:client_secret]

      raise TokenError.new("Does not exist Tenant ID or Directory ID") unless args.key?(:tenant_id) || args.key?(:directory_id)
      tenant_id = args[:tenant_id] || args[:directory_id]
    end

    def token
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
        "#{BASE_URL}/#{tenant_id}/#{REQUEST_PATH}",
        {
          body: {
            client_id: client_id,
            client_secret: client_secret,
            scope: "#{Msgraph::BASE_URL}/.default",
            grant_type: 'client_credentials',
          },
          'Content-Type' => 'application/json',
          multipart: true,
        }
      )
      raise TokenError.new("#{token_response.message}") unless response.code == 200

      return JSON.parse(response.body)
    end

  end

  class TokenError < StandardError; end
end

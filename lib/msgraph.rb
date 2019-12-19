# frozen_string_literal: true
require 'msgraph/version'
require 'access_token/entity'

require 'msgraph/config'
require 'msgraph/odata'
require 'msgraph/base'
require 'msgraph/base_entity'
require 'msgraph/class_builder'

class Msgraph

  def initialize(token = nil, **args)
    raise "Does not exist 'token' argument." unless token
    api_ver = args[:api_ver] || Config::API_VERSION_1
    context_url = "#{Config::MSGRAPH_API_ENDPOINT}/#{api_ver}/"
    metadata_filepath = args[:metadata_filepath]

    @dispatcher = Odata::Dispatcher.new(
      token: token,
      context_url: context_url,
      metadata_filepath: metadata_filepath
    )

    # 
    @association_collections = {}

    @class_builder = MicrosoftGraph::ClassBuilder.new
    unless class_loaded?
      @class_builder.load(@dispatcher)
    end
  end

  def class_loaded?
    @class_builder.loaded?
  end

end

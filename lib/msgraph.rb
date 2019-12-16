# frozen_string_literal: true
require 'msgraph/version'
require 'access_token/entity'

require 'msgraph/config'
require 'msgraph/odata'
require 'msgraph/class_builder'

class Msgraph
  attr_reader :dispatcher

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

    builder = MicrosoftGraph::ClassBuilder.new
    unless builder.loaded?
      MicrosoftGraph::ClassBuilder.load!(@dispatcher)
    end
  end

end

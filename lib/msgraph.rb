# frozen_string_literal: true
require 'msgraph/version'
require 'access_token/entity'

require 'msgraph/config'
require 'msgraph/errors'
require 'msgraph/utils'
require 'msgraph/odata'
require 'msgraph/base'
require 'msgraph/base_entity'
require 'msgraph/base_entity'
require 'msgraph/collection'
require 'msgraph/collection_association'

require 'msgraph/class_builder'

class Msgraph
  attr_reader :service

  def initialize(token = nil, **args)
    raise "You MUST set 'token' in the argument." unless token
    api_ver = args[:api_ver] || Config::API_VERSION_1
    context_url = "#{Config::MSGRAPH_API_ENDPOINT}/#{api_ver}/"
    metadata_filepath = args[:metadata_filepath]

    @service = Odata::Dispatcher.new(
      token: token,
      context_url: context_url,
      metadata_filepath: metadata_filepath,
    )

    # 
    @association_collections = {}

    @class_builder = ClassBuilder.new
    unless class_loaded?
      @class_builder.load(service)
    end
  end

  def class_loaded?
    @class_builder.loaded?
  end

  # 
  def containing_navigation_property(type_name)
    navigation_properties.values.find do |navigation_property|
      navigation_property.collection? && navigation_property.type.name == "Collection(#{type_name})"
    end
  end

  def path; end
end

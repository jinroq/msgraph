module Msgraph
  module User
    require 'httpclient'

    class Base
      attr_accessor :token, :select

      PROPERTIES = [
        :id,
        :business_phones,
        :display_name,
        :given_name,
        :job_title,
        :mail,
        :mobile_phone,
        :office_location,
        :preferred_language,
        :surname,
        :user_principal_name
      ]
    end

    class BaseError < StandardError; end

  end
end

# frozen_string_literal: true
class Msgraph::Users
  def initialize(args = {})
    require 'msgraph/users/base'
    require 'msgraph/users/user'

    @user = Msgraph::Users::User.new(args)
  end

  def user
    @user
  end
end

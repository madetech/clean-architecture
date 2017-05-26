class UserRegistrationController < ApplicationController
  def new
    @user = UserRegistration.new
  end

  def create
    request = Users::UseCase::RegisterUser::Request.new(*user_params)
    response = Users::UseCase::RegisterUser.new.register(request)
    @user = UserRegistration.new(request, response)
  end

  private

  def user_params
    params.require(:user).values_at(:email, :name, :password)
  end

  class UserRegistration
    include ActiveModel::Model

    attr_reader *Users::UseCase::RegisterUser::Request.members
    attr_reader *Users::UseCase::RegisterUser::Response.members

    def initialize(request = nil, response = nil)
      @email = request.try(:email)
      @name = request.try(:name)
      @password = request.try(:password)
      @errors = response.try(:errors)
    end
  end
end

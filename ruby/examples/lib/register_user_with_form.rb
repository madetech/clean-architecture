require 'active_model'

class RegisterUserWithForm
  Request = Struct.new(:email, :name, :password)
  Response = Struct.new(:form)

  class Response::Form
    include ActiveModel::Model

    attr_reader *Request.members
    attr_reader :errors

    def initialize(email:, name:, password:, errors:)
      @email = email
      @name = name
      @password = password
      @errors = errors
    end
  end

  attr_reader :gateway

  def initialize(gateway: Gateway.new)
    @gateway = gateway
  end

  def register(request)
    errors = gateway.create_user(request.to_h)
    form = Response::Form.new(request.to_h.merge(errors: errors))
    Response.new(form)
  end

  class Gateway
    def create_user(attributes)
      order = Spree::User.create(attributes)
      order.errors
    end
  end
end

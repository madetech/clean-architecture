class RegisterUser
  Request = Struct.new(:email, :name, :password)
  Response = Struct.new(:errors)

  attr_reader :gateway

  def initialize(gateway: Gateway.new)
    @gateway = gateway
  end

  def register(request)
    errors = gateway.create_user(request.to_h)
    Response.new(errors)
  end

  class Gateway
    def create_user(attributes)
      order = Spree::User.create(attributes)
      order.errors
    end
  end
end

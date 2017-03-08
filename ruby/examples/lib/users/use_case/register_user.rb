module Users
  module UseCase
    class RegisterUser
      Request = Struct.new(:email, :name, :password)
      Response = Struct.new(:errors)

      attr_reader :gateway

      def initialize(gateway: Gateway::User.new)
        @gateway = gateway
      end

      def register(request)
        errors = gateway.create_user(request.to_h)
        Response.new(errors)
      end
    end
  end
end

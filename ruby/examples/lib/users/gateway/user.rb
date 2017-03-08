module Users
  module Gateway
    class User
      def create_user(attributes)
        order = Spree::User.create(attributes)
        order.errors
      end
    end
  end
end

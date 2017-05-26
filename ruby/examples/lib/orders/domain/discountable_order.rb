module Orders
  module Domain
    class DiscountableOrder < Struct.new(:discount)
      def has_discount?
        discount > 0
      end
    end
  end
end

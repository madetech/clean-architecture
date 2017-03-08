module Orders
  module Gateway
    class Order
      def find_order_by_id(id)
        order = Spree::Order.find(id)
        Domain::DiscountableOrder.new(order.discount)
      end

      def save_order_discount(id, order)
        Spree::Order.find(id).update!(discount: order.discount)
      end
    end
  end
end

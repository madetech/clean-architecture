class ApplyOrderDiscount
  Request = Struct.new(:id)
  Response = Struct.new(:discount, :has_discount?)

  attr_reader :gateway

  def initialize(gateway: Gateway.new)
    @gateway = gateway
  end

  def apply(request)
    order = gateway.find_order_by_id(request.id)

    unless order.has_discount?
      order.discount = discount_amount
      gateway.save_order_discount(request.id, order)
    end

    Response.new(order.discount, order.has_discount?)
  end

  private

  def discount_amount
    10
  end

  class DiscountableOrder < Struct.new(:discount)
    def has_discount?
      discount > 0
    end
  end

  class Gateway
    def find_order_by_id(id)
      order = Spree::Order.find(id)
      DiscountableOrder.new(order.discount)
    end

    def save_order_discount(id, order)
      Spree::Order.find(id).update!(discount: order.discount)
    end
  end
end

# Fake Gateways

When building out Acceptance Tests, it is useful to use Fake [test doubles](https://learn.madetech.com/core-skills/tdd/test-doubles.html) to stand in for real gateways.

This gives you the ability to explore the domain, and the associated business rules with the customer while building real code.

Once you understand the domain, you can then make an informed decision about technology choices for persistence.

## Simplistic Gateway

Using an array as a backing store, a lot of early gateways might follow this pattern. 

```ruby
class InMemoryOrder
  def initialize
    @orders = []
  end
  
  def find_by(id)
    @orders[id]
  end

  def all
    @orders
  end
  
  def save(order)
    @orders << order
    @orders.length - 1
  end
end
```

## As part of an acceptance test

```ruby
describe 'orders' do
  let(:order_gateway) { InMemoryOrder.new }
  let(:view_order) { Customer::UseCase::ViewOrder.new(order_gateway: order_gateway) }
  let(:place_order) { Customer::UseCase::PlaceOrder.new(order_gateway: order_gateway) }
  
  context 'given an order has been placed' do
    let!(:place_order_response) do
      place_order.execute(
        customer_id: 3,
        shipping_address_id: 1,
        billing_address_id: 2,
        items: [
          {sku: '19283', quantity: 2}
        ]
      )
    end
    
    it 'has placed the order that is viewable' do
      response = view_order.execute(order_id: place_order_response[:order_id])
      
      expect(response[:items]).to(
        eq(
          [ {sku: '19283', quantity: 2, price: { amount: '10.00', currency: 'GBP' }} ]
        )
      )
      expect(response[:total]).to eq({amount: '10.00', currency: 'GBP'})
      expect(response[:shipping_address_id]).to eq(1)
      expect(response[:billing_address_id]).to eq(2)
      expect(response[:customer_id]).to eq(3)
    end
  end
end
```

## An outer loop, made simple by Fakes

Acceptance Test Driven Development creates an outer loop around your TDD discipline.

1. Write a failing acceptance test
2. Write the next simplest failing unit test
3. Write the simplest production code to make the unit test pass
4. Refactor
5. Does the acceptance test pass? If *yes* goto 1, *else* goto 2

Using a Fake test double to stand in for your persistence layer, enables you to exploring both the _domain_ without exploring the _persistence layer_ at the same time. 


---
title: Writing Fake Gateways
---

# Fake Gateways

When you write acceptance tests, use a Fake [test double](https://learn.madetech.com/core-skills/tdd/test-doubles.html) in place of a real Gateway.

A Fake lets you explore the domain and the business rules with the customer while you write real code.

Choose your persistence technology after you understand the domain.

## Simplistic Gateway

An early Gateway often uses an array as the store:

```ruby
class InMemoryOrderGateway
  def initialize
    @orders = []
  end
  
  def find_by_id(id)
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

The Fake exposes the same interface as the real Gateway. The Fake accepts an `Order` [Domain](../../domain.md) object to save, and returns `Order` objects when the Use Case reads. The Fake stores the Domain objects it receives, so the Fake needs no mapping code. That is why a Fake is cheap to write.

The Fake must not expose a *different* interface to the Use Case. A Fake that takes `customer_id:` and `items:` instead of an `Order` forces you to change every Use Case when you swap in a [real Gateway](./gateway-101.md).

## As part of an acceptance test

```ruby
describe 'orders' do
  let(:order_gateway) { InMemoryOrderGateway.new }
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

Acceptance Test Driven Development puts an outer loop around your TDD discipline.

1. Write a failing acceptance test
2. Write the next simplest failing unit test
3. Write the simplest production code that makes the unit test pass
4. Refactor
5. Run the acceptance test. If the acceptance test passes, go to step 1. If the acceptance test fails, go to step 2.

A Fake test double stands in for your persistence layer. The Fake lets you explore the _domain_ without exploring the _persistence layer_ at the same time.

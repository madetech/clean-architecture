---
title: Your first Delivery Mechanism
---

# Your first Delivery Mechanism

A delivery mechanism is whatever sits between the outside world and your use cases. It receives an external event — an HTTP request, a CLI command, a message off a queue — and translates it into a use case call.

## The job of a delivery mechanism

1. Translate the incoming request into use case input
2. Call the use case
3. Translate the use case response into an output

That is all. A delivery mechanism contains no business logic and has no knowledge of gateways.

## A simple example

```ruby
post '/orders' do
  response = create_order.execute(
    customer_id: params[:customer_id].to_i,
    items: params[:items]
  )

  json(order_id: response[:order_id])
end
```

The route knows about HTTP (params, JSON response). It does not know about `Order`, `OrderGateway`, or how `CreateOrder` works internally.

## Extracting a controller class

For anything beyond a trivial route, extract a controller class. This makes the delivery mechanism testable independently of the HTTP framework.

```ruby
module Delivery
  class CreateOrderController
    def initialize(create_order:)
      @create_order = create_order
    end

    def execute(params, response)
      result = @create_order.execute(
        customer_id: params[:customer_id].to_i,
        items: params[:items]
      )
      response.status = 201
      response.body = { order_id: result[:order_id] }.to_json
    end
  end
end
```

The controller has `create_order` injected as a collaborator, following the [constructors for collaborators](./constructors-for-collaborators.md) pattern. It is entirely unaware of how the use case is wired up or what gateway it uses.

The Sinatra route becomes thin glue:

```ruby
post '/orders' do
  controller = Delivery::CreateOrderController.new(
    create_order: get_use_case(:create_order)
  )
  controller.execute(params, response)
end
```

## Testing a delivery mechanism

Because the controller accepts its use case as a dependency, you can test it in isolation by injecting a Stub:

```ruby
describe Delivery::CreateOrderController do
  let(:create_order) { double('create_order', execute: { order_id: 42 }) }
  let(:controller) { described_class.new(create_order: create_order) }

  it 'sets a 201 status' do
    response = double('response').as_null_object
    controller.execute({ customer_id: '1', items: [] }, response)
    expect(response).to have_received(:status=).with(201)
  end
end
```

No HTTP stack, no database, no real use case. Just the translation logic under test.

## What must not live here

- **Business logic**: if an order over £100 gets free shipping, that belongs in a use case or domain object
- **Gateway knowledge**: the controller should not know what database you are using or how to construct one
- **Authorisation rules**: covered separately in [Authorisation](../../intermediate/authorisation.md)

## From the trenches

The most common mistake is letting the delivery mechanism grow. It starts with a small conditional — "if the user is an admin, show a slightly different response" — and within a few months the controller is 200 lines and contains half your business rules.

Keep delivery mechanisms so thin that there is almost nothing left to test. If you find yourself writing complex setup for a controller test, the logic probably belongs in a use case.

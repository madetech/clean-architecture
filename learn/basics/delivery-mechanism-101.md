---
title: Your first Delivery Mechanism
---

# Your first Delivery Mechanism

A Delivery Mechanism sits between the outside world and your Use Cases. A Delivery Mechanism receives an external event, such as an HTTP request, a CLI command, or a message from a queue, and turns that event into a Use Case call.

## The job of a Delivery Mechanism

1. Translate the incoming request into Use Case input
2. Call the Use Case
3. Translate the Use Case response into an output

A Delivery Mechanism does nothing else. A Delivery Mechanism holds no business logic, and knows nothing about Gateways.

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

The route knows about HTTP, which means the params and the JSON response. The route does not know about `Order`, about `OrderGateway`, or about how `CreateOrder` works inside.

## Extracting a controller class

Extract a controller class for any route that does more than the example above. A controller class makes the Delivery Mechanism testable without the HTTP framework.

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

The controller receives `create_order` as a collaborator, which follows the [constructors for collaborators](./constructors-for-collaborators.md) pattern. The controller does not know how the Use Case is wired up, and does not know which Gateway the Use Case uses.

The Sinatra route becomes three lines:

```ruby
post '/orders' do
  controller = Delivery::CreateOrderController.new(
    create_order: get_use_case(:create_order)
  )
  controller.execute(params, response)
end
```

## Testing a Delivery Mechanism

The controller accepts its Use Case as a dependency, so you test the controller in isolation with a Stub:

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

The test needs no HTTP stack, no database and no real Use Case. The test covers the translation code only.

## What must not go here

- **Business logic**: a rule such as free shipping on an order over £100 belongs in a Use Case or in a Domain object
- **Gateway knowledge**: the controller must not know which database you use, and must not construct a Gateway
- **Authorisation rules**: see [Authorisation](../intermediate/authorisation.md)

## In practice

The most common mistake is to let the Delivery Mechanism grow. The growth starts with one small conditional, such as a different response for an administrator. A few months later the controller holds 200 lines and half of your business rules.

Keep each Delivery Mechanism thin enough that almost nothing is left to test. Complex setup in a controller test tells you that the logic belongs in a Use Case.

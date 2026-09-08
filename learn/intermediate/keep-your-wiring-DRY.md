---
title: Keep your wiring DRY
---

# Keep your wiring DRY

Once you have several Use Cases and several real Gateways, a pattern appears: every Delivery Mechanism constructs the same dependencies again and again.

## The problem

```ruby
post '/orders' do
  gateway = SequelOrderGateway.new(DB)
  notifier = EmailNotifier.new(ENV['SMTP_HOST'])
  result = PlaceOrder.new(order_gateway: gateway, notifier: notifier).execute(params)
  json(result)
end

get '/orders' do
  gateway = SequelOrderGateway.new(DB)
  result = ListOrders.new(order_gateway: gateway).execute
  json(result)
end

delete '/orders/:id' do
  gateway = SequelOrderGateway.new(DB)
  result = CancelOrder.new(order_gateway: gateway).execute(order_id: params[:id].to_i)
  json(result)
end
```

Every route knows about `SequelOrderGateway`, `DB` and `EmailNotifier`, and knows how to construct all three. Change one constructor argument, and you change every route. Add a dependency to `PlaceOrder`, and you must find every place that constructs `PlaceOrder`.

This is fragility, and it breaks the dependency inversion principle. A Delivery Mechanism must not know about a Gateway implementation.

## A dependency factory

Move all construction into one class:

```ruby
class Dependencies
  def initialize(db:)
    @db = db
  end

  def get_use_case(name)
    case name
    when :place_order
      PlaceOrder.new(order_gateway: order_gateway, notifier: notifier)
    when :list_orders
      ListOrders.new(order_gateway: order_gateway)
    when :cancel_order
      CancelOrder.new(order_gateway: order_gateway)
    end
  end

  private

  def order_gateway
    @order_gateway ||= SequelOrderGateway.new(@db)
  end

  def notifier
    @notifier ||= EmailNotifier.new(ENV['SMTP_HOST'])
  end
end
```

Each Delivery Mechanism then knows nothing about any Gateway:

```ruby
post '/orders' do
  json(dependencies.get_use_case(:place_order).execute(params))
end

get '/orders' do
  json(dependencies.get_use_case(:list_orders).execute)
end

delete '/orders/:id' do
  json(dependencies.get_use_case(:cancel_order).execute(order_id: params[:id].to_i))
end
```

The [acceptance tests](../basics/start-with-acceptance.md) already show this pattern: `system.get_use_case(:create_light)`. The dependency factory is the class that provides `get_use_case`.

## The composition root

The composition root is the place where you construct the factory and wire everything together. In a Sinatra application the composition root is the application file, above the routes:

```ruby
def dependencies
  @dependencies ||= Dependencies.new(db: DB)
end
```

Exactly one place in your code base knows about `SequelOrderGateway` and `DB`. Nothing else holds that knowledge.

## Swapping implementations for tests

All construction is in the factory, so you write a test factory that injects Fakes in place of the real Gateways. No Delivery Mechanism changes:

```ruby
class TestDependencies
  def get_use_case(name)
    case name
    when :place_order
      PlaceOrder.new(order_gateway: InMemoryOrderGateway.new, notifier: FakeNotifier.new)
    when :list_orders
      ListOrders.new(order_gateway: InMemoryOrderGateway.new)
    end
  end
end
```

Your acceptance tests use `TestDependencies`. Your Production application uses `Dependencies`. The Use Cases and the Delivery Mechanisms need no change.

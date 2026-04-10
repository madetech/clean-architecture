---
title: Keep your wiring DRY
---

# Keep your wiring DRY

Once you have a handful of use cases and real gateways, you will notice a pattern: every delivery mechanism constructs the same dependencies over and over.

## The smell

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

Every route knows about `SequelOrderGateway`, `DB`, `EmailNotifier`, and how to construct them. Change a constructor argument and you touch every route. Add a new dependency to `PlaceOrder` and you have to find every place it is constructed.

This is fragility — and it violates the Dependency Inversion Principle. Delivery mechanisms should not know about gateway implementations.

## A dependency factory

Extract all construction into one place:

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

Delivery mechanisms become unaware of gateways entirely:

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

This is the pattern already visible in the [acceptance tests](../basics/start-with-acceptance.md): `system.get_use_case(:create_light)`. The dependency factory is what makes that work.

## The composition root

The place where you construct the factory and wire everything together is called the composition root. In a Sinatra app this is typically the application file, before any routes are defined:

```ruby
def dependencies
  @dependencies ||= Dependencies.new(db: DB)
end
```

There is exactly one place in your codebase that knows about `SequelOrderGateway` and `DB`. Everything else is shielded from that knowledge.

## Swapping implementations for tests

Because all construction lives in the factory, you can create a test variant that injects fakes instead of real gateways — without changing any delivery mechanism code:

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

Your acceptance tests use `TestDependencies`. Your production app uses `Dependencies`. The use cases and delivery mechanisms never change.

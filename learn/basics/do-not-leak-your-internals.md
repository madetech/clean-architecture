---
title: Don't leak your internals!
---

# Don't leak your internals!

Use cases sit at the boundary of your application. Anything that crosses that boundary — both coming in and going out — should be a plain data structure.

This rule is easy to follow for inputs (a hash of parameters). It is tempting to break for outputs — especially when you have a domain object sitting right there.

## What leaking looks like

A use case that returns a domain object:

```ruby
class PlaceOrder
  def initialize(order_gateway:)
    @order_gateway = order_gateway
  end

  def execute(customer_id:, items:)
    order = Order.new(customer_id: customer_id, items: items)
    @order_gateway.save(order)
    order  # leaking a domain object
  end
end
```

The caller — a controller, a test, another use case — now has a direct dependency on `Order`. That means:

- It can call any method on `Order`, including ones you didn't intend to expose
- Any change to `Order`'s interface (method names, return types) can break callers silently
- Your acceptance tests will start to know about internals they have no business knowing about

## What not leaking looks like

Return a plain hash instead:

```ruby
class PlaceOrder
  def initialize(order_gateway:)
    @order_gateway = order_gateway
  end

  def execute(customer_id:, items:)
    order = Order.new(customer_id: customer_id, items: items)
    id = @order_gateway.save(order)
    { order_id: id }
  end
end
```

The caller gets back only what they need. The fact that an `Order` domain object exists is a private detail.

## Why this matters

The use case boundary is a seam. Everything on the outside of that seam — delivery mechanisms, acceptance tests, other use cases — should be able to change independently of everything on the inside.

When a domain object escapes, that seam is broken. You lose the ability to refactor your domain freely.

## From the trenches

A common scenario: you refactor `Order` to rename `customer_id` to `customer`. You grep for `customer_id` to find all usages. You find it in three acceptance tests, two controllers, and an email formatter — none of which should know anything about `Order`.

Had the use cases returned plain hashes, the change would have been contained inside the use case and gateway. The callers would have been untouched.

The cost of the refactor just went from one file to six. Every additional file that needs to change is another opportunity to introduce a defect — a missed reference, a wrong field name, a test that was updated incorrectly and now passes for the wrong reason. The more code that moves, the more likely something breaks.

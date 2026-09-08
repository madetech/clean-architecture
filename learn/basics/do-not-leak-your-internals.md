---
title: Do not leak your internals
---

# Do not leak your internals

A Use Case sits at the boundary of your application. Everything that crosses that boundary, inward and outward, must be a plain data structure.

The rule is easy to follow for input, because input is a hash of parameters. The rule is tempting to break for output, because the Use Case already holds a Domain object.

## What leaking looks like

Here is a Use Case that returns a Domain object:

```ruby
class PlaceOrder
  def initialize(order_gateway:)
    @order_gateway = order_gateway
  end

  def execute(customer_id:, items:)
    order = Order.new(customer_id: customer_id, items: items)
    @order_gateway.save(order)
    order  # this leaks a Domain object
  end
end
```

The caller is a controller, a test, or another Use Case. That caller now depends on `Order` directly. Three problems follow:

- The caller can call any method on `Order`, including a method you did not intend to expose
- Any change to the interface of `Order`, such as a method name or a return type, can break the caller without a warning
- Your acceptance tests start to know about internals that an acceptance test must not see

## What not leaking looks like

Return a plain hash:

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

The caller receives only the data the caller needs. The `Order` Domain object stays a private detail.

## Why this matters

The Use Case boundary is a seam. Everything outside that seam, meaning the Delivery Mechanisms, the acceptance tests and the other Use Cases, changes independently of everything inside the seam.

A Domain object that escapes breaks the seam. You then lose the ability to refactor your domain freely.

## In practice

Consider this change: you rename `customer_id` to `customer` on `Order`. You search for `customer_id` to find every use. You find `customer_id` in three acceptance tests, two controllers and an email formatter. None of those files should know anything about `Order`.

If the Use Cases had returned a plain hash, the change would stay inside the Use Case and the Gateway. The callers would need no change.

The rename now touches six files instead of one. Each extra file that changes adds a chance of a defect: a missed reference, a wrong field name, or a test that you update wrongly and that then passes for the wrong reason. More code that moves means more chance of a failure.

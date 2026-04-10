# Extend Use Case behaviour with Domain objects

When you start building a Clean Architecture system, the advice is to keep your domain objects simple — just data, minimal behaviour. Let the use cases carry the logic. This is deliberate.

As [domain.md](../../domain.md) puts it: _it is cheaper to specialise Use Cases, resulting in an anemic domain model, then evolve the systems towards generalisations once patterns emerge._

This guide is about recognising when those patterns have emerged, and moving logic into the domain.

## Starting point: logic in the use case

Early on, a pricing rule lives in the use case that needs it:

```ruby
class PlaceOrder
  def execute(customer_id:, items:)
    subtotal = items.sum { |item| item[:price] * item[:quantity] }
    total = items.sum { |i| i[:quantity] } >= 10 ? subtotal * 0.9 : subtotal

    id = @order_gateway.save(customer_id: customer_id, items: items, total: total)
    { order_id: id }
  end
end
```

This is fine. One use case, one place the rule lives.

## The signal: duplication across use cases

A second use case needs the same rule:

```ruby
class UpdateOrder
  def execute(order_id:, items:)
    subtotal = items.sum { |item| item[:price] * item[:quantity] }
    total = items.sum { |i| i[:quantity] } >= 10 ? subtotal * 0.9 : subtotal

    @order_gateway.update(order_id: order_id, items: items, total: total)
    { order_id: order_id }
  end
end
```

The bulk discount rule is now in two places. When the discount threshold changes from 10 to 20, both use cases need updating. Miss one, and the system is inconsistent.

This is the signal: a rule that must be valid for multiple use cases belongs in the domain.

## Moving logic into a domain object

```ruby
class OrderPricing
  BULK_THRESHOLD = 10
  BULK_DISCOUNT  = 0.9

  def initialize(items)
    @items = items
  end

  def total
    bulk? ? subtotal * BULK_DISCOUNT : subtotal
  end

  private

  def subtotal
    @items.sum { |item| item[:price] * item[:quantity] }
  end

  def bulk?
    @items.sum { |i| i[:quantity] } >= BULK_THRESHOLD
  end
end
```

Both use cases simplify to:

```ruby
class PlaceOrder
  def execute(customer_id:, items:)
    total = OrderPricing.new(items).total
    id = @order_gateway.save(customer_id: customer_id, items: items, total: total)
    { order_id: id }
  end
end

class UpdateOrder
  def execute(order_id:, items:)
    total = OrderPricing.new(items).total
    @order_gateway.update(order_id: order_id, items: items, total: total)
    { order_id: order_id }
  end
end
```

The rule has one home. Use cases become orchestrators — they coordinate the flow, but the knowledge belongs to the domain.

## Testing the domain object independently

Domain objects have no gateways and no use case dependencies. They are the easiest things in your system to test:

```ruby
describe OrderPricing do
  context 'with fewer than 10 items' do
    it 'returns the full subtotal' do
      items = [{ price: 10, quantity: 9 }]
      expect(OrderPricing.new(items).total).to eq(90)
    end
  end

  context 'with 10 or more items' do
    it 'applies the bulk discount' do
      items = [{ price: 10, quantity: 10 }]
      expect(OrderPricing.new(items).total).to eq(90)
    end
  end
end
```

No setup, no doubles, no gateways. Fast, isolated, and focused on the rule itself.

## The guiding question

Before moving logic into the domain, ask: _must this rule hold for all use cases across the system?_

If the rule is specific to one use case, it belongs in the use case. If it is a constraint on the domain itself — something that would be wrong regardless of which use case triggered it — it belongs in the domain.

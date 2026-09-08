---
title: Extend Use Case behaviour with Domain objects
---

# Extend Use Case behaviour with Domain objects

At the start of a Clean Architecture system, keep your Domain objects simple. A Domain object holds data and little behaviour. The Use Cases hold the logic. That order is deliberate.

[domain.md](../../domain.md) states the rule: _specialise Use Cases first. Specialised Use Cases produce an anemic domain model. Move behaviour into a Domain object after the same pattern appears in more than one Use Case._

This guide shows you how to recognise that pattern, and how to move the logic into the domain.

## Starting point: logic in the Use Case

Early on, a pricing rule belongs in the Use Case that needs the rule:

```ruby
class PlaceOrder
  def execute(customer_id:, items:)
    subtotal = items.sum { |item| item[:price] * item[:quantity] }
    total = items.sum { |i| i[:quantity] } >= 10 ? subtotal * 0.9 : subtotal

    id = @order_gateway.save(Order.new(customer_id: customer_id, items: items, total: total))
    { order_id: id }
  end
end
```

This is correct. One Use Case holds the rule, in one place.

## The signal: duplication across Use Cases

A second Use Case needs the same rule:

```ruby
class UpdateOrder
  def execute(order_id:, items:)
    subtotal = items.sum { |item| item[:price] * item[:quantity] }
    total = items.sum { |i| i[:quantity] } >= 10 ? subtotal * 0.9 : subtotal

    @order_gateway.save(Order.new(id: order_id, items: items, total: total))
    { order_id: order_id }
  end
end
```

The bulk discount rule is now in two places. When the threshold changes from 10 to 20, you must change both Use Cases. Miss one Use Case, and the system gives two different answers.

That duplication is the signal. A rule that must be correct for more than one Use Case belongs in the domain.

## Moving logic into a Domain object

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

Both Use Cases become shorter:

```ruby
class PlaceOrder
  def execute(customer_id:, items:)
    total = OrderPricing.new(items).total
    id = @order_gateway.save(Order.new(customer_id: customer_id, items: items, total: total))
    { order_id: id }
  end
end

class UpdateOrder
  def execute(order_id:, items:)
    total = OrderPricing.new(items).total
    @order_gateway.save(Order.new(id: order_id, items: items, total: total))
    { order_id: order_id }
  end
end
```

The rule now has one home. Each Use Case becomes an orchestrator that coordinates the flow. The Domain object holds the knowledge.

## Testing the Domain object independently

A Domain object has no Gateway and no Use Case dependency. A Domain object is the easiest part of your system to test:

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

The test needs no setup, no test double and no Gateway. The test is fast, isolated, and directed at the rule.

## Polymorphic behaviour from the database

A Domain object does more than hold a shared rule. When the Gateway constructs a different Domain object type from the stored data, the behaviour varies with the stored state, and the Use Case never learns which type it received.

Consider customer pricing tiers. A first Use Case branches on a tier flag:

```ruby
class PlaceOrder
  def execute(customer_id:, items:)
    customer = @customer_gateway.find(customer_id)
    pricing = OrderPricing.new(items)

    total = case customer.tier
            when 'wholesale'  then pricing.subtotal * 0.6
            when 'premium'    then pricing.subtotal * 0.8
            else                   pricing.subtotal
            end

    id = @order_gateway.save(Order.new(customer_id: customer_id, items: items, total: total))
    { order_id: id }
  end
end
```

Every new tier forces a change to that Use Case. A `'vip'` tier means you must find and change every Use Case that prices an order.

### Encode the variation in Domain objects

Write one class per tier. Each class responds to the same interface:

```ruby
class StandardCustomer
  def discount_rate
    1.0
  end
end

class PremiumCustomer
  def discount_rate
    0.8
  end
end

class WholesaleCustomer
  def initialize(account_manager_id:)
    @account_manager_id = account_manager_id
  end

  def discount_rate
    0.6
  end
end
```

The Gateway reads the `tier` column and constructs the right type. Two style points apply here:

**Use a lookup hash instead of a case statement.** A case statement needs a new branch inside existing code, so a case statement is closed to extension. A lookup hash is open to extension: a new tier means one new entry, and the existing entries stay as they are. A lookup hash is also faster to read.

**Store a constructor lambda instead of the class itself.** Each Domain object type takes different constructor parameters. `WholesaleCustomer` needs an `account_manager_id`, and `StandardCustomer` does not. A lambda keeps the call site the same for every type, which is `constructor.call(row)`, and lets each lambda pass the data that its own type needs.

```ruby
class SequelCustomerGateway
  TIER_CONSTRUCTORS = {
    'standard'  => ->(row) { StandardCustomer.new },
    'premium'   => ->(row) { PremiumCustomer.new },
    'wholesale' => ->(row) { WholesaleCustomer.new(account_manager_id: row[:account_manager_id]) }
  }.freeze

  def find(id)
    row = @customers.where(id: id).first
    constructor = TIER_CONSTRUCTORS.fetch(row[:tier], TIER_CONSTRUCTORS['standard'])
    constructor.call(row)
  end
end
```

The Use Case no longer needs to know which type of customer it holds:

```ruby
class PlaceOrder
  def execute(customer_id:, items:)
    customer = @customer_gateway.find(customer_id)
    total = OrderPricing.new(items).subtotal * customer.discount_rate

    id = @order_gateway.save(Order.new(customer_id: customer_id, items: items, total: total))
    { order_id: id }
  end
end
```

A `VipCustomer` with a 50% discount rate needs a new class and one new entry in `TIER_CONSTRUCTORS`. `PlaceOrder`, `UpdateOrder` and every other Use Case that prices an order need no change.

### Testing

Each Domain class is simple to test on its own:

```ruby
describe WholesaleCustomer do
  it 'has a 40% discount rate' do
    expect(described_class.new(account_manager_id: 1).discount_rate).to eq(0.6)
  end
end
```

### Extracting a Builder

A second Gateway will need to build the same customers: an HTTP Gateway onto another service, a CSV importer, or a read-replica Gateway. A reference to `SequelCustomerGateway::TIER_CONSTRUCTORS` from that second Gateway makes one persistence implementation depend on another. Neither Gateway may depend on the other.

Move the construction code into a builder:

```ruby
class CustomerBuilder
  CONSTRUCTORS = {
    'standard'  => ->(row) { StandardCustomer.new },
    'premium'   => ->(row) { PremiumCustomer.new },
    'wholesale' => ->(row) { WholesaleCustomer.new(account_manager_id: row[:account_manager_id]) }
  }.freeze

  def self.build(row)
    constructor = CONSTRUCTORS.fetch(row[:tier], CONSTRUCTORS['standard'])
    constructor.call(row)
  end
end
```

Every Gateway that reads stored data calls the builder. No Gateway owns the construction code, and no Gateway depends on another Gateway:

```ruby
class SequelCustomerGateway
  def find(id)
    CustomerBuilder.build(@customers.where(id: id).first)
  end
end

class HttpCustomerGateway
  def find(id)
    CustomerBuilder.build(get("/customers/#{id}"))
  end
end
```

The Fake needs no builder. The Fake receives `Customer` Domain objects to save, and returns the same objects:

```ruby
class InMemoryCustomerGateway
  def find(id)
    @customers[id]
  end

  def save(customer)
    @customers[customer.id] = customer
  end
end
```

Read that again. Every Gateway, real or Fake, accepts and returns Domain objects, so the Fake has nothing to translate. A builder is needed only where stored data must become a Domain object again. That is the concern of a Gateway that reads stored data, not of the domain and not of any Use Case.

A new tier now means a new Domain class and one new entry in `CustomerBuilder::CONSTRUCTORS`. Nothing else changes: no Gateway, no Fake, and no Use Case.

You can also test the builder on its own, to check that the builder produces the right type for each tier value.

## The guiding question

Before you move logic into the domain, ask one question: _must this rule hold for every Use Case in this [bounded context](../../bounded_contexts.md)?_

A rule that applies to one Use Case belongs in that Use Case. A rule that constrains the domain itself, and that would be wrong whichever Use Case in the bounded context triggered it, belongs in the domain. A rule that varies with the stored data belongs in a set of Domain object types, and the Gateway chooses which type to construct.

A rule that holds in one bounded context and not in another is not a rule of the shared domain. Each bounded context keeps its own Domain object for that concept.

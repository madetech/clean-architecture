---
title: Your first Real Gateway
---

# Your first Real Gateway

Once you understand the domain well enough — and your acceptance tests are passing with a Fake — it is time to replace the Fake with a gateway that talks to a real persistence store.

## What a Real Gateway does

A gateway is responsible for one thing: translating between the language of your domain and the language of your storage technology.

It converts a domain-friendly request into whatever the database expects, and converts what the database returns into a plain hash that the use case can work with.

That is the full extent of its responsibility. Business logic does not belong here.

## Implementing the adapter

The [Sequel](https://sequel.jeremyevans.net/) gem is a good fit for Clean Architecture in Ruby. Unlike ActiveRecord, Sequel keeps your database logic and your domain objects separate by default — there is no temptation to inherit from a base class and pull in persistence concerns.

Here is a Sequel gateway for orders:

```ruby
class SequelOrderGateway
  def initialize(db)
    @orders = db[:orders]
    @line_items = db[:line_items]
  end

  def save(customer_id:, items:)
    id = @orders.insert(customer_id: customer_id)
    items.each do |item|
      @line_items.insert(order_id: id, sku: item[:sku], quantity: item[:quantity])
    end
    id
  end

  def find_by_id(id)
    order = @orders.where(id: id).first
    return nil unless order

    items = @line_items.where(order_id: id).map do |row|
      { sku: row[:sku], quantity: row[:quantity] }
    end

    {
      id: order[:id],
      customer_id: order[:customer_id],
      items: items
    }
  end
end
```

The use case knows nothing about Sequel, table names, or how items are stored. That is the point.

## Keep the gateway thin

The gateway's job is persistence, not policy. Validation and rules belong in your use case or domain:

```ruby
# Don't do this
def save(customer_id:, items:)
  raise 'No items' if items.empty?   # business logic — belongs in the use case
  @orders.insert(...)
end
```

## Testing your Real Gateway

Gateway tests are integration tests — they run against a real database instance, not a Fake. This is correct and expected.

Run the [shared contract](./reliable-dependencies.md) against your real gateway first:

```ruby
describe SequelOrderGateway do
  subject { SequelOrderGateway.new(DB) }
  it_behaves_like 'an order gateway'
end
```

Once the contract passes, add gateway-specific tests for edge cases the contract does not cover:

```ruby
describe SequelOrderGateway do
  describe '#find_by_id' do
    context 'when the order does not exist' do
      it 'returns nil' do
        expect(subject.find_by_id(99999)).to be_nil
      end
    end
  end
end
```

Keep gateway integration tests in a separate suite from your unit tests. The inner TDD loop depends on fast feedback — gateway tests are slower by nature and should not slow down every red-green cycle.

## Swapping in the real gateway

When you replace the Fake with the real gateway, only your wiring changes — the place where you construct use cases and inject dependencies. Use cases, domain objects, and acceptance tests remain untouched.

This is the payoff of keeping the gateway behind a consistent interface from the start.

## A note on Rails

### Tableless models in the delivery mechanism

If you are building a Rails application, one option is to use tableless ActiveRecord objects in your delivery mechanism for form objects and parameter handling — giving you Rails conventions (validations, strong parameters) at the HTTP boundary without ActiveRecord objects leaking into your use cases.

```ruby
class OrderForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :customer_id, :integer
  attribute :items, default: []

  validates :customer_id, presence: true
end
```

The form object lives in the delivery mechanism. Your use case receives a plain hash, as always.

### Rails and Clean Architecture work against each other

That said, using Rails with Clean Architecture is likely to lead to framework frustration. Rails is designed around the Active Record pattern and convention over configuration — a tight coupling between your domain model and your persistence layer is a feature, not a bug, in Rails' worldview.

Clean Architecture pulls in exactly the opposite direction: keep your domain free of persistence concerns, defer technology choices, and make frameworks replaceable.

Attempting both at once means fighting Rails' conventions at every turn. You will find yourself working around the framework rather than with it. For greenfield projects, a lighter framework — Sinatra, Hanami, or Roda — will create far less friction with a Clean Architecture approach.

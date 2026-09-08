---
title: Your first Real Gateway
---

# Your first Real Gateway

Replace the Fake with a Gateway that talks to a real persistence store once you understand the domain well enough, and once your acceptance tests pass against the Fake.

## What a Real Gateway does

A Gateway does one thing: a Gateway translates between the language of your domain and the language of your storage technology.

A Gateway accepts a [Domain](../../domain.md) object and converts it into the form the database expects. A Gateway also converts what the database returns into a Domain object that the Use Case reads.

A Gateway does nothing else. Business logic does not belong in a Gateway.

An identifier is the only thing that crosses the Gateway boundary and is *not* a Domain object. An identifier is an id, an email address, or a date range. Everything else, in both directions, is a Domain object.

## Implementing the adapter

The [Sequel](https://sequel.jeremyevans.net/) gem suits Clean Architecture in Ruby. Sequel keeps your database code and your Domain objects separate by default. ActiveRecord does not, because ActiveRecord invites you to inherit from a base class and to pull persistence into the Domain object.

Here is a Sequel Gateway for orders:

```ruby
class SequelOrderGateway
  def initialize(db)
    @orders = db[:orders]
    @line_items = db[:line_items]
  end

  def save(order)
    id = @orders.insert(customer_id: order.customer_id)
    order.items.each do |item|
      @line_items.insert(order_id: id, sku: item.sku, quantity: item.quantity)
    end
    id
  end

  def find_by_id(id)
    row = @orders.where(id: id).first
    return nil unless row

    items = @line_items.where(order_id: id).map do |item_row|
      LineItem.new(sku: item_row[:sku], quantity: item_row[:quantity])
    end

    Order.new(id: row[:id], customer_id: row[:customer_id], items: items)
  end
end
```

The Use Case knows nothing about Sequel, about the table names, or about how the Gateway stores the items.

Read what `save` accepts: an `Order`, not `customer_id:` and `items:`. A Gateway that took a bag of attributes would force every Use Case that saves an order to know how an order is assembled, and would spread the shape of an order across the system instead of holding that shape in one class. The same rule applies in reverse. `find_by_id` returns an `Order`, not a hash, so the Use Case asks the order questions instead of reading keys.

An update works the same way. There is no separate `update` method that takes an id and a hash of changes. The Use Case reads an order, changes the order, and saves the order:

```ruby
order = order_gateway.find_by_id(order_id)
order.cancel
order_gateway.save(order)
```

## Keep the Gateway thin

A Gateway performs persistence. A Gateway does not apply policy. Validation and business rules belong in your Use Case or in your Domain object:

```ruby
# Wrong
def save(order)
  raise 'No items' if order.items.empty?   # a business rule belongs in the Use Case or the Domain object
  @orders.insert(...)
end
```

## Testing your Real Gateway

Gateway tests are integration tests. Gateway tests run against a real database instance, not against a Fake. That is correct.

Run the [shared contract](./reliable-dependencies.md) against your real Gateway first:

```ruby
describe SequelOrderGateway do
  subject { SequelOrderGateway.new(DB) }
  it_behaves_like 'an order gateway'
end
```

Once the contract passes, add Gateway-specific tests for the edge cases the contract does not cover:

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

Keep the Gateway integration tests in a separate suite from your unit tests. The inner TDD loop needs fast feedback. A Gateway test is slower, and must not slow down every red-green cycle.

## Swapping in the real Gateway

When you replace the Fake with the real Gateway, only your wiring changes. The wiring is the place where you construct Use Cases and inject dependencies. The Use Cases, the Domain objects and the acceptance tests need no change.

That is the return on keeping the Gateway behind one consistent interface from the start.

## A note on Rails

### Tableless models in the Delivery Mechanism

In a Rails application, one option is to use tableless ActiveRecord objects in your Delivery Mechanism for form objects and parameter handling. Tableless models give you the Rails conventions, such as validations and strong parameters, at the HTTP boundary. No ActiveRecord object then reaches your Use Cases.

```ruby
class OrderForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :customer_id, :integer
  attribute :items, default: []

  validates :customer_id, presence: true
end
```

The form object belongs in the Delivery Mechanism. Your Use Case receives a plain hash, as always.

### Rails and Clean Architecture work against each other

WARNING: Rails and Clean Architecture pull in opposite directions.

Rails is built around the Active Record pattern and around convention over configuration. In Rails, tight coupling between your domain model and your persistence layer is intended.

Clean Architecture keeps your domain free of persistence concerns, defers technology choices, and makes frameworks replaceable.

Use both at once and you work against the Rails conventions in most files. For a new project, a lighter framework such as Sinatra, Hanami or Roda fits Clean Architecture better.

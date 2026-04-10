# Your first Real Gateway

Once you understand the domain well enough — and your acceptance tests are passing with a Fake — it is time to replace the Fake with a gateway that talks to a real persistence store.

## What a Real Gateway does

A gateway is responsible for one thing: translating between the language of your domain and the language of your storage technology.

It converts a domain-friendly request into whatever the database expects, and converts what the database returns into a plain hash that the use case can work with.

That is the full extent of its responsibility. Business logic does not belong here.

## Implementing the adapter

Here is a simple ActiveRecord gateway for orders:

```ruby
class ActiveRecordOrderGateway
  def save(customer_id:, items:)
    record = OrderRecord.create!(
      customer_id: customer_id,
      line_items: items.to_json
    )
    record.id
  end

  def find_by_id(id)
    record = OrderRecord.find(id)
    {
      id: record.id,
      customer_id: record.customer_id,
      items: JSON.parse(record.line_items, symbolize_names: true)
    }
  end
end
```

The use case knows nothing about `OrderRecord`, `to_json`, or ActiveRecord. That is the point.

## Keep the gateway thin

It is tempting — especially with ActiveRecord — to let logic creep in:

```ruby
# Don't do this
def save(customer_id:, items:)
  raise 'No items' if items.empty?   # business logic — belongs in the use case
  OrderRecord.create!(...)
end
```

Validation and rules belong in your use case or domain. The gateway's job is persistence, not policy.

## Testing your Real Gateway

Gateway tests are integration tests — they run against a real database instance, not a Fake. This is correct and expected.

Run the [shared contract](./reliable-dependencies.md) against your real gateway first:

```ruby
describe ActiveRecordOrderGateway do
  subject { ActiveRecordOrderGateway.new }
  it_behaves_like 'an order gateway'
end
```

Once the contract passes, add gateway-specific tests for edge cases the contract does not cover:

```ruby
describe ActiveRecordOrderGateway do
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

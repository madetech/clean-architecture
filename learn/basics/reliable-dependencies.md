# Build in a reliable dependency upgrade path

Fake gateways let you build and test your application without a real database. But there is a risk: your Fake can drift from the real thing.

If the Fake behaves differently to the real gateway, your test suite will pass while your application fails in production. This is the worst kind of test failure — the invisible one.

## The problem

Imagine your `InMemoryOrderGateway` returns orders sorted by insertion order. Your real `ActiveRecordOrderGateway` returns them sorted by `created_at` descending.

Your acceptance tests pass. Your production app shows orders in the wrong order.

The Fake lied.

## Gateway contracts

The solution is to write a shared contract: a set of tests that both your Fake and your real gateway must pass.

In RSpec, this is done with `shared_examples`:

```ruby
RSpec.shared_examples 'an order gateway' do
  it 'saves and retrieves an order by id' do
    id = subject.save(customer_id: 1, items: [])
    order = subject.find_by_id(id)
    expect(order[:customer_id]).to eq(1)
  end

  it 'returns orders in reverse chronological order' do
    subject.save(customer_id: 1, items: [])
    subject.save(customer_id: 2, items: [])
    orders = subject.all
    expect(orders.first[:customer_id]).to eq(2)
  end
end
```

Both gateways include the contract:

```ruby
describe InMemoryOrderGateway do
  subject { InMemoryOrderGateway.new }
  it_behaves_like 'an order gateway'
end

describe ActiveRecordOrderGateway do
  subject { ActiveRecordOrderGateway.new }
  it_behaves_like 'an order gateway'
end
```

Now the Fake is contractually obligated to behave the same way as the real gateway. If either drifts, the contract tests catch it.

## What the contract should cover

- The interface: what methods exist, what they accept, what they return
- The semantics: ordering, uniqueness constraints, what happens when a record is not found

The contract does not need to test every edge case — that is the job of the real gateway's own integration tests. It only needs to cover the behaviour your use cases depend on.

## The upgrade path

When you introduce a new persistence technology — say, replacing ActiveRecord with a raw SQL gateway — you:

1. Implement the new gateway
2. Run the contract tests against it
3. If they pass, swap it in

Your use cases, domain objects, and acceptance tests require no changes. The contract tests are your safety net.

## From the trenches

A Fake is a working implementation with shortcuts. That "working" part is the obligation — it must faithfully represent the behaviour of the real thing within the contract. Shared contract tests are how you enforce that obligation and ensure the shortcuts never become lies.

---
title: Build in a reliable dependency upgrade path
---

# Build in a reliable dependency upgrade path

A Fake Gateway lets you build and test your application without a real database. A Fake Gateway also carries a risk: the Fake can drift away from the real Gateway.

WARNING: When the Fake behaves differently from the real Gateway, your test suite passes and your application fails in Production. That failure is invisible until it reaches a user.

## The problem

Your `InMemoryOrderGateway` returns orders in insertion order. Your real `ActiveRecordOrderGateway` returns orders sorted by `created_at` descending.

Your acceptance tests pass. Your Production application shows the orders in the wrong order.

The Fake reported behaviour that the real Gateway does not have.

## Gateway contracts

Write a shared contract, which is a set of tests that the Fake and the real Gateway must both pass.

In RSpec, write the contract with `shared_examples`:

```ruby
RSpec.shared_examples 'an order gateway' do
  it 'saves and retrieves an order by id' do
    id = subject.save(Order.new(customer_id: 1, items: []))
    order = subject.find_by_id(id)
    expect(order.customer_id).to eq(1)
  end

  it 'returns orders in reverse chronological order' do
    subject.save(Order.new(customer_id: 1, items: []))
    subject.save(Order.new(customer_id: 2, items: []))
    orders = subject.all
    expect(orders.first.customer_id).to eq(2)
  end
end
```

Write the contract entirely in [Domain](../../domain.md) objects. The contract passes an `Order` to the Gateway, and expects an `Order` back. Every Gateway exposes that same interface, so the contract is the place to pin the interface down. A contract written against hashes lets a Fake and a real Gateway agree on the keys while they disagree about the domain.

Include the contract in the tests of both Gateways:

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

The contract now requires the Fake to behave the same way as the real Gateway. When either one drifts, the contract tests fail.

## What the contract should cover

- The interface: which methods exist, which Domain objects each method accepts, and which Domain objects each method returns
- The semantics: ordering, uniqueness constraints, and the result when a record does not exist

The contract does not need to test every edge case. The integration tests of the real Gateway test those. The contract covers the behaviour that your Use Cases depend on.

## The upgrade path

Follow these steps when you introduce a new persistence technology, such as a raw SQL Gateway in place of ActiveRecord:

1. Write the new Gateway
2. Run the contract tests against the new Gateway
3. When the contract tests pass, swap the new Gateway in

Your Use Cases, your Domain objects and your acceptance tests need no change. The contract tests protect all three.

## In practice

A Fake is a working implementation with shortcuts. The word "working" is the obligation: within the contract, the Fake must reproduce the behaviour of the real Gateway. Shared contract tests enforce that obligation, and stop the shortcuts from reporting behaviour that the real Gateway does not have.

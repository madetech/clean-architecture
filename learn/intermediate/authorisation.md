---
title: Authorisation
---

# Authorisation

[Authentication](./authentication.md) answers "who are you?". Authorisation answers "what are you allowed to do?".

The two are separate concerns, and each belongs in a separate place.

## The problem with authorisation inside Use Cases

It is tempting to check the permission inside the Use Case:

```ruby
class CancelOrder
  def execute(order_id:, actor_id:)
    order = @order_gateway.find_by_id(order_id)
    return { success: false, errors: [:not_authorised] } unless order.customer_id == actor_id
    order.cancel
    @order_gateway.save(order)
    { success: true }
  end
end
```

That code works, and that code mixes two concerns: "may this user cancel this order?" and "cancel the order". As the authorisation rules grow to cover roles, team membership and time windows, the Use Case fills with logic that has nothing to do with cancellation. A test of the cancellation logic then also needs an authorisation setup.

## The proxy pattern

Write a proxy class that wraps the call to the Use Case. The proxy performs the authorisation and nothing else. When the check passes, the proxy calls the real Use Case. When the check fails, the proxy returns early. The real Use Case holds business logic only.

```ruby
# The real use case — knows nothing about who is allowed to call it
class CancelOrder
  def initialize(order_gateway:)
    @order_gateway = order_gateway
  end

  def execute(order_id:)
    order = @order_gateway.find_by_id(order_id)
    order.cancel
    @order_gateway.save(order)
    { success: true }
  end
end
```

The Gateway returns an `Order` [Domain](../../domain.md) object, and accepts an `Order` back to save. The Gateway has no `cancel(order_id)` method. An order knows how to cancel itself. The Gateway saves the result.

```ruby
# The proxy — responsible only for authorisation
class AuthorisedCancelOrder
  def initialize(cancel_order:, order_gateway:, current_user:)
    @cancel_order = cancel_order
    @order_gateway = order_gateway
    @current_user = current_user
  end

  def execute(order_id:)
    order = @order_gateway.find_by_id(order_id)
    policy = OrderPolicy.new(order: order, current_user: @current_user)
    return { success: false, errors: [:not_authorised] } unless policy.can_cancel?

    @cancel_order.execute(order_id: order_id)
  end
end
```

WARNING: A `:not_found` error for a missing record tells the caller which records exist in the system. The proxy above returns `:not_authorised` both when the order does not exist and when the actor has no permission.

The proxy exposes the same interface as the Use Case it wraps: the proxy responds to `execute`. The Delivery Mechanism cannot tell the two apart.

## Policy objects

A policy object holds the authorisation rules. Only a proxy class evaluates a policy object. A Use Case does not. A Delivery Mechanism does not.

The Gateway returns an `Order` Domain object, so the policy reads the domain instead of a database column.

The policy receives the data it needs for the decision, and the `CurrentUser` that gives the actor context. [Authentication](./authentication.md) introduces `CurrentUser`.

```ruby
class OrderPolicy
  def initialize(order:, current_user:)
    @order = order
    @current_user = current_user
  end

  def can_cancel?
    return false unless @order
    owns_order? && order_is_pending?
  end

  def can_view?
    return false unless @order
    owns_order?
  end

  private

  def owns_order?
    @order.customer_id == @current_user.id
  end

  def order_is_pending?
    @order.pending?
  end
end
```

A policy object is plain Ruby with no dependencies, so a policy object is one of the easiest parts of the system to test.

## Wiring via the dependency factory

The [dependency factory](./keep-your-wiring-DRY.md) composes the proxy around the Use Case. The Delivery Mechanism asks for `:cancel_order` and receives whatever the factory registers, which includes the proxy:

```ruby
class Dependencies
  def initialize(db:, current_user:)
    @db = db
    @current_user = current_user
  end

  def get_use_case(name)
    case name
    when :cancel_order
      AuthorisedCancelOrder.new(
        cancel_order: CancelOrder.new(order_gateway: order_gateway),
        order_gateway: order_gateway,
        current_user: @current_user
      )
    end
  end
end
```

The Delivery Mechanism does not know that a proxy exists:

```ruby
delete '/orders/:id' do
  result = get_use_case(:cancel_order).execute(order_id: params[:id].to_i)
  json(result)
end
```

## Testing each layer independently

Test the policy on its own, with no Gateway and no Use Case:

```ruby
describe OrderPolicy do
  describe '#can_cancel?' do
    context 'when the actor owns the order and it is pending' do
      it 'permits cancellation' do
        order = Order.new(customer_id: 1, status: 'pending', items: [])
        current_user = CurrentUser.new(1)
        expect(described_class.new(order: order, current_user: current_user).can_cancel?).to be(true)
      end
    end

    context 'when the actor does not own the order' do
      it 'denies cancellation' do
        order = Order.new(customer_id: 1, status: 'pending', items: [])
        current_user = CurrentUser.new(2)
        expect(described_class.new(order: order, current_user: current_user).can_cancel?).to be(false)
      end
    end

    context 'when the order is not pending' do
      it 'denies cancellation' do
        order = Order.new(customer_id: 1, status: 'dispatched', items: [])
        current_user = CurrentUser.new(1)
        expect(described_class.new(order: order, current_user: current_user).can_cancel?).to be(false)
      end
    end
  end
end
```

Test the Use Case with no authorisation setup at all:

```ruby
describe CancelOrder do
  let(:order_gateway) { InMemoryOrderGateway.new }
  subject { described_class.new(order_gateway: order_gateway) }

  it 'cancels the order' do
    order_id = order_gateway.save(Order.new(customer_id: 1, status: 'pending', items: []))
    result = subject.execute(order_id: order_id)
    expect(result[:success]).to be(true)
  end
end
```

Test the proxy with a stub inner Use Case. The test checks that the proxy applies the policy and calls the inner Use Case:

```ruby
describe AuthorisedCancelOrder do
  let(:inner_use_case) { double(:cancel_order, execute: { success: true }) }
  let(:order_gateway) { InMemoryOrderGateway.new }
  let(:current_user) { CurrentUser.new(1) }

  subject do
    described_class.new(
      cancel_order: inner_use_case,
      order_gateway: order_gateway,
      current_user: current_user
    )
  end

  context 'when the actor owns a pending order' do
    it 'delegates to the inner use case' do
      order_id = order_gateway.save(Order.new(customer_id: 1, status: 'pending', items: []))
      subject.execute(order_id: order_id)
      expect(inner_use_case).to have_received(:execute).with(order_id: order_id)
    end
  end

  context 'when the actor does not own the order' do
    it 'returns not_authorised without delegating' do
      order_id = order_gateway.save(Order.new(customer_id: 2, status: 'pending', items: []))
      result = subject.execute(order_id: order_id)
      expect(result[:errors]).to include(:not_authorised)
      expect(inner_use_case).not_to have_received(:execute)
    end
  end
end
```

## What must not go in the Delivery Mechanism

It is tempting to apply authorisation in a `before` filter:

```ruby
# Wrong
before '/orders/:id/cancel' do
  order = order_gateway.find_by_id(params[:id].to_i)
  halt 403 unless order.customer_id == @current_user_id
end
```

WARNING: That rule is now tied to one HTTP route. A background job, a CLI command or another Use Case triggers the same action with no protection. Authorisation in a Delivery Mechanism protects that one Delivery Mechanism only.

The proxy pattern keeps the protection with the Use Case, whichever caller starts it.

## In practice

Authorisation rules grow to cover roles, team membership and time windows. Extra policy methods and extra proxy classes absorb that growth. A Use Case with twenty lines of permission checks before the first line of real work tells you that the proxy is missing.

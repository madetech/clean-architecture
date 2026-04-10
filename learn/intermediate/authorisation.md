# Authorisation

[Authentication](./authentication.md) answers "who are you?". Authorisation answers "what are you allowed to do?".

They are distinct concerns and should live in distinct places.

## The problem with authorisation inside use cases

It is tempting to check permissions inside the use case itself:

```ruby
class CancelOrder
  def execute(order_id:, actor_id:)
    order = @order_gateway.find_by_id(order_id)
    return { success: false, errors: [:not_authorised] } unless order[:customer_id] == actor_id
    @order_gateway.cancel(order_id)
    { success: true }
  end
end
```

This works, but it mixes two concerns: "is this user allowed to cancel this order?" and "cancel the order". As authorisation rules grow — roles, team membership, time-based windows — the use case fills up with logic that has nothing to do with cancellation. Testing the cancellation logic also requires setting up authorisation scenarios.

## The proxy pattern

A cleaner approach is a proxy class that wraps the use case call. The proxy is solely responsible for authorisation. If the check passes, it delegates to the real use case. If not, it returns early. The real use case remains pure business logic.

```ruby
# The real use case — knows nothing about who is allowed to call it
class CancelOrder
  def initialize(order_gateway:)
    @order_gateway = order_gateway
  end

  def execute(order_id:)
    @order_gateway.cancel(order_id)
    { success: true }
  end
end
```

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

Note that the proxy returns `:not_authorised` whether the order does not exist or the actor lacks permission. This is intentional — returning `:not_found` for a missing resource leaks information about what exists in the system.

The proxy has the same interface as the use case it wraps: it responds to `execute`. From the delivery mechanism's perspective, they are interchangeable.

## Policy objects

Policy objects hold the authorisation rules. They are only ever evaluated by proxy classes — not by use cases, not by delivery mechanisms.

The policy receives the data it needs to make a decision and the `CurrentUser` that provides actor context (introduced in [Authentication](./authentication.md)):

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
    @order[:customer_id] == @current_user.id
  end

  def order_is_pending?
    @order[:status] == 'pending'
  end
end
```

Policy objects are plain Ruby with no dependencies — they are among the easiest things in the system to test.

## Wiring via the dependency factory

The [dependency factory](./keep-your-wiring-DRY.md) composes the proxy around the use case transparently. The delivery mechanism requests `:cancel_order` and receives whatever is registered — proxy included:

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

The delivery mechanism is completely unaware that a proxy exists:

```ruby
delete '/orders/:id' do
  result = get_use_case(:cancel_order).execute(order_id: params[:id].to_i)
  json(result)
end
```

## Testing each layer independently

Test the policy in isolation — no gateways, no use cases:

```ruby
describe OrderPolicy do
  describe '#can_cancel?' do
    context 'when the actor owns the order and it is pending' do
      it 'permits cancellation' do
        order = { customer_id: 1, status: 'pending' }
        current_user = CurrentUser.new(1)
        expect(described_class.new(order: order, current_user: current_user).can_cancel?).to be(true)
      end
    end

    context 'when the actor does not own the order' do
      it 'denies cancellation' do
        order = { customer_id: 1, status: 'pending' }
        current_user = CurrentUser.new(2)
        expect(described_class.new(order: order, current_user: current_user).can_cancel?).to be(false)
      end
    end

    context 'when the order is not pending' do
      it 'denies cancellation' do
        order = { customer_id: 1, status: 'dispatched' }
        current_user = CurrentUser.new(1)
        expect(described_class.new(order: order, current_user: current_user).can_cancel?).to be(false)
      end
    end
  end
end
```

Test the use case with no authorisation concerns at all:

```ruby
describe CancelOrder do
  let(:order_gateway) { InMemoryOrderGateway.new }
  subject { described_class.new(order_gateway: order_gateway) }

  it 'cancels the order' do
    order_id = order_gateway.save(customer_id: 1, status: 'pending', items: [])
    result = subject.execute(order_id: order_id)
    expect(result[:success]).to be(true)
  end
end
```

Test the proxy with a stub inner use case to verify it enforces the policy and delegates correctly:

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
      order_id = order_gateway.save(customer_id: 1, status: 'pending', items: [])
      subject.execute(order_id: order_id)
      expect(inner_use_case).to have_received(:execute).with(order_id: order_id)
    end
  end

  context 'when the actor does not own the order' do
    it 'returns not_authorised without delegating' do
      order_id = order_gateway.save(customer_id: 2, status: 'pending', items: [])
      result = subject.execute(order_id: order_id)
      expect(result[:errors]).to include(:not_authorised)
      expect(inner_use_case).not_to have_received(:execute)
    end
  end
end
```

## What must not live in the delivery mechanism

It is tempting to enforce authorisation in a `before` filter:

```ruby
# Avoid this
before '/orders/:id/cancel' do
  order = order_gateway.find_by_id(params[:id].to_i)
  halt 403 unless order[:customer_id] == @current_user_id
end
```

The rule is now tied to an HTTP route. If the same action is triggered by a background job, a CLI command, or another use case, the protection is absent. Authorisation in the delivery mechanism is only authorisation for that one delivery mechanism.

The proxy pattern ensures the protection travels with the use case, regardless of how it is invoked.

## From the trenches

As authorisation rules grow complex — roles, team membership, time-based windows — additional policy methods and proxy classes absorb that complexity cleanly. A use case that has grown twenty lines of permission checks before doing any real work is a signal the proxy is missing.

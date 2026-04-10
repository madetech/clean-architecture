# Authorisation

[Authentication](./authentication.md) answers "who are you?". Authorisation answers "what are you allowed to do?".

They are distinct concerns and should live in distinct places.

## Policy objects as domain objects

Authorisation rules are domain knowledge. "A customer may only cancel their own orders, and only if the order is still pending" is a business rule — it belongs in the domain, not scattered across use cases or delivery mechanisms.

Model it as a domain object:

```ruby
class OrderPolicy
  def initialize(order:, actor_id:)
    @order = order
    @actor_id = actor_id
  end

  def can_cancel?
    owns_order? && order_is_pending?
  end

  def can_view?
    owns_order?
  end

  private

  def owns_order?
    @order[:customer_id] == @actor_id
  end

  def order_is_pending?
    @order[:status] == 'pending'
  end
end
```

Policy objects are plain Ruby objects with no dependencies — they are among the easiest things in the system to test.

## Enforcing authorisation inside the use case

The use case enforces the policy after loading the relevant data:

```ruby
class CancelOrder
  def initialize(order_gateway:)
    @order_gateway = order_gateway
  end

  def execute(order_id:, actor_id:)
    order = @order_gateway.find_by_id(order_id)
    return { success: false, errors: [:order_not_found] } unless order

    policy = OrderPolicy.new(order: order, actor_id: actor_id)
    return { success: false, errors: [:not_authorised] } unless policy.can_cancel?

    @order_gateway.cancel(order_id)
    { success: true }
  end
end
```

The use case loads the record, checks the policy, and acts — in that order. The delivery mechanism need only pass the authenticated actor's ID.

## Testing authorisation

Test the policy object independently, without touching the use case or gateway:

```ruby
describe OrderPolicy do
  describe '#can_cancel?' do
    context 'when the actor owns the order and it is pending' do
      it 'permits cancellation' do
        order = { customer_id: 1, status: 'pending' }
        expect(described_class.new(order: order, actor_id: 1).can_cancel?).to be(true)
      end
    end

    context 'when the actor does not own the order' do
      it 'denies cancellation' do
        order = { customer_id: 1, status: 'pending' }
        expect(described_class.new(order: order, actor_id: 2).can_cancel?).to be(false)
      end
    end

    context 'when the order is not pending' do
      it 'denies cancellation' do
        order = { customer_id: 1, status: 'dispatched' }
        expect(described_class.new(order: order, actor_id: 1).can_cancel?).to be(false)
      end
    end
  end
end
```

Test the use case separately, with a stub policy or by exercising the full flow through a fake gateway:

```ruby
describe CancelOrder do
  let(:order_gateway) { InMemoryOrderGateway.new }
  let(:use_case) { described_class.new(order_gateway: order_gateway) }

  context 'when the actor does not own the order' do
    it 'returns not_authorised' do
      order_id = order_gateway.save(customer_id: 1, status: 'pending', items: [])
      result = use_case.execute(order_id: order_id, actor_id: 2)
      expect(result[:errors]).to include(:not_authorised)
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

The problem is that the rule is now tied to an HTTP route. If the same action is later triggered by a background job, a CLI command, or another use case, the protection is missing. Authorisation logic in the delivery mechanism is only authorisation for that one delivery mechanism.

Enforcing rules inside the use case means the protection travels with the business logic, regardless of how it is invoked.

## From the trenches

Authorisation rules have a habit of growing complex — roles, ownership, team membership, time-based restrictions. Policy objects accommodate this naturally: add methods, add tests, keep it out of use cases. A use case that contains twenty lines of authorisation logic before it does any real work is a sign the policy object is missing.

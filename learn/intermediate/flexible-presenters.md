# Presenters are more flexible

Returning a hash from a use case is the right default. It is simple, easy to test, and works well for most situations.

But as a system grows, use cases accumulate more outcomes. Each new outcome requires every caller to branch on the result hash. Left unchecked, the same `if` statement ends up duplicated across the codebase — and this is a symptom of zero polymorphism.

## The zero polymorphism problem

Consider a use case that can fail in multiple ways:

```ruby
class PlaceOrder
  def execute(customer_id:, items:)
    customer = @customer_gateway.find(customer_id)
    return { status: :customer_not_found } unless customer
    return { status: :no_items } if items.empty?
    return { status: :out_of_stock } unless @inventory_gateway.all_available?(items)

    order_id = @order_gateway.save(customer_id: customer_id, items: items)
    { status: :success, order_id: order_id }
  end
end
```

Every caller must now branch on `status`:

```ruby
# HTML controller
result = place_order.execute(customer_id: id, items: params[:items])
case result[:status]
when :success        then redirect_to order_path(result[:order_id])
when :customer_not_found then redirect_to login_path
when :no_items       then render :cart, alert: 'Your cart is empty'
when :out_of_stock   then render :cart, alert: 'Some items are out of stock'
end
```

```ruby
# JSON API controller
result = place_order.execute(customer_id: id, items: params[:items])
case result[:status]
when :success        then json({ order_id: result[:order_id] }, status: 201)
when :customer_not_found then json({ error: 'not_found' }, status: 404)
when :no_items       then json({ error: 'no_items' }, status: 422)
when :out_of_stock   then json({ error: 'out_of_stock' }, status: 422)
end
```

The same four-way branch appears in every delivery mechanism. Add a fifth outcome to the use case and every caller must be updated. This is the definition of zero polymorphism: variation handled by repeated conditionals rather than by different objects.

In the worst case the same `if` appears in all three layers — the gateway inspecting a type to build the right data structure, the use case inspecting it again to apply the right rule, the delivery mechanism inspecting it a third time to render the right response. The [extend-with-domain](./extend-with-domain.md) guide covers eliminating the gateway and use case branches through polymorphic domain objects. The presenter pattern eliminates the delivery mechanism branch.

## The presenter pattern

Instead of returning a hash, the use case accepts a presenter and calls a named method per outcome:

```ruby
class PlaceOrder
  def initialize(order_gateway:, customer_gateway:, inventory_gateway:)
    @order_gateway = order_gateway
    @customer_gateway = customer_gateway
    @inventory_gateway = inventory_gateway
  end

  def execute(customer_id:, items:, presenter:)
    customer = @customer_gateway.find(customer_id)
    return presenter.customer_not_found unless customer
    return presenter.no_items if items.empty?
    return presenter.out_of_stock unless @inventory_gateway.all_available?(items)

    order_id = @order_gateway.save(customer_id: customer_id, items: items)
    presenter.success(order_id: order_id)
  end
end
```

Each caller provides its own implementation of the outcome methods. The branching disappears — replaced by polymorphism.

## Self-shunting: the controller as the presenter

The simplest way to provide a presenter is to make the controller the presenter itself. The controller passes `self` to the use case and implements the outcome methods directly:

```ruby
class OrdersController < ApplicationController
  def create
    place_order.execute(
      customer_id: current_user.id,
      items: params[:items],
      presenter: self
    )
  end

  def success(order_id:)
    redirect_to order_path(order_id)
  end

  def customer_not_found
    redirect_to login_path
  end

  def no_items
    render :cart, alert: 'Your cart is empty'
  end

  def out_of_stock
    render :cart, alert: 'Some items are out of stock'
  end
end
```

This is called self-shunting. There is no indirection — the controller is the presenter. Each outcome is a named method, not a branch in `create`. Adding a new outcome means adding a new method, not modifying an existing one.

The JSON API controller handles the same outcomes differently, with no shared code needed:

```ruby
class Api::OrdersController < ApplicationController
  def create
    place_order.execute(
      customer_id: current_user.id,
      items: params[:items],
      presenter: self
    )
  end

  def success(order_id:)
    render json: { order_id: order_id }, status: :created
  end

  def customer_not_found
    render json: { error: 'customer_not_found' }, status: :not_found
  end

  def no_items
    render json: { error: 'no_items' }, status: :unprocessable_entity
  end

  def out_of_stock
    render json: { error: 'out_of_stock' }, status: :unprocessable_entity
  end
end
```

## A worked example: polymorphism at every layer

The sections above address the delivery mechanism layer in isolation. This example shows the full chain: the same polymorphism that eliminates branching in the gateway and use case (covered in [extend-with-domain](./extend-with-domain.md)) extends through to the delivery mechanism.

The scenario: viewing an order that can be in one of three states — pending, confirmed, or dispatched. Each state carries different data and should render differently.

### The domain objects

Each state is a separate class. Each knows how to render itself to a presenter by calling the appropriate method — there is no branching, just a direct call:

```ruby
class PendingOrder
  def initialize(id:, items:)
    @id = id
    @items = items
  end

  def render_to(presenter)
    presenter.pending(id: @id, items: @items)
  end
end

class ConfirmedOrder
  def initialize(id:, items:, confirmed_at:)
    @id = id
    @items = items
    @confirmed_at = confirmed_at
  end

  def render_to(presenter)
    presenter.confirmed(id: @id, items: @items, confirmed_at: @confirmed_at)
  end
end

class DispatchedOrder
  def initialize(id:, items:, tracking_number:)
    @id = id
    @items = items
    @tracking_number = tracking_number
  end

  def render_to(presenter)
    presenter.dispatched(id: @id, items: @items, tracking_number: @tracking_number)
  end
end
```

Notice that each type passes only the data relevant to it. `DispatchedOrder` provides a `tracking_number`; `PendingOrder` does not need one and does not mention it. The presenter method signature for each outcome reflects exactly what that state can offer.

### The gateway and builder

The gateway reads the `status` column and delegates construction to a builder (see [extend-with-domain](./extend-with-domain.md) for the full rationale). Constructor lambdas handle the differing parameters each type requires:

```ruby
class OrderBuilder
  CONSTRUCTORS = {
    'pending'    => ->(row) { PendingOrder.new(id: row[:id], items: row[:items]) },
    'confirmed'  => ->(row) { ConfirmedOrder.new(id: row[:id], items: row[:items], confirmed_at: row[:confirmed_at]) },
    'dispatched' => ->(row) { DispatchedOrder.new(id: row[:id], items: row[:items], tracking_number: row[:tracking_number]) }
  }.freeze

  def self.build(row)
    constructor = CONSTRUCTORS.fetch(row[:status], CONSTRUCTORS['pending'])
    constructor.call(row)
  end
end

class SequelOrderGateway
  def find_by_id(id)
    row = @orders.where(id: id).first
    return nil unless row
    items = @line_items.where(order_id: id).all
    OrderBuilder.build(row.merge(items: items))
  end
end
```

No branching in the gateway. Adding a new state means a new domain class and one new entry in `CONSTRUCTORS`.

### The use case

The use case has no knowledge of order states. It loads the domain object and asks it to render itself:

```ruby
class ViewOrder
  def initialize(order_gateway:)
    @order_gateway = order_gateway
  end

  def execute(order_id:, presenter:)
    order = @order_gateway.find_by_id(order_id)
    return presenter.not_found unless order
    order.render_to(presenter)
  end
end
```

No branching. The use case is completely insulated from the fact that three order states exist.

### The delivery mechanism

The controller self-shunts as the presenter. Each outcome is a named method — the `show` action itself contains no conditionals:

```ruby
class OrdersController < ApplicationController
  def show
    view_order.execute(order_id: params[:id].to_i, presenter: self)
  end

  def pending(id:, items:)
    render :pending, locals: { id: id, items: items }
  end

  def confirmed(id:, items:, confirmed_at:)
    render :confirmed, locals: { id: id, items: items, confirmed_at: confirmed_at }
  end

  def dispatched(id:, items:, tracking_number:)
    render :dispatched, locals: { id: id, items: items, tracking_number: tracking_number }
  end

  def not_found
    render :not_found, status: :not_found
  end
end
```

Adding a fourth state — say `CancelledOrder` — requires: a new domain class, one line in `OrderBuilder::CONSTRUCTORS`, and one new method on the controller. The gateway, the use case, the `show` action, and all other controller methods are untouched.

## Separate presenter objects

When the presentation logic itself is complex or needs to be shared across controllers, extract it into a dedicated presenter object rather than shunting into the controller:

```ruby
class PlaceOrderPresenter
  attr_reader :redirect_to, :render_template, :alert

  def success(order_id:)
    @redirect_to = "/orders/#{order_id}"
  end

  def customer_not_found
    @redirect_to = '/login'
  end

  def no_items
    @render_template = :cart
    @alert = 'Your cart is empty'
  end

  def out_of_stock
    @render_template = :cart
    @alert = 'Some items are out of stock'
  end
end
```

The controller instantiates and interrogates the presenter:

```ruby
def create
  presenter = PlaceOrderPresenter.new
  place_order.execute(customer_id: current_user.id, items: params[:items], presenter: presenter)
  redirect_to presenter.redirect_to and return if presenter.redirect_to
  render presenter.render_template, alert: presenter.alert
end
```

## Testing with the presenter

In tests, use a double to assert which outcome was called:

```ruby
describe PlaceOrder do
  let(:presenter)          { double(:presenter) }
  let(:order_gateway)      { InMemoryOrderGateway.new }
  let(:customer_gateway)   { InMemoryCustomerGateway.new }
  let(:inventory_gateway)  { InMemoryInventoryGateway.new }

  subject do
    described_class.new(
      order_gateway: order_gateway,
      customer_gateway: customer_gateway,
      inventory_gateway: inventory_gateway
    )
  end

  context 'when items are available' do
    before { customer_gateway.save(id: 1) }
    before { inventory_gateway.mark_available('SKU-1') }

    it 'calls success with the order id' do
      expect(presenter).to receive(:success).with(order_id: anything)
      subject.execute(customer_id: 1, items: [{ sku: 'SKU-1' }], presenter: presenter)
    end
  end

  context 'when items are out of stock' do
    before { customer_gateway.save(id: 1) }
    before { inventory_gateway.mark_unavailable('SKU-1') }

    it 'calls out_of_stock' do
      expect(presenter).to receive(:out_of_stock)
      subject.execute(customer_id: 1, items: [{ sku: 'SKU-1' }], presenter: presenter)
    end
  end
end
```

## When to use a presenter

The hash return is simpler — prefer it unless you have a concrete reason to reach for a presenter. Good reasons include:

- The use case has several distinct outcome paths and the same branching is appearing in multiple callers
- Multiple callers handle outcomes in fundamentally different ways
- You want the compiler (in typed languages) to enforce that callers handle every outcome

A use case that returns `{ success: true }` or `{ success: false, errors: [...] }` does not need a presenter. A use case with four distinct outcomes handled differently across two delivery mechanisms probably does.

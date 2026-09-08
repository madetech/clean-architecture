---
title: Presenters are more flexible
---

# Presenters are more flexible

A Use Case that returns a hash is the correct default. A hash is simple, easy to test, and correct for most situations.

As a system grows, a Use Case collects more outcomes. Each new outcome forces every caller to branch on the result hash. The same `if` statement then appears across the code base. That duplication is a symptom of zero polymorphism.

## The zero polymorphism problem

Consider a Use Case that fails in several ways:

```ruby
class PlaceOrder
  def execute(customer_id:, items:)
    customer = @customer_gateway.find(customer_id)
    return { status: :customer_not_found } unless customer
    return { status: :no_items } if items.empty?
    return { status: :out_of_stock } unless @inventory_gateway.all_available?(items)

    order_id = @order_gateway.save(Order.new(customer_id: customer_id, items: items))
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

The same four-way branch appears in every Delivery Mechanism. Add a fifth outcome to the Use Case, and you must change every caller. That is zero polymorphism: repeated conditionals carry the variation instead of separate objects.

The same `if` can appear in all three layers. The Gateway reads a type to build the right data structure. The Use Case reads the type again to apply the right rule. The Delivery Mechanism reads the type a third time to render the right response. The [extend-with-domain](./extend-with-domain.md) guide removes the branch in the Gateway and the branch in the Use Case with polymorphic Domain objects. The presenter pattern removes the branch in the Delivery Mechanism.

## The presenter pattern

The Use Case accepts a presenter instead of returning a hash, and calls one named method for each outcome:

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

    order_id = @order_gateway.save(Order.new(customer_id: customer_id, items: items))
    presenter.success(order_id: order_id)
  end
end
```

Each caller writes its own version of the outcome methods. The branch disappears, and polymorphism takes its place.

## Self-shunting: the controller as the presenter

The simplest presenter is the controller itself. The controller passes `self` to the Use Case, and writes the outcome methods directly:

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

This pattern is called self-shunting. There is no extra object, because the controller is the presenter. Each outcome is a named method, not a branch inside `create`. A new outcome means a new method, not a change to an existing method.

The JSON API controller renders the same outcomes differently, and shares no code with the HTML controller:

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

The sections above cover the Delivery Mechanism layer on its own. This example covers the full chain. The polymorphism that removes the branch in the Gateway and in the Use Case, which [extend-with-domain](./extend-with-domain.md) describes, reaches the Delivery Mechanism as well.

The example views an order in one of three states: pending, confirmed, or dispatched. Each state carries different data, and each state renders differently.

### The Domain objects

Each state is a separate class that exposes only the data of that state. A Domain object knows nothing about a presenter:

```ruby
class PendingOrder
  attr_reader :id, :items

  def initialize(id:, items:)
    @id = id
    @items = items
  end
end

class ConfirmedOrder
  attr_reader :id, :items, :confirmed_at

  def initialize(id:, items:, confirmed_at:)
    @id = id
    @items = items
    @confirmed_at = confirmed_at
  end
end

class DispatchedOrder
  attr_reader :id, :items, :tracking_number

  def initialize(id:, items:, tracking_number:)
    @id = id
    @items = items
    @tracking_number = tracking_number
  end
end
```

`DispatchedOrder` exposes a `tracking_number`. `PendingOrder` does not. Each type exposes only the data that the type holds.

### The Gateway and builder

The Gateway reads the `status` column and calls a builder to construct the Domain object. [extend-with-domain](./extend-with-domain.md) gives the full reason. A constructor lambda passes the parameters that each type needs:

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

The Gateway holds no branch. A new state means a new Domain class and one new entry in `CONSTRUCTORS`.

### The Use Case: three approaches

There are three ways to send a Domain object to a presenter. Each way makes a different trade-off.

#### Option A: delegate to the Domain object

Each Domain object gets a `present_to` method that calls the right presenter method with its own data:

```ruby
class PendingOrder
  # ...
  def present_to(presenter)
    presenter.pending(id: @id, items: @items)
  end
end

class ConfirmedOrder
  # ...
  def present_to(presenter)
    presenter.confirmed(id: @id, items: @items, confirmed_at: @confirmed_at)
  end
end

class DispatchedOrder
  # ...
  def present_to(presenter)
    presenter.dispatched(id: @id, items: @items, tracking_number: @tracking_number)
  end
end
```

The Use Case delegates:

```ruby
def execute(order_id:, presenter:)
  order = @order_gateway.find_by_id(order_id)
  return presenter.not_found unless order
  order.present_to(presenter)
end
```

**Pros:** Open for extension and closed for modification. A new state needs only a new class with a `present_to` method. The Use Case never changes. The dispatch is fully polymorphic, and there is no lookup table to maintain.

**Cons:** The Domain object learns a presenter interface that belongs to one Use Case. When several Use Cases with different presenter interfaces read `PendingOrder`, `PendingOrder` must either write one `present_to_*` method per interface, or choose one interface. Presenter method names enter the vocabulary of the domain.

#### Option B: lookup hash in the Use Case

The Domain objects stay as data. The Use Case owns a `PRESENT` table keyed on the Domain class:

```ruby
class ViewOrder
  PRESENT = {
    PendingOrder    => ->(order, p) { p.pending(id: order.id, items: order.items) },
    ConfirmedOrder  => ->(order, p) { p.confirmed(id: order.id, items: order.items, confirmed_at: order.confirmed_at) },
    DispatchedOrder => ->(order, p) { p.dispatched(id: order.id, items: order.items, tracking_number: order.tracking_number) }
  }.freeze

  def initialize(order_gateway:)
    @order_gateway = order_gateway
  end

  def execute(order_id:, presenter:)
    order = @order_gateway.find_by_id(order_id)
    return presenter.not_found unless order
    PRESENT.fetch(order.class).call(order, presenter)
  end
end
```

**Pros:** The Domain objects know nothing about any presenter. Each Use Case owns its own table, so the same Domain objects serve Use Cases with completely different presenter interfaces.

**Cons:** A new Domain class forces a change to the Use Case, so the Use Case is not closed for modification. A key of `order.class` is fragile: a class rename breaks the lookup with no error at the point of the rename, and a subclass is not found unless you add it. The Use Case knows every concrete type in the hierarchy.

#### Option C: strategy objects injected at build time

One strategy object per Domain type calls the right presenter methods. The builder injects the strategy into the Domain object at construction. The Domain object delegates `present_to` to the strategy, and knows only that it holds a strategy:

```ruby
class PendingOrderPresentationStrategy
  def present(order, presenter)
    presenter.pending(id: order.id, items: order.items)
  end
end

class ConfirmedOrderPresentationStrategy
  def present(order, presenter)
    presenter.confirmed(id: order.id, items: order.items, confirmed_at: order.confirmed_at)
  end
end

class DispatchedOrderPresentationStrategy
  def present(order, presenter)
    presenter.dispatched(id: order.id, items: order.items, tracking_number: order.tracking_number)
  end
end
```

Each Domain object holds the injected strategy:

```ruby
class PendingOrder
  attr_reader :id, :items

  def initialize(id:, items:, presentation_strategy:)
    @id = id
    @items = items
    @presentation_strategy = presentation_strategy
  end

  def present_to(presenter)
    @presentation_strategy.present(self, presenter)
  end
end
```

The builder passes the right strategy into each constructor lambda:

```ruby
class OrderBuilder
  CONSTRUCTORS = {
    'pending'    => ->(row) { PendingOrder.new(id: row[:id], items: row[:items], presentation_strategy: PendingOrderPresentationStrategy.new) },
    'confirmed'  => ->(row) { ConfirmedOrder.new(id: row[:id], items: row[:items], confirmed_at: row[:confirmed_at], presentation_strategy: ConfirmedOrderPresentationStrategy.new) },
    'dispatched' => ->(row) { DispatchedOrder.new(id: row[:id], items: row[:items], tracking_number: row[:tracking_number], presentation_strategy: DispatchedOrderPresentationStrategy.new) }
  }.freeze

  def self.build(row)
    constructor = CONSTRUCTORS.fetch(row[:status], CONSTRUCTORS['pending'])
    constructor.call(row)
  end
end
```

The Use Case is the same as in Option A. The Use Case calls `present_to`:

```ruby
def execute(order_id:, presenter:)
  order = @order_gateway.find_by_id(order_id)
  return presenter.not_found unless order
  order.present_to(presenter)
end
```

**Pros:** The Use Case is closed for modification, and never changes when you add a type. A Domain object knows no presenter interface, and knows only that it holds a strategy. Different Use Cases inject different strategies for the same Domain type, which gives full flexibility with no coupling. There is no `.class` lookup.

**Cons:** More parts: one strategy class per type, strategy injection in the builder, and a `present_to` method on every Domain object. The extra indirection is harder to follow.

**When the extra parts are worth it:** Strategy injection is worth it when the aggregate root Domain objects form a deep hierarchy. For example, an `Order` holds `LineItem` objects, and each `LineItem` is itself polymorphic as `PhysicalItem`, `DigitalItem` or `SubscriptionItem`, and each one renders differently. One strategy walks that whole object graph and presents it, and the Domain objects and the Use Case hold no presentation code. For a flat Domain object, Option A or Option B is enough.

### The Delivery Mechanism

The controller self-shunts as the presenter. Each outcome is a named method, and the `show` action holds no conditional:

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

A fourth state, such as `CancelledOrder`, needs a new Domain class, one line in `OrderBuilder::CONSTRUCTORS`, and one new method on the controller. The Gateway, the Use Case, the `show` action and the other controller methods need no change.

## Separate presenter objects

When the presentation code is complex, or when several controllers share it, write a separate presenter object instead of self-shunting:

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

The controller constructs the presenter, then reads the presenter:

```ruby
def create
  presenter = PlaceOrderPresenter.new
  place_order.execute(customer_id: current_user.id, items: params[:items], presenter: presenter)
  redirect_to presenter.redirect_to and return if presenter.redirect_to
  render presenter.render_template, alert: presenter.alert
end
```

## Testing with the presenter

In a test, use a double to check which outcome the Use Case called:

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
    before { customer_gateway.save(Customer.new(id: 1)) }
    before { inventory_gateway.mark_available('SKU-1') }

    it 'calls success with the order id' do
      expect(presenter).to receive(:success).with(order_id: anything)
      subject.execute(customer_id: 1, items: [{ sku: 'SKU-1' }], presenter: presenter)
    end
  end

  context 'when items are out of stock' do
    before { customer_gateway.save(Customer.new(id: 1)) }
    before { inventory_gateway.mark_unavailable('SKU-1') }

    it 'calls out_of_stock' do
      expect(presenter).to receive(:out_of_stock)
      subject.execute(customer_id: 1, items: [{ sku: 'SKU-1' }], presenter: presenter)
    end
  end
end
```

## When to use a presenter

A hash return is simpler. Use a hash unless you have one of these reasons for a presenter:

- The Use Case has several distinct outcomes, and the same branch appears in more than one caller
- Two or more callers render the outcomes in completely different ways
- You want the compiler, in a typed language, to require every caller to cover every outcome

A Use Case that returns `{ success: true }` or `{ success: false, errors: [...] }` does not need a presenter. A Use Case with four distinct outcomes, rendered differently by two Delivery Mechanisms, does.

# Extracting a Use Case from a Use Case

A use case should do one thing. As systems grow, what started as one thing often quietly becomes two or three. The tell is length — and the feeling that testing this use case requires setting up far too much.

## The smell

```ruby
class PlaceOrder
  def initialize(order_gateway:, customer_gateway:, mailer:, inventory_gateway:)
    @order_gateway = order_gateway
    @customer_gateway = customer_gateway
    @mailer = mailer
    @inventory_gateway = inventory_gateway
  end

  def execute(customer_id:, items:)
    order_id = @order_gateway.save(customer_id: customer_id, items: items)

    customer = @customer_gateway.find(customer_id)
    @mailer.send_confirmation(to: customer[:email], order_id: order_id)

    items.each do |item|
      @inventory_gateway.decrement(sku: item[:sku], quantity: item[:quantity])
    end

    { order_id: order_id }
  end
end
```

`PlaceOrder` has four dependencies and is doing three distinct things: saving the order, sending a confirmation, and updating inventory. To test it in isolation you must arrange four collaborators. A change to how notifications are sent requires touching an order use case.

## Extracting collaborator use cases

Pull each concern into its own use case:

```ruby
class NotifyOrderPlaced
  def initialize(customer_gateway:, mailer:)
    @customer_gateway = customer_gateway
    @mailer = mailer
  end

  def execute(customer_id:, order_id:)
    customer = @customer_gateway.find(customer_id)
    @mailer.send_confirmation(to: customer[:email], order_id: order_id)
    {}
  end
end
```

```ruby
class ReserveInventory
  def initialize(inventory_gateway:)
    @inventory_gateway = inventory_gateway
  end

  def execute(items:)
    items.each do |item|
      @inventory_gateway.decrement(sku: item[:sku], quantity: item[:quantity])
    end
    {}
  end
end
```

`PlaceOrder` becomes an orchestrator, with the extracted use cases injected as collaborators — exactly like gateways:

```ruby
class PlaceOrder
  def initialize(order_gateway:, notify_order_placed:, reserve_inventory:)
    @order_gateway = order_gateway
    @notify_order_placed = notify_order_placed
    @reserve_inventory = reserve_inventory
  end

  def execute(customer_id:, items:)
    order_id = @order_gateway.save(customer_id: customer_id, items: items)
    @notify_order_placed.execute(customer_id: customer_id, order_id: order_id)
    @reserve_inventory.execute(items: items)
    { order_id: order_id }
  end
end
```

## When extraction makes sense

Extraction is worthwhile when:

- **The extracted use case needs to be called directly** by a delivery mechanism or API in its own right. If `ReserveInventory` can also be triggered by a warehouse management interface, it earns its own existence as a first-class use case.
- **The code is genuinely too complicated** to reason about or test as one unit. Four dependencies and fifty lines is a signal worth acting on.

## The downsides

Extraction is not a panacea. It comes with real costs:

**Sharing information between use cases becomes harder.** When logic lives in one use case, intermediate values computed early can be used later. Once you split across use cases, each invocation starts fresh. You end up passing more data through the interface, or reading data a second time that you have already read.

**More database calls.** Domain objects cannot be shared across use case boundaries without breaking the architectural philosophy — a domain object that escapes a use case is a leaked internal (see [Don't leak your internals](../basics/do-not-leak-your-internals.md)). This means each extracted use case may reload data the orchestrating use case already has. In the example above, if `NotifyOrderPlaced` needs order details that `PlaceOrder` already computed, it must fetch them again.

Apply extraction when the benefits — reusability, testability, separation of concerns — outweigh these costs. Not every large use case needs to be split.

## Testing each piece independently

Each use case can be tested with stub collaborators rather than a full wiring:

```ruby
describe PlaceOrder do
  let(:order_gateway)       { instance_double(InMemoryOrderGateway, save: 42) }
  let(:notify_order_placed) { double(:notify_order_placed, execute: {}) }
  let(:reserve_inventory)   { double(:reserve_inventory, execute: {}) }

  subject do
    PlaceOrder.new(
      order_gateway: order_gateway,
      notify_order_placed: notify_order_placed,
      reserve_inventory: reserve_inventory
    )
  end

  it 'returns the order id' do
    result = subject.execute(customer_id: 1, items: [])
    expect(result[:order_id]).to eq(42)
  end

  it 'notifies that the order was placed' do
    subject.execute(customer_id: 1, items: [])
    expect(notify_order_placed).to have_received(:execute).with(customer_id: 1, order_id: 42)
  end
end
```

`NotifyOrderPlaced` and `ReserveInventory` each get their own focused test with only the collaborators they actually need.

## Wiring it together

In your [dependency factory](./keep-your-wiring-DRY.md), compose the use cases. Use a lookup hash rather than a case statement — adding a new use case means adding an entry, not modifying a branch:

```ruby
def use_cases
  {
    place_order: -> {
      PlaceOrder.new(
        order_gateway: order_gateway,
        notify_order_placed: get_use_case(:notify_order_placed),
        reserve_inventory: get_use_case(:reserve_inventory)
      )
    },
    notify_order_placed: -> {
      NotifyOrderPlaced.new(customer_gateway: customer_gateway, mailer: mailer)
    },
    reserve_inventory: -> {
      ReserveInventory.new(inventory_gateway: inventory_gateway)
    }
  }
end

def get_use_case(name)
  use_cases.fetch(name).call
end
```

Each use case remains individually accessible — `notify_order_placed` can be triggered by other use cases or delivery mechanisms without duplication.

## An alternative: the event publisher

Direct injection of collaborator use cases means `PlaceOrder` must know the names of every downstream use case it triggers. Adding `UpdateLoyaltyPoints` as a new consequence of placing an order means changing `PlaceOrder`.

An event publisher inverts this. `PlaceOrder` publishes a signal; downstream use cases subscribe to it. `PlaceOrder` no longer knows what cares about its outcome.

```ruby
class PlaceOrder
  def initialize(order_gateway:, event_publisher:)
    @order_gateway = order_gateway
    @event_publisher = event_publisher
  end

  def execute(customer_id:, items:)
    order_id = @order_gateway.save(customer_id: customer_id, items: items)
    @event_publisher.publish(:order_placed, customer_id: customer_id, order_id: order_id, items: items)
    { order_id: order_id }
  end
end
```

The publisher calls each subscriber in turn, synchronously:

```ruby
class EventPublisher
  def initialize
    @subscribers = Hash.new { |h, k| h[k] = [] }
  end

  def subscribe(event, use_case)
    @subscribers[event] << use_case
    self
  end

  def publish(event, payload)
    @subscribers[event].each { |use_case| use_case.execute(**payload) }
  end
end
```

Subscriptions are wired up in the [dependency factory](./keep-your-wiring-DRY.md):

```ruby
def event_publisher
  @event_publisher ||= EventPublisher.new
    .subscribe(:order_placed, get_use_case(:notify_order_placed))
    .subscribe(:order_placed, get_use_case(:reserve_inventory))
end
```

Adding `UpdateLoyaltyPoints` as a new subscriber requires one new line in the factory. `PlaceOrder` is untouched.

The same downsides around database calls and information sharing apply — each subscriber starts fresh and may re-read data. But the coupling between `PlaceOrder` and its downstream consequences is eliminated entirely.

## From the trenches

Extracted use cases are easier to replace. If notification sending moves to a background queue, only `NotifyOrderPlaced` changes — as long as the new implementation still responds to `execute`. With an event publisher, that swap happens in the factory without touching any use case at all.

---
title: Extracting a Use Case from a Use Case
---

# Extracting a Use Case from a Use Case

A Use Case does one thing. As a system grows, one thing becomes two or three. Two signs tell you that this has happened: the Use Case is long, and a test of the Use Case needs a large amount of setup.

## The problem

```ruby
class PlaceOrder
  def initialize(order_gateway:, customer_gateway:, mailer:, inventory_gateway:)
    @order_gateway = order_gateway
    @customer_gateway = customer_gateway
    @mailer = mailer
    @inventory_gateway = inventory_gateway
  end

  def execute(customer_id:, items:)
    order_id = @order_gateway.save(Order.new(customer_id: customer_id, items: items))

    customer = @customer_gateway.find(customer_id)
    @mailer.send_confirmation(to: customer.email, order_id: order_id)

    items.each do |item|
      stock = @inventory_gateway.find_by_sku(item[:sku])
      stock.reserve(item[:quantity])
      @inventory_gateway.save(stock)
    end

    { order_id: order_id }
  end
end
```

`PlaceOrder` has four dependencies and does three separate things: `PlaceOrder` saves the order, sends a confirmation, and updates the inventory. A test of `PlaceOrder` must arrange four collaborators. A change to the way the system sends a notification forces a change to an order Use Case.

## Extracting collaborator Use Cases

Move each concern into its own Use Case:

```ruby
class NotifyOrderPlaced
  def initialize(customer_gateway:, mailer:)
    @customer_gateway = customer_gateway
    @mailer = mailer
  end

  def execute(customer_id:, order_id:)
    customer = @customer_gateway.find(customer_id)
    @mailer.send_confirmation(to: customer.email, order_id: order_id)
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
      stock = @inventory_gateway.find_by_sku(item[:sku])
      stock.reserve(item[:quantity])
      @inventory_gateway.save(stock)
    end
    {}
  end
end
```

`PlaceOrder` becomes an orchestrator. The extracted Use Cases arrive as collaborators, in the same way that a Gateway arrives as a collaborator:

```ruby
class PlaceOrder
  def initialize(order_gateway:, notify_order_placed:, reserve_inventory:)
    @order_gateway = order_gateway
    @notify_order_placed = notify_order_placed
    @reserve_inventory = reserve_inventory
  end

  def execute(customer_id:, items:)
    order_id = @order_gateway.save(Order.new(customer_id: customer_id, items: items))
    @notify_order_placed.execute(customer_id: customer_id, order_id: order_id)
    @reserve_inventory.execute(items: items)
    { order_id: order_id }
  end
end
```

## When extraction makes sense

Extract a Use Case when one of these is true:

- **A Delivery Mechanism or an API needs to call the extracted Use Case directly.** A warehouse management interface that triggers `ReserveInventory` makes `ReserveInventory` a Use Case in its own right.
- **The code is too complicated to read or to test as one unit.** Four dependencies and fifty lines is enough to act on.

## The costs

Extraction is not free. Extraction has two costs.

**Sharing data between Use Cases becomes harder.** One Use Case can compute a value early and read that value later. Two Use Cases cannot. Each call starts again, so you pass more data through the interface, or you read the same data a second time.

**The system makes more database calls.** A Domain object must not cross a Use Case boundary, because a Domain object that leaves a Use Case is a leaked internal. See [Do not leak your internals](../basics/do-not-leak-your-internals.md). Each extracted Use Case therefore reloads data that the orchestrating Use Case already holds. In the example above, `NotifyOrderPlaced` reads the order details again if it needs them.

Extract a Use Case when the benefits, which are reuse, testability and separation of concerns, are worth these two costs. Not every large Use Case needs a split.

## Testing each piece independently

Test each Use Case with stub collaborators instead of the full wiring:

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

`NotifyOrderPlaced` and `ReserveInventory` each get their own test, with only the collaborators that each one needs.

## Wiring it together

Compose the Use Cases in your [dependency factory](./keep-your-wiring-DRY.md). Use a lookup hash instead of a case statement. A new Use Case then means a new entry, not a change to an existing branch:

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

Each Use Case stays available on its own. Another Use Case or another Delivery Mechanism calls `notify_order_placed` without any duplication.

## An alternative: the event publisher

When you inject collaborator Use Cases directly, `PlaceOrder` knows the name of every downstream Use Case. Adding `UpdateLoyaltyPoints` as a new consequence of placing an order forces a change to `PlaceOrder`.

An event publisher inverts that dependency. `PlaceOrder` publishes an event. Each downstream Use Case subscribes to the event. `PlaceOrder` then knows nothing about what reacts to its outcome.

```ruby
class PlaceOrder
  def initialize(order_gateway:, event_publisher:)
    @order_gateway = order_gateway
    @event_publisher = event_publisher
  end

  def execute(customer_id:, items:)
    order_id = @order_gateway.save(Order.new(customer_id: customer_id, items: items))
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

Wire the subscriptions in the [dependency factory](./keep-your-wiring-DRY.md):

```ruby
def event_publisher
  @event_publisher ||= EventPublisher.new
    .subscribe(:order_placed, get_use_case(:notify_order_placed))
    .subscribe(:order_placed, get_use_case(:reserve_inventory))
end
```

Adding `UpdateLoyaltyPoints` as a new subscriber takes one new line in the factory. `PlaceOrder` needs no change.

The two costs above still apply. Each subscriber starts again and can read the same data twice. The coupling between `PlaceOrder` and its downstream Use Cases is gone.

## In practice

An extracted Use Case is easier to replace. When notification sending moves to a background queue, only `NotifyOrderPlaced` changes, as long as the new implementation still responds to `execute`. With an event publisher, that swap happens in the factory, and no Use Case changes at all.

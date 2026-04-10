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

## Testing each piece independently

Each use case can now be tested with stub collaborators rather than a full wiring:

```ruby
describe PlaceOrder do
  let(:order_gateway)      { instance_double(InMemoryOrderGateway, save: 42) }
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

In your [dependency factory](./keep-your-wiring-DRY.md), compose the use cases:

```ruby
def get_use_case(name)
  case name
  when :place_order
    PlaceOrder.new(
      order_gateway: order_gateway,
      notify_order_placed: get_use_case(:notify_order_placed),
      reserve_inventory: get_use_case(:reserve_inventory)
    )
  when :notify_order_placed
    NotifyOrderPlaced.new(customer_gateway: customer_gateway, mailer: mailer)
  when :reserve_inventory
    ReserveInventory.new(inventory_gateway: inventory_gateway)
  end
end
```

Each use case remains individually accessible — `notify_order_placed` can be triggered by other use cases in the future without duplication.

## From the trenches

Extracted use cases are also easier to replace. If notification sending moves to a background queue, only `NotifyOrderPlaced` changes. `PlaceOrder` and its tests are untouched — as long as the new implementation still responds to `execute`.

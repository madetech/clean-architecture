# Gateway

The responsibility of a gateway is to adapt an IO mechanism for your [Use Cases](use_case.md).

Usually, a gateway will be the adapter between a data source (e.g. Postgresql) and a particular [Domain](domain.md) object (e.g. Order)

In Object-Oriented languages a gateways are usually a class which implements an interface.

IO is could be anything external to your application e.g. files, database or even HTTP API calls

It is the responsibility of Gateways to (one or more of):

* Construct Domain objects by reading from the I/O source
* Accept Domain objects to be written to the I/O source

Gateways are I/O source specific e.g. ActiveRecord, Sequel, MySQL, Paypal, FileSystem, RethinkDB

## The interface of a Gateway

The interface a Gateway exposes to Use Cases is expressed in [Domain](domain.md) objects:

* Methods that read return Domain objects, or collections of them — never rows, hashes or ORM records
* Methods that write accept Domain objects

The exception is the arguments used to *identify* what to read or delete e.g. `find_by_id(id)`, `find_by_email(email)`, a page number, or a date range. These are values used to locate data, not Domain objects, and passing them is fine.

Avoid gateway methods that accept a bag of attributes:

```ruby
# Don't do this
order_gateway.save(customer_id: 3, items: [{sku: '19283', quantity: 2}])

# Do this
order_gateway.save(Order.new(customer_id: 3, items: [LineItem.new(sku: '19283', quantity: 2)]))
```

Spreading the attributes of an Order across a gateway call means every Use Case that saves one has to know how an Order is assembled. Change the shape of an Order and every one of those call sites changes with it. It also leaves the Domain object with nowhere to grow behaviour — there is no `Order` to put it on.

For the same reason, prefer `save(order)` over a separate `update(id, attributes)`. A Domain object that already carries an identity is an update; one that does not is an insert. The Use Case reads, mutates and saves the Domain object:

```ruby
order = order_gateway.find_by_id(order_id)
order.cancel
order_gateway.save(order)
```

Returning a Domain object from a write is optional — returning the assigned id is common and enough for most Use Cases.

# Gateway

A Gateway adapts an IO mechanism for your [Use Cases](use_case.md).

A Gateway is usually the adapter between a data source, such as PostgreSQL, and one [Domain](domain.md) object, such as `Order`.

In an object-oriented language a Gateway is a class that implements an interface.

IO is anything outside your application, such as a file, a database, or an HTTP API call.

A Gateway does one or both of these:

* A Gateway constructs Domain objects by reading from the IO source.
* A Gateway accepts Domain objects and writes them to the IO source.

Each Gateway is specific to one IO source, such as ActiveRecord, Sequel, MySQL, PayPal, the file system, or RethinkDB.

## The interface of a Gateway

A Gateway exposes an interface to Use Cases in [Domain](domain.md) objects:

* A read method returns a Domain object, or a collection of Domain objects. A read method never returns a row, a hash, or an ORM record.
* A write method accepts a Domain object.

An identifier is the exception. A Use Case passes an identifier to say which record to read or delete, such as `find_by_id(id)`, `find_by_email(email)`, a page number, or a date range. An identifier locates data. An identifier is not a Domain object, and a Use Case passes an identifier without breaking the rule.

Do not write a Gateway method that accepts a bag of attributes:

```ruby
# Wrong
order_gateway.save(customer_id: 3, items: [{sku: '19283', quantity: 2}])

# Correct
order_gateway.save(Order.new(customer_id: 3, items: [LineItem.new(sku: '19283', quantity: 2)]))
```

A bag of attributes spreads the shape of an `Order` across every Use Case that saves one. Change the shape of an `Order`, and every one of those call sites changes too. A bag of attributes also leaves no `Order` object to hold new behaviour.

For the same reason, write `save(order)` instead of a separate `update(id, attributes)`. A Domain object that carries an identity is an update. A Domain object without an identity is an insert. The Use Case reads the Domain object, changes the Domain object, and saves the Domain object:

```ruby
order = order_gateway.find_by_id(order_id)
order.cancel
order_gateway.save(order)
```

A write method can return the assigned id. Most Use Cases need nothing more. A write method does not need to return a Domain object.

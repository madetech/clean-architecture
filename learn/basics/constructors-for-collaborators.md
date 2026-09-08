---
title: Constructors are for collaborators
---

# Constructors for collaborators

Consider a Use Case class, such as the following:

```ruby
class CreateOrder
  def initialize(...)
  end

  def execute(...)
  end
end
```

Which parameter belongs on the initializer, which is the constructor, and which parameter belongs on the `execute` method?

## A non-reentrant example

A common design passes everything to the constructor.

Assume a Clean Architecture design, and assume Rails for familiarity. A controller then looks like this:

```ruby
class OrderController < ApplicationController
  def create 
    order_gateway = ActiveRecordOrderGateway.new(Order)
    CreateOrder.new(order_gateway, create_order_request).execute
  end
end
```

This design has one downside. The call site of `.execute` must hold a reference to the Gateway and a reference to the request.

The next example shows why that is a problem.

## A reentrant example

Pass the request at the `.execute` call site, and pass the Gateway to the constructor.

Consider the following controller:

```ruby
class OrderController < ApplicationController
  def create
    @create_order.execute(create_order_request)
  end
end
```

This design separates the construction of your objects from the use of your objects.

The controller now knows nothing about the `order_gateway` dependency.

This is the interface segregation principle at work.

## An alternative

You could make `order_gateway` an instance variable instead:

```ruby
class OrderController < ApplicationController
  def create 
    CreateOrder.new(@order_gateway, create_order_request).execute
  end
end
```

That design reuses more code than the first example.

That design still has two downsides:

- The controller holds a source code dependency on the `CreateOrder` class constant. This breaks the dependency inversion principle.
- The controller knows about the `@order_gateway` dependency, and the controller does not need that knowledge. This breaks the interface segregation principle.

Both downsides make `OrderController` harder to unit test.

## Sinatra

Assume Sinatra instead of Rails, and consider the following code:

```ruby
post '/add-user' do
  controller = Controllers::AddUser.new(
    add_user: @dependency_factory.get_use_case(:add_user)
  )
  controller.execute(params, request_hash, response)
end
```

This code builds an MVC structure without Rails. The code binds a controller to the route `/add-user`.

The controller declares its dependencies as constructor parameters. 

The route passes every request parameter to the `.execute` method.

The controller is now isolated from Sinatra. You can unit test the controller without the framework, and without the business rules.

## Conclusion

Put collaborators, which are the dependencies, on the constructor only. Construction then stays separate from the use of the object.

That separation decouples parts of your system, makes each part easier to test, and lets you compose the parts in different ways.

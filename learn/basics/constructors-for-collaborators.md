# Constructors for collaborators

Consider a use case class, such as the following:

```ruby
class CreateOrder
  def initialize(...)
  end

  def execute(...)
  end
end
```

What should be a parameter for the initializer (the constructor) and what should be a parameter for the execute method?

## A non-reentrant example

A fairly typical design is to pass everything to the constructor.

Lets also assume a Clean Architecture design, and for familiarity that we are using Rails, and see what it looks like in a controller...

```ruby
class OrderController < ApplicationController
  def create 
    order_gateway = ActiveRecordOrderGateway.new(Order)
    CreateOrder.new(order_gateway, create_order_request).execute
  end
end
```

This has one particular downside in that you must have both a reference to the gateway and the request at the callsite to `.execute`.

To understand why this is an issue, lets look at a reentrant example.

## A reentrant example

We pass the request at the `.execute` callsite, and pass the gateway to the constructor.

Consider the following controller...

```ruby
class OrderController < ApplicationController
  def create
    @create_order.execute(create_order_request)
  end
end
```

What this has enabled us to do is separate the construction of our objects, from the usage of the object.

To say this another way, we can write controllers that are entirely unaware of the `order_gateway` dependency.

This is the interface segregation principle at work.

## But...

I could just make `order_gateway` an instance variable? Like this...

```ruby
class OrderController < ApplicationController
  def create 
    CreateOrder.new(@order_gateway, create_order_request).execute
  end
end
```

Yes you could. And this is certainly better, in terms of code reuse.

There are two downsides

- There is a source code dependency on the `CreateOrder` class constant. (Dependency Inversion Principle violation)
- Knowledge of an unnecessary dependency `@order_gateway`. (Interface Segregation Principle violation) 

Both of these facts make it harder to unit test this `OrderController`.

## Sinatra

Lets assume we're using Sinatra for a moment and lets consider the following code...

```ruby
post '/add-user' do
  controller = Controllers::AddUser.new(
    add_user: @dependency_factory.get_use_case(:add_user)
  )
  controller.execute(params, request_hash, response)
end
```

We have created an MVC structure without Rails. We have a Controller, bound to a route `/add-user`.

This controller has explicit dependencies, passed in via the constructor parameters. 

All request parameters are passed in via parameters to the `.execute` method.

This controller is now isolated from Sinatra - we can unit test it without the framework, and without the business rules.

## Conclusion

By making constructors for collaborators only (Dependencies), we are able to seperate construction from the usage of objects. 

This fact makes it easier to decouple aspects of your system for easier testing, and have the flexibility to compose them.


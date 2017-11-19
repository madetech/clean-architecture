# Use Case

The purpose of a use case is to serve a user's use case of the system. For example, "turn light on" or "send email to tenant".

In code, the entry point of a Use Case is a class that has one public method.

```ruby
class TurnLightOn
  def initialize(light_gateway:)
    @light_gateway = light_gateway
  end
  
  def execute(light_id:)
    @light_gateway.turn_on(light_id)
    {}
  end
end
```

This is a simple example, but it only considers the happy path.

Validation should also be handled by the Use Case too:

```ruby
class TurnLightOn
  def initialize(light_gateway:)
    @light_gateway = light_gateway
  end
  
  def execute(light_id:)
    light = @light_gateway.find(light_id)
    
    return light_not_found if light.nil?
    
    light.turn_on
    
    {
      success: true,
      errors: []
    }
  end
  
  private
  
  def light_not_found
    {
      success: false,
      errors: [:light_not_found]
    }
  end
end
```

As you can imagine, depending on the system there may be more complexity needed to service the TurnLightOn use case.

Use Cases can also use the presenter pattern:

```ruby
class TurnLightOn
  def initialize(light_gateway:)
    @light_gateway = light_gateway
  end
  
  def execute(light_id:, presenter:)
    @presenter = presenter
    light = @light_gateway.find(light_id)
    
    light_not_found and return if light.nil?
    
    turn_light_on(light)
    nil
  end
  
  private
  
  def turn_light_on(light)
    light.turn_on
    @presenter.success
  end
  
  def light_not_found
    @presenter.failure([:light_not_found])
  end
end
```

In this example, the Use Case is not aware of the implementation details of the lighting system, nor how the user is accessing the use case or seeing the errors presented to them. That is handled by the Gateway and the Delivery Mechanism respectively.

It's not hard to imagine this being called by a button with a red error light, nor is it hard to imagine it used by an iOS application with TouchID activation. 

## Properties of Use Cases

* Each use case should be Framework and Database agnostic. 
* Use Cases define an interface (implicit in Ruby) that must be fulfilled by a Gateway
* Use Cases expose a request, response interface which are defined as simple data structures (Hashes or Structs)
  * In the Presenter pattern the Responses should always be simple data structures.

## Alternative names

* In Ivar Jacobson's BCE architecture these are the "Controls".
* Martin Fowler has a concept called "Transaction Scripts".
* In Uncle Bob's terminology these are "Interactors".
* "Operations"
* "Commands"

In Made Tech Flavour Clean Architecture we stick to the name "UseCase"

# Use Case

A Use Case serves one task that a user asks the system to do. Examples are "turn light on" and "send email to tenant".

In code, a Use Case is a class with one public method.

```ruby
class TurnLightOn
  def initialize(light_gateway:)
    @light_gateway = light_gateway
  end
  
  def execute(light_id:)
    light = @light_gateway.find(light_id)
    light.turn_on
    @light_gateway.save(light)
    {}
  end
end
```

That example covers the success path only.

A Use Case also validates its input:

```ruby
class TurnLightOn
  def initialize(light_gateway:)
    @light_gateway = light_gateway
  end
  
  def execute(light_id:)
    light = @light_gateway.find(light_id)
    
    return light_not_found if light.nil?
    
    light.turn_on
    @light_gateway.save(light)
    
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

A real system usually needs more code than this to serve the `TurnLightOn` Use Case.

A Use Case can also use the presenter pattern:

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
    @light_gateway.save(light)
    @presenter.success
  end
  
  def light_not_found
    @presenter.failure([:light_not_found])
  end
end
```

In that example the Use Case does not know how the lighting system works. The Use Case also does not know how the user starts the Use Case, and does not know how the user reads the errors. The [Gateway](gateway.md) knows the lighting system. The [Delivery Mechanism](learn/basics/delivery-mechanism-101.md) knows the user.

A button with a red error light can call this Use Case. An iOS application with TouchID can call the same Use Case.

## Properties of Use Cases

* A Use Case does not depend on a framework or on a database.
* A Use Case defines an interface that a Gateway must fulfil. In Ruby that interface is implicit.
  * The interface is expressed in [Domain](domain.md) objects. A Gateway returns Domain objects, and a Gateway accepts Domain objects to save. See [Gateway](gateway.md).
* A Use Case exposes a request interface and a response interface. Both are simple data structures, such as a hash or a struct.
  * In the presenter pattern the response is always a simple data structure.

## Alternative names

* Ivar Jacobson's BCE architecture calls these "Controls".
* Martin Fowler describes a related idea called a "Transaction Script".
* Robert C. Martin calls these "Interactors".
* "Operations"
* "Commands"

Made Tech Flavour Clean Architecture uses the name "UseCase".

# Use Cases

Standard Directory: use_case/


Each use case should be Framework and Database agnostic. 
* They are aware of the interface of the Gateways and Domain objects
* They expose a request/response interface which are defined as simple data structures (Hashes or Structs)

## Alternative names

* In Ivar Jacobson's BCE architecture these are the "Controls"
* In Uncle Bob's terminology these are "Interactors".
* "Operations"
" "Commands"

In Made Tech Flavour Clean Architecture we stick to "UseCases"

## Libraries

* [Deject](https://github.com/JoshCheek/deject)

## Example

```ruby
module AcmeIndustries
  module Widget
    module UseCase
      class WidgetsPerFooBarReport
        Deject self, :widget_gateway
        
        def execute(from_date:, to_date:) # receive a hash
           # widgets is a collection of Domain::Widget objects
           widgets = widget_gateway.all

           # secret sauce here
           
           {} # return a hash
        end
      end
    end
  end
end
```


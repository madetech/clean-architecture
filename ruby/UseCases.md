# Use Cases

Standard Directory: use_case/

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


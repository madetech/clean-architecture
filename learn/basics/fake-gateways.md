# Fake Gateways

When building out Acceptance Tests, it is useful to use Fake [test doubles](https://learn.madetech.com/core-skills/tdd/test-doubles.html) to stand in for real gateways.

This gives you the ability to explore the domain, and the associated business rules with the customer while building real code.

Once you understand the domain, you can then make an informed decision about technology choices for persistence.

## Simplistic Gateway

Using an array as a backing store, a lot of early gateways can follow this pattern. 

```ruby
class InMemoryOrder
  def initialize
    @orders = []
  end
  
  def find_by(id)
    @orders[id]
  end

  def all
    @orders
  end
  
  def save(order)
    @orders << order
    @orders.length - 1
  end
end
```


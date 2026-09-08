---
title: Start with Acceptance Testing
---

# Start with Acceptance Testing


Start with acceptance testing before you write anything else. 
When you are unsure what to do next, read your acceptance tests and start from there.

This guide describes the A in [ATDD](https://en.wikipedia.org/wiki/Acceptance_test%E2%80%93driven_development), and uses ideas from [BDD](https://en.wikipedia.org/wiki/Behavior-driven_development).

## What is an acceptance test?

An acceptance test is a high-level test. An acceptance test takes the perspective of the user, describes the steps through the system, and states the expectation at each step.

BDD describes the behaviour of the system like this: 

```cucumber
Given the light is off
When I turn the light on
Then the light is on
```

Here is the same Cucumber script written as RSpec Ruby:

```ruby
describe 'lighting' do
  let(:system) { LightingSystem.new }
  let(:create_light_use_case) { system.get_use_case(:create_light) }
  let(:turn_light_on_use_case) { system.get_use_case(:turn_light_on) }
  let(:view_light_status_use_case) { system.get_use_case(:view_light_status) }
  
  let(:light_id) do
    response = create_light_use_case.execute
    response[:id]
  end
  
  let(:view_light_status_response) do
    view_light_status_use_case.execute(light_id: light_id)
  end
  
  context 'given the light is off' do
    it 'is off' do
      expect(view_light_status_response[:on]).to be(false)
    end
    
    context 'when I turn the light on' do
      before { turn_light_on_use_case.execute(light_id: light_id) } 
      
      it 'is on' do
        expect(view_light_status_response[:on]).to be(true)
      end
    end
  end
end
```

## Write acceptance tests first

Write a failing acceptance test before you write any other code.

Describe what the customer needs before you start work.

### The reasons

A failing acceptance test stops you from
* losing focus, 
* writing more code than the customer needs, and 
* reaching a state where the separate parts of the system do not work together

**Above all, an acceptance test states the goal before you start.**

### What should an acceptance test suite test?

A test has three parts: **Arrange**, **Act** and **Assert**. The sections below describe each part, in reverse order.

#### Assert

Run a Use Case, then check the response of that Use Case.

```ruby
it 'is off' do
  view_light_status_response = view_light_status.execute(
    light_id: light_id
  )
  expect(view_light_status_response[:on]).to be(false)
end

```

Your application may not be complete yet. As a shortcut, assert against a Gateway directly. The shortcut lets you take a small slice of the work at a time.

WARNING: An acceptance test coupled to a Gateway has three costs:

* The interface between Use Cases and Gateways becomes harder to refactor.
* The acceptance test sees the internals of your application, which are the Domain objects.
* The acceptance test changes more often.

##### In practice

More than one Use Case can know about the same Domain object. When several Use Cases know about the same Domain object, extract a factory or a builder that constructs the Domain object. Both the tests and the production code then call that factory. 

An acceptance test that never sees a Domain object needs no change when you refactor the API of that Domain object. With the right abstractions in place, one change to the unit test code is often enough.  


#### Act

The Act step of an acceptance test always calls the boundary of a Use Case.

```ruby
context 'when I turn the light on' do
  before { turn_light_on_use_case.execute(light_id: light_id) } 
end
```


##### In practice

WARNING: Do not specify the needs of your customer in an API test, such as a Rails feature spec. 

The single responsibility principle applies to acceptance tests as well as to production code.

An acceptance test coupled to your HTTP stack changes for technical reasons, not for domain reasons. For example, the test changes when the system sets a new cookie, or when a new version of a JavaScript library changes the request.

It is hard to concentrate on two problems at once. A developer who changes a test because of an HTTP header does not concentrate on the domain of the customer at the same time. 

That developer can leave a gap in the test suite without noticing. In a system of moderate complexity, that risk is high.

An acceptance test specifies the needs of the customer, and nothing else. 

Separate the concerns in your production code. Separate the concerns in your test code as well.

#### Arrange

The Arrange step is the hardest part of acceptance testing to learn. 

In the simplest case the Arrange step calls one or more Use Cases to put the system into the state you need. Aim for that.

That is not always possible.

Write your test setup so that it calls the system the same way the Delivery Mechanism calls the system.

## Code or a Domain Specific Language?

Gherkin (Cucumber and SpecFlow) and Fitnesse are common DSL choices for executable acceptance tests.

Use a DSL when stakeholders who do not program write or check the acceptance tests. Use code otherwise, and keep the code readable. 

```Gherkin
Feature: A customer places an order

Scenario: An existing customer places an order
Given an existing customer
And a valid UK billing address
And a valid UK shipping address
And wants to buy 1x sku 19283
When the order is placed
Then the order is viewable
And there is one line item
And there is valid UK shipping address
And there is a valid UK billing address
And there is a line item for 1x sku 19283 for 10.00 GBP
And the order total is 10.00 GBP
```

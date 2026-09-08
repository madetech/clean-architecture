---
title: TDD everything
---

# TDD everything

The [outer loop](./fake-gateways.md) describes the ATDD discipline: write a failing acceptance test, make the acceptance test pass, then repeat. The outer loop does not tell you how to write the production code between those two steps.

The inner loop tells you that.

## The inner loop

Enter the inner loop while your acceptance test fails:

1. Write a failing unit test
2. Watch the unit test fail for the right reason
3. Write the minimum production code that makes the unit test pass
4. Watch the unit test pass
5. Refactor
6. Run the acceptance test. If the acceptance test passes, return to the outer loop. If the acceptance test fails, return to step 1.

## The three rules

Three rules govern the inner loop:

1. You **must** write a failing test before you write any production code
2. You **must not** write more of a test than the amount that fails
3. You **must not** write more production code than the amount that makes the failing test pass

Rule 3 permits sliming, which means you return a hard-coded value to make a test pass. Sliming is not cheating. Sliming tells you that you do not yet have enough tests to justify the real implementation. Triangulation closes that gap.

## Triangulation

With a single test, you pass the test by hard-coding the expected value:

```ruby
def total_price(items)
  10.00
end
```

Write a second test with different input and a different expected output. The second test forces you to write the real implementation.

Generalise production code only when a failing test demands the generalisation.

## Arrange, Act, Assert, Teardown

Every unit test follows this structure:

- **Arrange** — set up the state the test needs
- **Act** — call the code under test
- **Assert** — check the outcome
- **Teardown** — clean up, which the test framework often does for you

Name each test after the behaviour of the software from the perspective of the user, not after the implementation. `"#execute"` is a poor test name. `"returns the order total including tax"` is a good one.

```ruby
describe 'placing an order' do
  context 'given a single item' do
    it 'returns the order id' do
      # Arrange
      order_gateway = InMemoryOrderGateway.new
      place_order = PlaceOrder.new(order_gateway: order_gateway)

      # Act
      response = place_order.execute(customer_id: 1, items: [{ sku: 'ABC', quantity: 1 }])

      # Assert
      expect(response[:order_id]).not_to be_nil
    end
  end
end
```

## Test doubles at the unit level

When you unit test a Use Case, inject a [Fake](./fake-gateways.md) in place of the real Gateway. The Fake keeps the test fast, and keeps the test directed at the behaviour of the Use Case.

The five types of test double are Dummy, Stub, Fake, Spy and True Mock. At the Use Case level, use a Fake most often. A Fake is a working implementation with shortcuts, such as an in-memory store instead of a database. Use a Stub for a simpler case where you only need to control a return value.

Use as few test doubles as possible in one test. A test that needs three mocked collaborators to arrange tells you that the class under test has too many responsibilities.

## Well-designed tests

Keep the coupling between test code and production code low. The public interface of your production code must be able to change without a rewrite of the tests.

A test that asserts on an implementation detail instead of on observable behaviour creates churn. Every internal refactor that changes no behaviour then breaks that test.

## When TDD is not appropriate

Do not apply TDD to everything:

- **Markup**, such as HTML and templates: you can only check the result by looking at it
- **Configuration**: a config file or a state machine is only testable when you run it against the real system it configures
- **Slow feedback cycles**: when one test cycle takes minutes, weigh the cost. Make the feedback faster instead of abandoning TDD

## Keep feedback fast

Aim for a unit test suite that runs in under 30 seconds. A slow unit test suite usually points at a structural problem, which is unit tests that call a real database or a real external service. Move those tests into a separate integration suite, and keep the inner loop fast.

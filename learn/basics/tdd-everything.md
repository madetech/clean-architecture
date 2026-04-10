---
title: TDD everything
---

# TDD everything

The [outer loop](./fake-gateways.md) describes an ATDD discipline: write a failing acceptance test, make it pass, repeat. But the outer loop does not tell you how to write the production code in between.

That is what the inner loop is for.

## The inner loop

When your acceptance test is failing, you enter the inner loop:

1. Write a failing unit test
2. Watch it fail for the right reason
3. Write the minimum production code to make it pass
4. Watch it pass
5. Refactor
6. Does the acceptance test pass? If yes, go back to the outer loop. If no, go back to step 1.

## The three rules

The inner loop is governed by three rules:

1. You **must** write a failing test before writing any production code
2. You **must not** write more of a test than is sufficient to fail
3. You **must not** write more production code than is sufficient to make the currently failing test pass

Rule 3 permits sliming — returning a hardcoded value to make a test pass. This is not cheating. It is a signal: you don't yet have enough tests to justify writing the real implementation. Triangulation closes this loophole.

## Triangulation

With a single test, you can pass it by hardcoding the expected value:

```ruby
def total_price(items)
  10.00
end
```

Write a second test with different input and a different expected output. Now you are forced to write the real implementation.

Only generalise production code when a failing test demands it.

## Arrange, Act, Assert, Teardown

Every unit test follows this structure:

- **Arrange** — set up the state required for the test
- **Act** — call the thing under test
- **Assert** — verify the outcome
- **Teardown** — clean up (often handled automatically)

Name your tests to describe the behaviour of the software from the user's perspective, not the implementation. `"#execute"` is not a useful test name. `"returns the order total including tax"` is.

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

When unit testing a use case, inject a [Fake](./fake-gateways.md) to stand in for real gateways. This keeps tests fast and focused on use case behaviour only.

The five types of test double are Dummy, Stub, Fake, Spy, and True Mock. At the use case level, Fakes are most common — they are working implementations with shortcuts (in-memory instead of a database). Stubs work well for simpler cases where you only need to control a return value.

Minimise the number of test doubles in a single test. A test that needs three mocked collaborators to arrange is a signal that the class under test has too many responsibilities.

## Well-designed tests

Avoid tight coupling between test code and production code. The goal is for your production code's public interface to be able to evolve without requiring you to rewrite tests.

Asserting on implementation details rather than observable behaviour creates churn: every internal refactor that _should not_ break anything ends up breaking tests.

## When TDD is not appropriate

Not everything should be TDD'd:

- **Markup** (HTML, templates): correctness can only be verified by visual inspection
- **Configuration**: config files and state machines are only testable by running them against the real system they configure
- **Slow feedback cycles**: if your test cycle takes minutes per iteration, weigh the cost carefully — but invest in making feedback faster rather than abandoning TDD

## Keep feedback fast

Aim for individual unit test suites to run in under 30 seconds. A slow unit test suite is usually a structural problem — unit tests that hit a real database or real external services. Keep those in a separate integration suite, and keep the inner loop fast.

---
title: "Clean Architecture Ruby: RSpec"
---

# RSpec ATDD Structure

## spec/acceptance

Holds the end-to-end acceptance specs. These specs exclude the web Delivery Mechanism, and call the interface that the web Delivery Mechanism calls.

## spec/unit

Holds the unit specs.

## spec/fixtures

Holds the raw fixtures.

## spec/test_doubles

Holds the test doubles that need more than one line to build.

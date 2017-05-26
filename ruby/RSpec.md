---
title: Clean Architecture Ruby: RSpec
---

# RSpec ATDD Structure

## spec/acceptance

Contains end-to-end acceptance specs, without the Web Delivery mechanism
These specs call the interface that the Web Delivery mechanism uses

## spec/unit

Contains unit specs

## spec/fixtures

Contains raw fixtures

## spec/test_doubles

Contains "complex" test doubles
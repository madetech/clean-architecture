---
title: Clean Architecture & ATDD
---

# ATDD

## Acceptance Testing

An acceptance test exercises the whole system through the boundary of the system, and through nothing else.

An acceptance test stands in for the future UI of your system, and documents what that UI must do. Whatever an acceptance test couples to, the UI couples to as well.

An acceptance test therefore must not depend on these types of object:

- Domain objects 
- Gateways 

An acceptance test depends on the *Boundary* of your system only.

**An acceptance test measures progress towards the needs of the customer.** An acceptance test also reduces the amount of work that the customer did not ask for.

## Unit Testing

A unit test can break the rules above. A unit test documents the behaviour of a lower level component.

A unit test drives one component at a time, so a unit test can force the system through every permutation of that behaviour.

A suite of unit tests that does this gives you [semantic stability](https://www.madetech.com/blog/semantically-stable-test-suites).

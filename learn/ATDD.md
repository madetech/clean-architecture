# ATDD

## Acceptance Testing

The purpose of acceptance testing is to test an entire system via it's boundary only.
It serves as a *stand-in*, and documentation for the implementation of the future UI of your system.
Anything that you are coupled to in your acceptance tests, you are also going to be coupled to in your UI.

This means an acceptance test, cannot depend on the following types of objects:

- Domain objects 
- Gateways 

It must only depend on the *Boundary* of your system.

**The purpose of acceptance tests** is to measure success towards the goal of meeting the customer's needs, and reduces the 
occurrence of gold plating

## Unit Testing

Unit Tests are able to break these rules of acceptance tests. 
It is meant to serve as documentation of the behaviour of lower level components.
Since these tests are lower level it is possible to test-drive the system into performing every possible permutation of behaviour under a test situation.

This gives the property of [(semantic stability)](https://www.madetech.com/blog/semantically-stable-test-suites) .


# Clean Architecture

How to begin with "Made Tech Flavour Clean Architecture". 

This style of architecture has carried many names, which include "Hexagonal", "Ports & Adapters" and "Boundary-Control-Entity".

# Getting started

## Architectural Concepts

* [Use Case](use_case.md)
* [Domain](domain.md)
* [Gateway](gateway.md)
* [Bounded Contexts](bounded_contexts.md)

## Learn by example (Ruby)

Deliberate practice is the best way to learn Clean Architecture.

*(Work-in-progress)*

### Basics

* [The Mindset](learn/the-mindset.md)
* [Start with Acceptance Testing](learn/basics/start-with-acceptance.md)
* [Writing Fake Gateways](learn/basics/fake-gateways.md)
* [Use Cases organise your code](learn/basics/use-cases-organise.md)
* [Constructors are for collaborators](learn/basics/constructors-for-collaborators.md)
* [Do not leak your internals](learn/basics/do-not-leak-your-internals.md)
* [TDD everything](learn/basics/tdd-everything.md)
* [Build in a reliable dependency upgrade path](learn/basics/reliable-dependencies.md)
* [Your first Real Gateway](learn/basics/gateway-101.md)
* [Your first Delivery Mechanism](learn/basics/delivery-mechanism-101.md)

### Intermediate

* [Presenters are more flexible](learn/intermediate/flexible-presenters.md)
* [Keep your wiring DRY](learn/intermediate/keep-your-wiring-DRY.md)
* [Extend Use Case behaviour with Domain objects](learn/intermediate/extend-with-domain.md)
* [Extracting a Use Case from a Use Case](learn/intermediate/extract-use-case-from-another.md) 
* [Authentication](learn/intermediate/authentication.md)
* [Authorisation](learn/intermediate/authorisation.md)

### Advanced

* [Consider the Actors](learn/advanced/consider-the-actors.md)
* [Substitutable Use Cases](learn/advanced/substitutable-use-cases.md)
* [Feature Toggles](learn/advanced/feature-toggles.md)
* [Keep your Domain object construction DRY](learn/advanced/keep-your-domain-object-construction-dry.md) 

## Examples in Languages

* [Ruby](ruby/README.md)
* [Kotlin](kotlin/README.md)
* Go 
* Clojure
* JS

# Further Reading

[Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html) by Robert C. Martin is very close to 

* [BCE](https://www.amazon.com/Object-Oriented-Software-Engineering-Approach/dp/0201544350) by Ivar Jacobson, and
* [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture) by Alistair Cockburn. Hexagonal Architecture is also called **Ports & Adapters**.

The Made Tech Flavour differs again from [the Clean Architecture book by Robert C. Martin](https://www.amazon.co.uk/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164). Made Tech renames some of the basic concepts on purpose, for three reasons:

- A junior developer learns the concepts faster
  - The name "Use Case" connects the object to a Use Case Analysis session. Robert C. Martin calls the same object an Interactor.
  - The name "Domain" keeps Domain-Driven Design in view, and asks the reader what a Domain object is.
  - The name "Domain" avoids a clash with the EntityFramework Entity. Robert C. Martin calls a Domain object an Entity.

Made Tech Flavour Clean Architecture is more [prescriptive than any of these other examples](learn/practicality.md)

## Reference

* [Clean Coders videos](https://cleancoders.com/videos/clean-code)
* [Clean Architecture Book](https://www.amazon.co.uk/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164/)

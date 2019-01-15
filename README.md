# Clean Architecture

How to begin with "Made Tech Flavoured Clean Architecture". 

This style of architecture has had many names over the years including "Hexagonal", "Ports & Adapters" and "Boundary-Control-Entity".

# Getting started

## Architectural Concepts

* [Use Case](use_case.md)
* [Domain](domain.md)
* [Gateway](gateway.md)
* [Bounded Contexts](bounded_contexts.md)

## Learn by example (Ruby)

The best way to learn Clean Architecture is through deliberate practice.

*(Work-in-progress)*

### Basics

* [The Mindset](learn/the-mindset.md)
* [Start with Acceptance Testing](learn/basics/start-with-acceptance.md)
* [Writing Fake Gateways](learn/basics/fake-gateways.md)
* [Use Cases organise your code](learn/basics/use-cases-organise.md)
* [Constructors are for collaborators](learn/basics/constructors-for-collaborators.md)
* [Don't leak your internals!](learn/basics/do-not-leak-your-internals.md)
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

[Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html) by Robert C. Martin is extremely similar in nature to 

* [BCE](https://www.amazon.com/Object-Oriented-Software-Engineering-Approach/dp/0201544350) by Ivar Jacobson and,
* [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture) (also known as **Ports & Adapters**) by Alistair Cockburn.

The Made Tech flavour is slightly different still to exactly what is described in [Robert C. Martin's book about Clean Architecture](https://www.amazon.co.uk/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164), the choice to rename certain basic concept is deliberate to aid:

- Learning as a Junior 
  - Relating Interactors (Robert's name for UseCase objects) to Use Case Analysis sessions
  - Retaining an eye on Domain-Driven-Design i.e. What are Domain objects?
  - Avoiding overloading terminology e.g. Entity (Robert's name for Domain Objects) with EntityFramework Entities

You can think of the Made Tech flavour as being more relaxed than Hexagonal Architecture, but more prescriptive than the abstract concepts of Clean Architecture as described by Robert C. Martin's book.

## Reference

* [Clean Coders videos](https://cleancoders.com/videos/clean-code)
* [Clean Architecture Book](https://www.amazon.co.uk/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164/)


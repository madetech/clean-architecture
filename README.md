# Clean Architecture

![Clean Architecture](https://8thlight.com/blog/assets/posts/2012-08-13-the-clean-architecture/CleanArchitecture-8b00a9d7e2543fa9ca76b81b05066629.jpg)

This documents Made Tech Flavoured [Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html).

Clean Architecture is a variant of [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture) by Alistair Cockburn and,
[BCE](https://www.amazon.com/Object-Oriented-Software-Engineering-Approach/dp/0201544350) by Ivar Jacobson.

The Made Tech flavour is a bit more relaxed in some areas than Hexagonal Architecture but more prescriptive than the basics of Clean Architecture and, at this time, we only have documentation about Ruby.

# Long-term learning guide

We're beginning to put together [long-term learning goals](learn/README.md) for Clean Architecture, which individuals
can use to help provide some direction to areas which are required in order to be proficient at Clean Architecture.

# Use Cases

Each use case should be Framework and Database agnostic. 
* They are aware of the interface of the Gateways and Domain objects
* They expose a request/response interface which are defined as simple data structures (Hashes or Structs)

## Alternative names

* In Ivar Jacobson's BCE architecture these are the "Controls"
* In Uncle Bob's terminology these are "Interactors".
* "Operations"
* "Commands"

In Made Tech Flavour Clean Architecture we stick to the name "UseCase"

# Domain 

Domain objects are the center of your system. 
Their purpose is to model the domain, in the Object-Oriented world.

The challenge is determining what behaviours lie within Domain objects, and what behaviours lie within Use Cases.

A good rule of thumb is that behaviours within Domain objects *must be valid for all Use Cases across the system.*

It is cheaper to specialise Use Cases, resulting in an anemic domain model, then evolve the systems towards generalisations once patterns emerge.

## Alternative names

* Entities

# Gateways

Contains IO adapters (e.g. files, database or API calls)

It is the responsibility of Gateways to (one or more of):

* Construct Domain objects by reading from the I/O source
* Accept Domain objects to be written to the I/O source

Gateways are I/O source specific e.g. ActiveRecord, Sequel, MySQL, Paypal, FileSystem, RethinkDB

# Examples in Languages

* [Ruby](ruby/README.md)
* [Go](go/README.md) 
* [Clojure](clojure/README.md)
* [JS](js/README.md)
* [Kotlin](kotlin/README.md)

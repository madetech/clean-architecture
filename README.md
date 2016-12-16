# clean-architecture

![Clean Architecture](https://8thlight.com/blog/assets/posts/2012-08-13-the-clean-architecture/CleanArchitecture-8b00a9d7e2543fa9ca76b81b05066629.jpg)

This documents Made Tech Flavoured [Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html).

Clean Architecture is a variant of [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture) by Alistair Cockburn and,
[BCE](https://www.amazon.com/Object-Oriented-Software-Engineering-Approach/dp/0201544350) by Ivar Jacobson.

The Made Tech flavour is a bit more relaxed in some areas than Hexagonal Architecture but more prescriptive than the basics of Clean Architecture and, at this time, we only have documentation about Ruby.

# Use Cases

Each use case should be Framework and Database agnostic. 
* They are aware of the interface of the Gateways and Domain objects
* They expose a request/response interface which are defined as simple data structures (Hashes or Structs)

## Alternative names

* In Ivar Jacobson's BCE architecture these are the "Controls"
* In Uncle Bob's terminology these are "Interactors".
* "Operations"
* "Commands"

In Made Tech Flavour Clean Architecture we stick to the name "UseCases"

# Domain 

These contain the "Entity" objects

# Gateways

Contains IO adapters (e.g. files, database or API calls)
These construct Domain objects for use by Use Cases, and, save Domain objects given to it

# Examples in Languages

* [Ruby](ruby/README.md)
* [Go](go/README.md) 
* [Clojure](clojure/README.md)
* [JS](js/README.md)
* [Kotlin](kotlin/README.md)

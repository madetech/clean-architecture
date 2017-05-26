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

The purpose of Domain objects are to model the domain in a "data storage agnostic way".
The key here that there is an impedance-mismatch between Data Structures and Objects.
 
Since databases store Data Structures, not Objects with behaviour, we should rely on Gateways to do this conversion for us.

The challenge is determining what behaviours lie within Domain objects, and what behaviours lie within Use Cases.

A good rule of thumb is that behaviours within Domain objects *must be valid for all Use Cases across the system.*

It is cheaper to specialise Use Cases, resulting in an anemic domain model, then evolve the systems towards generalisations once patterns emerge.

## Alternative Names

* Entities 

We stick to the name "Domain"

# Gateways

Contains IO adapters (e.g. files, database or API calls)

It is the responsibility of Gateways to (one or more of):

* Construct Domain objects by reading from the I/O source
* Accept Domain objects to be written to the I/O source

Gateways are I/O source specific e.g. ActiveRecord, Sequel, MySQL, Paypal, FileSystem, RethinkDB

# Bounded Contexts

Once the SOLID and Package principles are understood, it is important to understand the role that bounded contexts play.

## Explicit 

When creating explicit bounded contexts, package principles and the cost of creating a separate package apply.

Explicit bounded contexts use a language or tooling-level feature to encode separation these could include using different repositories, separate microservice, maven multi-modules, gems or even .NET assemblies.
The benefit of explicit bounded contexts is that they promote clear separation (some methods enforce explicit decoupling more than others).

## Implicit

In Clean Architecture, it is important to also draw implicit bounded contexts to separate areas of the system that change for different reasons. 

Implicit bounded contexts will not encode separation in anything other than naming / namespacing in terms of grouping functionality. 
The benefit here is that the separation is cheap to create and destroy.

Carefully thinking about the fan-out of UseCases is important. An important consideration is when fan-out crosses a bounded context
e.g. A UseCase related "Financial Reporting" dependending on a gateway in "Authentication". 

It may make sense to have a Financial Reporting user Gateway that depends on a UseCase in Authentication and, database tables specific to the Financial Reporting.

Database Structures *are* Global variables. So it's important to think about which bounded context "owns" or should encapsulate those databases/tables/columns.

Similarly it might be important to consider a certain subset of Domain object(s) implicitly bounded context private. 
Such that, those Domain objects may only be manipulated (by another bounded context) through the UseCase boundary of that bounded context.

# Examples in Languages

* [Ruby](ruby/README.md)
* [Kotlin](kotlin/README.md)
* Go 
* Clojure
* JS

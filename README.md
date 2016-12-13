# clean-architecture

This documents Made Tech Flavoured Clean Architecture.

Clean Architecture is a variant of [Hexagonal Architecture](http://alistair.cockburn.us/Hexagonal+architecture) by Alistair Cockburn and,
[BCE](https://www.amazon.com/Object-Oriented-Software-Engineering-Approach/dp/0201544350) by Ivar Jacobson.

The Made Tech flavour is a bit more relaxed in some areas than Hexagonal Architecture but more prescriptive than the basics of Clean Architecture and, at this time, we only have documentation about Ruby.

## RSpec (RSpec specific test layout)

### spec/acceptance

Contains end-to-end acceptance specs, without the Web Delivery mechanism
These specs call the interface that the Web Delivery mechanism uses

### spec/unit

Contains unit specs

### spec/fixtures

Contains raw fixtures

### spec/test_doubles

Contains "complex" test doubles

## Production Code

### (lib|src)/<insert customer name here>/**

* All customer code should be housed within a Client namespace e.g. ```AcmeIndustries::Financial::UseCase::CreateInvoice```
* All non-customer specfic code should be housed within a MadeTech namespace e.g. ```MadeTech::Authentication::UseCase::Login```

### use_case/

Each use case should be Framework and Database agnostic. 
* They are aware of the interface of the Gateways and Domain objects
* They expose a request/response interface which are defined as simple data structures (Hashes or Structs)

#### Alternative names

* In Ivar Jacobson's BCE architecture these are the "Controls" #
* In Uncle Bob's terminology these are "Interactors".
* "Operations"
" "Commands"

In Made Tech Flavour Clean Architecture we stick to "UseCases"

### domain/

These contain the "Entity" objects

### gateway/

Contains IO adapters (e.g. files, database or API calls)
These construct Domain objects for use by Use Cases, and, save Domain objects given to it

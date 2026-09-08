# Practicality

The structure of Made Tech Flavour Clean Architecture suits the systems that Made Tech builds most often.

Made Tech has built these styles of system with it:

- HTTP APIs
- Event-driven GUIs
- Web applications with server-side rendering
- HTTP middleware that integrates several APIs
- Event-driven systems that use message queues

Made Tech has done limited work with it on:

- Games programming
- Embedded programming

## Rule: one Use Case per file

This rule causes problems when you build a reusable library.

Library authors either ignore the rule, or add a facade that makes the public API easier to call.

Some workloads already have a well-known architecture, such as a compiler. Use that architecture instead.

## Rule: use object composition over class inheritance

One way to provide a plugin point is to let the Delivery Mechanism inherit from the high-level policy.

Consider a system that switches a light on. The template method pattern gives you one way to build it.

Consider the following pseudocode:

```ruby
abstract class LightFlasher

  def flash_lights(rate:)
     ...
  end

  abstract def light_on;
  abstract def light_off;
end
```

The real light flasher then extends `LightFlasher`. Inheritance is a simple alternative to composition, and composition usually means a Gateway.

## In Haskell

In Haskell, define a Free Monad that holds the impure operations your business rules need.

In Production, run a Free Monad interpreter that calls the real impure operations.

In unit tests, run an interpreter that is pure. A pure interpreter is a test double, and it lets you test code that describes impure operations.

Consider the following pseudocode:

```haskell
createOrUpdate personExists createPerson person = if !personExists(person) then createPerson(person) && true else false
```

`personExists` reads from a database, so `personExists` performs IO. That makes `createOrUpdate` impure, and an impure function is hard to test.

A Free Monad represents an impure operation as pure data.

## Conclusion

Robert C. Martin describes Clean Architecture in the abstract for this reason.

The general principle of Clean Architecture is that high-level policy, meaning the business rules, does not depend on low-level detail, such as how to talk to PostgreSQL.

Reach that goal with the features of your language. If your system works and stays easy to change, you have a Clean Architecture.

Made Tech Flavour Clean Architecture adds three things to that principle: parts of Domain-Driven Design, a structure that suits ATDD, and a directory layout that stays easy to navigate as the number of Use Cases grows.

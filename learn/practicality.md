# Practicality

The system structure of Made Tech Flavour Clean Architecture is optimised for the set of systems that we would commonly build.

It has been used successfully to build systems of the following styles:

- HTTP APIs
- Event-driven GUIs
- Web applications with server-side rendering
- HTTP Middleware (integrating multiple APIs)
- Event-driven systems (using Message Queues)

Some (limited) exploration has been made using it for:

- Games programming
- Embedded programming

## Rule: one use case per file

This aspect of the style can cause issues when building reusable libraries.

Typically you will see this rule being ignored, or a facade pattern employed to optimise the API for ease-of-use.

For workloads that already have a well-known architecture e.g. a Compiler, it may be desirable to employ that architecture instead.

## Rule: use object composition over class inheritance

One way to provide plugin points is to allow the delivery mechanism to inherit from the high-level policy.

Imagine you needed to switch on a light, you could use the template method pattern

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

The real light flasher system could then extend this to create the concrete light flasher. This can be a simple alternative to composition (typically a gateway).

## In Haskell

In Haskell, the most flexible way to implement Clean Architecture is to define a Free Monad with the impure operations that your business rules need to operate on.

In production you will use a Free Monad interpreter that connects to the real impure operations.

In unit tests, you will use an interpreter that is actually pure (a test double!), which enables you to test code that encodes impure operations.

Consider the following pseudocode:

```haskell
createOrUpdate personExists createPerson person = if !personExists(person) then createPerson(person) && true else false
```

Since personExists must perform IO (to fetch from a database), and we either perform some IO or not. This function _must_ be impure.
This makes it difficult to test.

Free Monads provide a way to represent this impure operation as pure data.

## Conclusion

This is why Robert C. Martin intentionally speaks about Clean Architecture in the abstract.

The _general principle_ of Clean Architecture is to have high-level policy (i.e. Business Rules) not depend on low-level details (e.g. how to speak to PostgreSQL). 

If you achieve this goal through careful use of language features, and your system is working and easy to maintain you have achieved a "Clean Architecture".

What we do in Made Tech Flavoured Clean Architecture is blend a mix of Domain-Driven-Design, optimise for ATDD, and ease of project navigation given a large number of use cases.


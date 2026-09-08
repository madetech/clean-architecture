# Bounded Contexts

Learn the SOLID principles and the Package principles first. Bounded contexts build on both.

## Explicit

An explicit bounded context uses a language feature or a tool to encode the separation. Examples are separate repositories, separate microservices, Maven multi-modules, gems, and .NET assemblies.

An explicit bounded context creates a clear separation. Some of these methods enforce the separation more strongly than others.

The Package principles apply to an explicit bounded context. The cost of creating a separate package applies too.

## Implicit

An implicit bounded context separates areas of the system that change for different reasons. Draw implicit bounded contexts as well as explicit ones.

An implicit bounded context encodes the separation in naming and namespacing only. An implicit bounded context is cheap to create and cheap to remove.

## Fan-out across a bounded context

Check the fan-out of each Use Case. Fan-out that crosses a bounded context needs care.

For example, a Use Case in "Financial Reporting" needs the name of a user. The user data belongs to "Authentication".

WARNING: A Use Case must never call a [Gateway](gateway.md) that belongs to another bounded context. A Gateway is a private detail of the bounded context that owns it. A Financial Reporting Use Case that calls an Authentication Gateway reads the Authentication tables, and Authentication can then no longer change those tables without breaking Financial Reporting.

A Use Case may call a Use Case in another bounded context. The Use Case boundary is the part that a bounded context publishes, so a call across that boundary is correct. The Financial Reporting Use Case calls a Use Case in Authentication, and receives a simple data structure back.

### When to wrap the call in a Gateway

Financial Reporting can also give itself a user Gateway that calls the Authentication Use Case. That wrapper is an option, not a requirement.

Wrap the call when data from the other bounded context must combine with data that this bounded context owns.

The Financial Reporting user Gateway then has two IO sources: the Use Case boundary of Authentication, and the database tables that Financial Reporting owns, such as a ledger table. A Gateway adapts an IO mechanism, and the published boundary of another bounded context is an IO mechanism in the same way that PostgreSQL or an HTTP API is one. The Gateway combines both sources into one Financial Reporting Domain object.

The Financial Reporting Use Case then receives one collaborator and one Domain object. The Use Case does not join two sources itself, and the Use Case does not know which field came from which source.

Call the other Use Case directly when there is nothing to combine. A Gateway that only forwards a single call adds a class and no value.

## Ownership

A database structure is a global variable. Decide which bounded context owns each database, each table, and each column.

You can also make a set of Domain objects private to one bounded context. Another bounded context then changes those Domain objects only through the Use Case boundary of the owning context.

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

For example, a Use Case in "Financial Reporting" depends on a Gateway in "Authentication". Instead, give "Financial Reporting" its own user Gateway. That Gateway depends on a Use Case in "Authentication", and on database tables that belong to "Financial Reporting".

## Ownership

A database structure is a global variable. Decide which bounded context owns each database, each table, and each column.

You can also make a set of Domain objects private to one bounded context. Another bounded context then changes those Domain objects only through the Use Case boundary of the owning context.

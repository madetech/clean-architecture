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

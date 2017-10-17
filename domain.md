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

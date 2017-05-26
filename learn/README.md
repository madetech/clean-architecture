---
title: Learning Clean Architecture
---


# Learning Clean Architecture

## Learning

A typical number used to determine how much effort is required to become an expert is 10,000 hours of practice.

It cannot be any practice, however, i.e. you cannot swing a golf club for 10,000 hours and become as good as Tiger Woods.

"Practice" must be:

* Deliberate and goal directed
* Include the opportunity for:
    * Self-reflection
    * Feedback

## Values 

Clean Architecture works best when all programmers share the same mindset, or at the very least understand and apply its mindset.

*We are uncovering better ways of writing code and architecting software by doing it and helping others do it. Through this work we have come to value:*

**Expressing the domain simply** over expressing the domain via tools and frameworks
**Executable documentation** over non-executable documentation
**Customer usage, deferring technology choices** over fitting customer usage into technology choices 
**Delivering value with low cost of change** over delivering hard to change value sooner 

*That is, while there is value in the items on
the right, we value the items on the left more.*

## Principles

* Code rots and becomes a big ball of mud when programmers fear changing code
* Applying a sound strategy for preventing the introduction of defects, such as TDD, unpins eliminating fear. [(semantic stability)](https://www.madetech.com/blog/semantically-stable-test-suites) 
* Refactoring can occur at any time when there is no fear
* When the team understanding of the domain improves, keeping the in-code model of the domain up to date is important.
* The SOLID and package principles provide a guide to aid good software design  

## Other guides

* [ATDD](ATDD.md)

## Core Skills

* Able to describe 
    - OO language features
    - the responsibility of each organising component of a clean architecture 
    - SOLID principles
    
* Able to identify 
    - OO language features
    - the core organising components of a clean architecture in a code base
    - concrete examples where the forces of the SOLID and Package principles are at play
    
* Able to implement and use in code
    - OO language features
    - all the core organising components of a clean architecture
    - the SOLID principles as a tool to help guide the shape of your architecture
    - the Package principles as a tool to help guide the organisation of your packages
    
# Clean Architecture skill-set 

* Able to perform analysis of potential use case(s) 
    * Determine an order to work through use case(s) that will test the most assumptions
    * Determine input data structure 
    * Determine output data structure
    * Determine which Domain object(s) are potentially required
    * Determine potential interface of any collaborator(s)
* Able to perform analysis of appropriate use of asynchronous vs synchronous use cases
* Able to use type systems to aid construction, refactoring and robustness (rather than primarily a hindrance)
* Able to make use of IDE refactoring tools to aid refactoring and construction
* Able to apply TDD to provide the basis of a good testing strategy
    * Able to apply ATDD to provide extra robustness and a customer-goal-oriented testing approach
* Able to recognise recurring themes of the development process, and the common challenges faced in each
    * Null-step (wiring and boilerplate)
    * Degenerate cases
    * Passing the first acceptance test
    * Creating your second use case
    * Creating generalisations
    * ...
* Able to support and mentor others in recurring themes of the development process
* Be able to (self-)organise/communicate with other teams also writing code in the same parts of the system

# Object-oriented principles 

Below is a list of OO tools & skills that are non-specific to Clean Architecture. 

It is ideal if you have knowledge of how each of these works in your language of choice (assuming it supports the listed language feature).

* OO
    * Polymorphism
    * Encapsulation
    * Composition
    * Abstract class
    * Inheritance
    * Reference and value types
    * Static
    * Overriding
    * Exceptions
    
* Type-safe OO: 
    * Interface
    * Concrete class
    * Generics

### Principles of Object-oriented programming

These are widely accepted as the forces at play when developing OO software. While there is opposition to that, we 
assume when building Cleanly architected systems, that they hold true.

* SOLID principles
    * Single responsibility principle
    * Open closed principle
    * Liskov substitution principle
    * Interface segregation principle
    * Dependency inversion principle

* Package principles
    * Cohesion
        * Reuse-release equivalence principle
        * Common-reuse principle
        * Common-closure principle
    * Coupling
        * Acyclic dependencies principle
        * Stable-dependencies principle
        * Stable-abstractions principle

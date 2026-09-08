---
title: Learning Clean Architecture
---


# Learning Clean Architecture

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

* Code decays into an unstructured mass when programmers fear changing the code
* A sound strategy for preventing defects, such as TDD, removes that fear. [(semantic stability)](https://www.madetech.com/blog/semantically-stable-test-suites) 
* A team without that fear refactors at any time
* When the team understanding of the domain improves, update the model of the domain in the code
* The SOLID principles and the Package principles guide software design 

## Learning

People often say that an expert needs 10,000 hours of practice.

Repetition alone does not produce an expert. A golfer who swings a club for 10,000 hours without feedback does not become an expert golfer.

Practice must be:

* Deliberate and directed at a goal
* Open to:
    * Self-reflection
    * Feedback

## Other guides

* [ATDD](ATDD.md)

## Core Skills

* You can describe 
    - the object-oriented features of your language
    - the responsibility of each organising component of a Clean Architecture 
    - the SOLID principles
    
* You can identify 
    - the object-oriented features of your language
    - the core organising components of a Clean Architecture in a code base
    - concrete examples where the SOLID principles and the Package principles apply
    
* You can write and use in code
    - the object-oriented features of your language
    - all the core organising components of a Clean Architecture
    - the SOLID principles, as a tool that guides the shape of your architecture
    - the Package principles, as a tool that guides the organisation of your packages
    
# Clean Architecture skill-set 

* You can analyse a set of Use Cases 
    * You choose an order of work through the Use Cases that tests the most assumptions
    * You determine the input data structure 
    * You determine the output data structure
    * You determine which Domain objects the Use Cases need
    * You determine the interface of each collaborator
* You can decide when to write an asynchronous Use Case and when to write a synchronous one
* You can use a type system to help you construct, refactor and harden code, instead of fighting the type system
* You can use the refactoring tools of your IDE to refactor and to write code
* You can apply TDD as the basis of a good testing strategy
    * You can apply ATDD to add robustness and to keep the tests directed at the goal of the customer
* You can recognise the recurring stages of the development process, and the common problems in each stage
    * Null-step (wiring and boilerplate)
    * Degenerate cases
    * Passing the first acceptance test
    * Creating your second Use Case
    * Creating generalisations
    * ...
* You can support and mentor others through the recurring stages of the development process
* You can organise and communicate with the other teams that write code in the same parts of the system

# Object-oriented principles 

The list below holds object-oriented tools and skills that are not specific to Clean Architecture. 

Learn how each one works in your language, where your language supports it.

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

The principles below are the widely accepted forces that act on object-oriented software. Some people disagree with them. Made Tech Flavour Clean Architecture assumes that they hold true.

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

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

* Code rots and becomes a big ball of mud when programmers fear changing code
* Applying a sound strategy for preventing the introduction of defects, such as TDD, unpins eliminating fear. [(semantic stability)](https://www.madetech.com/blog/semantically-stable-test-suites) 
* Refactoring can occur at any time when there is no fear
* When the team understanding of the domain improves, keeping the in-code model of the domain up to date is important.
* The SOLID and package principles provide a guide to aid good software design 

## Learning

A typical number used to determine how much effort is required to become an expert is 10,000 hours of practice.

It cannot be any practice, however, i.e. you cannot swing a golf club for 10,000 hours and become as good as Tiger Woods.

"Practice" must be:

* Deliberate and goal directed
* Include the opportunity for:
    * Self-reflection
    * Feedback

## Other guides

* [ATDD](ATDD.md)

## Skills

Measure your skills in each of these areas as: can describe, can identify, can implement.

0. Programming
  - OO Language Features
    - Polymorphism
    - Encapsulation
    - Composition
    - Abstract class
    - Inheritance
    - Reference and value types
    - Static
    - Overriding
    - Exceptions
    - Interface*
    - Concrete class*
    - Generics*
  - SOLID Principles
    - Single responsibility principle
    - Open closed principle
    - Liskov substitution principle
    - Interface segregation principle
    - Dependency inversion principle
  - Package Principles
    - Cohesion
      - Reuse-release equivalence principle
      - Common-reuse principle
      - Common-closure principle
    - Coupling
      - Acyclic dependencies principle
      - Stable-dependencies principle
      - Stable-abstractions principle
  - Design patterns
  - Static type systems
    - Using as advantage rather than hindrance
    - Stringly-typing in these languages
  - Dynamic type systems
    - Playing to strengths
    - Avoiding not so obvious smells
  - Editing code
    - Refactoring tools
    - Regex replacers
  - Professionalism
    - Thinking as a Team
    - Easily identify potential for merge conflicts, without looking at the code
    - Sharing knowledge (pair programming)
1. Testing
  - Code coverage
  - Semantic Stability
  - Mutation Testing
  - Acceptance testing
    - Code
    - Cucumber
    - Fitnesse
    - When to use Code vs Cucumber/Fitnesse?
  - Acceptance-tests-as-a-UI 
  - Transformation Priority Premise
  - Designing your public API
  - Recognizing the difference between necessary & unnecessary null-step (wiring & boilerplate)
  - Degenerate test cases
  - 
2. Clean Architecture   
  - Presenter pattern (asyncronous)
  - Request/response pattern (syncronous)
  - Domain-Driven-Design
    - Creating generalisations using Domain objects
3. Lightweight-analysis
  - Determine users needs
    - Wireframes
    - Seams
      - Existing UI
      - Delivery Mechanism
  - UI-agnostic Use Case
    - Input data structure
    - Output data structure
    - What Domain objects are likely required
    - What collaborators are likely required
  - Committing to a first slice
    - Good incision points
      - Testing assumptions & Risks
      - Delivering quick wins
    - Considering your next move
4. Mentoring
  - Able to mentor others
 

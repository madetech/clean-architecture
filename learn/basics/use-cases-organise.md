---
title: Use Cases organise your code
---

# Use Cases organise your code

A software system collects a large list of Use Cases over time. An end user calls some of those Use Cases through the UI. Other Use Cases compose together.

Clean Architecture keeps that list easy to navigate.

## One Use Case per Class

Write one class for one Use Case.

The first reason is _isolation_. Separate files make it harder to break one Use Case while you change another. Isolation and decoupling prevent the design fault called _fragility_.

The second reason is naming. _JournalManager_ tells you nothing, so you must read the class to learn what the class does. _ViewJournal_ tells you what the class does, so you decide from the name alone whether the class serves your current goal.

## Use the command pattern

Expose a single method called `execute`. The method takes a simple data structure and returns a simple data structure.

In Ruby, use a hash `{}`.

```ruby
class ViewJournal
  def execute(request)
    {}
  end
end
```

## Responsibility

Use Cases divide your business logic into parts. Each part is responsible to one actor, and to one actor only.

For example, an eCommerce system might have these actors:

- The Customer
- The Payer
- The Financial Team
- The Warehouse
- The Customer Service Team

[Consider the Actors](../advanced/consider-the-actors.md) shows you how to find the actors and how to check that each Use Case serves one of them.

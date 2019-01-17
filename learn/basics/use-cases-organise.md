# Use Cases organise your code

Over time many software systems accumulate a large list of use cases that can be used either by end users through the UI or be composed together.

Clean Architecture seeks to make this list of use cases easy to navigate.

## One Use Case per Class

As a general rule, you should create one class to house one use case.

One reason to do this is to create _isolation_ - it is harder to break other use cases if the code is physically located in separate files.
We value this isolation and decoupling to avoid the design smell of _fragility_.

Another reason is to make it easier to name your classes - _JournalManager_ is a broadly useless name which will require inspecting the contents of the class to learn it's intent.
Whereas _ViewJournal_ is a discrete, descriptive name that will enable you to decide _from the name alone_ if it is relevant to your current goal.

## Use the command pattern

We expose a single method called `execute` which takes a simple data structure and returns a simple data structure.

In ruby, we use hashes `{}`.

```ruby
class ViewJournal
  def execute(request)
    {}
  end
end
```

## Responsibility

Use cases divide your code base into chunks of business logic that should be responsible to one (and only one) actor.

For example, in an eCommerce system you may have identified the following actors:

- The Customer
- The Payer
- The Financial Team
- The Warehouse
- The Customer Service Team


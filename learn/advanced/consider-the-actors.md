---
title: Consider the Actors
---

# Consider the Actors

A use case serves one actor.

Name the actors before you name the use cases. If you name the use cases first, you write one class that serves three actors. That class then changes for three reasons, and each change risks the other two actors.

## What an actor is

An actor is a person or a system that asks the software to do work and cares about the result.

An actor is not a database, a framework, a screen, or a class in your code.

Use this test: an actor changes their mind on their own. The cheese supplier changes the cheese rule without asking the concert promoter. Two actors, two reasons to change.

An actor is a role, not a person. One person can act as two actors. The same person fills the coffee machine and drinks the coffee. The two roles want different things, so they are two actors.

## Use case analysis

Do these steps in order.

1. List the actors.
2. For each actor, list the work that the actor asks the system to do.
3. Write each item of work as `<Actor> <verb> <object>`.
4. Give each item of work one use case class.
5. Check each use case. Name the one actor who can ask for a change to it. If you name two actors, split the use case.

A UML use case diagram draws a stick figure for each actor, an oval for each use case, and a line from the actor to the use case. A table records the same information:

| Actor | Use case | Trigger | Result |
| --- | --- | --- | --- |
| The Brewer | `StartBrew` | The Brewer presses the Brew button | Water heats |

An actor can own more than one use case. A use case serves only one actor. The relation is one to many, not many to many. A line from two actors to one oval is the fault this article shows you how to remove.

## The coffee maker

The Mark IV Special Coffee Maker holds a boiler, a relief valve, a warmer plate, a pot sensor, a Brew button, and an indicator light.

The written requirement is one sentence: "The machine makes coffee."

That sentence produces one class:

```ruby
class MakeCoffee
  def initialize(hardware:)
    @hardware = hardware
  end

  def execute(brew_button:)
    if brew_button == :pushed && @hardware.boiler_status == :not_empty
      @hardware.boiler_mode = :on
      @hardware.relief_valve = :closed
      @hardware.indicator = :off
    end

    case @hardware.warmer_plate_status
    when :warmer_empty
      @hardware.relief_valve = :open
      @hardware.boiler_mode = :off
      @hardware.warmer_mode = :off
    when :pot_not_empty
      @hardware.relief_valve = :closed
      @hardware.boiler_mode = :on
      @hardware.warmer_mode = :on
    when :pot_empty
      @hardware.warmer_mode = :off
    end

    if @hardware.boiler_status == :empty
      @hardware.boiler_mode = :off
      @hardware.indicator = :on
    end

    {}
  end
end
```

`MakeCoffee` reads one sensor in three branches and writes `boiler_mode` in four places. The order of the branches decides the result. Nobody can change one rule without reading all of them.

### Name the actors

Three actors ask this machine for work.

**The Now Drinker** wants a cup before the brew finishes. The Now Drinker takes the pot off the warmer plate during the brew.

**The Hot Drinker** collects coffee later and wants it hot. The Hot Drinker wants the warmer plate on while the pot holds coffee.

**The Brewer** fills the water and the grounds and presses the Brew button. The Brewer wants the machine to refuse a brew with an empty boiler, and to signal when the brew finishes.

| Actor | Use case | Trigger | Result |
| --- | --- | --- | --- |
| The Brewer | `StartBrew` | The Brewer presses the Brew button | The valve closes and the boiler heats |
| The Brewer | `FinishBrew` | The boiler runs empty | The boiler stops and the indicator lights |
| The Now Drinker | `PauseBrew` | The pot sensor reports no pot | The valve opens and the boiler stops |
| The Now Drinker | `ResumeBrew` | The pot sensor reports a pot | The valve closes and the boiler heats |
| The Hot Drinker | `KeepCoffeeHot` | The pot sensor changes | The warmer plate heats or stops |

Five use cases, three actors. The Brewer owns two use cases. Each use case still serves one actor.

### The conflict

The Now Drinker takes the pot during the brew. The Hot Drinker wants a full hot pot.

The machine cannot serve both actors at that moment. Hot water still sprays over the grounds, and the pot is not under the filter. The filter overflows.

The Mark IV design opens the relief valve and stops the flow. The Now Drinker wins. The Hot Drinker waits longer for a full pot.

That decision belongs to the actors, not to the code. Record it. A reader of `PauseBrew` must be able to find out why the machine stops the brew instead of finishing it.

### The use cases

```ruby
class StartBrew
  def initialize(boiler_gateway:, valve_gateway:, indicator_gateway:)
    @boiler_gateway = boiler_gateway
    @valve_gateway = valve_gateway
    @indicator_gateway = indicator_gateway
  end

  def execute
    return { success: false, errors: [:boiler_empty] } if @boiler_gateway.empty?

    @valve_gateway.close
    @boiler_gateway.heat
    @indicator_gateway.off

    { success: true, errors: [] }
  end
end
```

```ruby
class FinishBrew
  def initialize(boiler_gateway:, indicator_gateway:)
    @boiler_gateway = boiler_gateway
    @indicator_gateway = indicator_gateway
  end

  def execute
    @boiler_gateway.stop
    @indicator_gateway.on
    {}
  end
end
```

```ruby
class PauseBrew
  def initialize(boiler_gateway:, valve_gateway:)
    @boiler_gateway = boiler_gateway
    @valve_gateway = valve_gateway
  end

  def execute
    @valve_gateway.open
    @boiler_gateway.stop
    {}
  end
end
```

```ruby
class ResumeBrew
  def initialize(boiler_gateway:, valve_gateway:)
    @boiler_gateway = boiler_gateway
    @valve_gateway = valve_gateway
  end

  def execute
    @valve_gateway.close
    @boiler_gateway.heat
    {}
  end
end
```

```ruby
class KeepCoffeeHot
  def initialize(pot_gateway:, warmer_plate_gateway:)
    @pot_gateway = pot_gateway
    @warmer_plate_gateway = warmer_plate_gateway
  end

  def execute
    if @pot_gateway.holds_coffee?
      @warmer_plate_gateway.heat
    else
      @warmer_plate_gateway.stop
    end
    {}
  end
end
```

Each use case now names its own gateways. `KeepCoffeeHot` does not know that a brew exists. `PauseBrew` does not know that a warmer plate exists.

The hardware poll loop is the [delivery mechanism](../basics/delivery-mechanism-101.md). The poll loop reads the sensors and calls the use cases:

```ruby
class HardwarePoller
  def initialize(hardware:, use_cases:)
    @hardware = hardware
    @use_cases = use_cases
    @pot_present = true
  end

  def poll
    @use_cases[:start_brew].execute if @hardware.brew_button == :pushed
    @use_cases[:finish_brew].execute if @hardware.boiler_status == :empty

    pot_present = @hardware.warmer_plate_status != :warmer_empty

    if pot_present != @pot_present
      @use_cases[pot_present ? :resume_brew : :pause_brew].execute
      @pot_present = pot_present
    end

    @use_cases[:keep_coffee_hot].execute
  end
end
```

The poll loop knows the hardware. The use cases know the rules. A change to the sensor polling rate does not touch a rule, and a change to a rule does not touch the poll loop.

## Gilded Rose, solved

The Gilded Rose kata gives you one method that updates the quality of every item each night. This is the shape of the original code:

```ruby
def update_quality
  @items.each do |item|
    if item.name != 'Aged Brie' && item.name != 'Backstage passes to a TAFKAL80ETC concert'
      if item.quality > 0 && item.name != 'Sulfuras, Hand of Ragnaros'
        item.quality -= 1
      end
    else
      if item.quality < 50
        item.quality += 1
        if item.name == 'Backstage passes to a TAFKAL80ETC concert'
          item.quality += 1 if item.sell_in < 11 && item.quality < 50
          item.quality += 1 if item.sell_in < 6 && item.quality < 50
        end
      end
    end
    # the sell_in and past-date branches continue in the same method
  end
end
```

The kata teaches refactoring. It also records an actor fault. Read the method again and name the actors.

**The Innkeeper** owns the nightly run. The Innkeeper decides when the update runs, which items it covers, and the quality bounds of 0 and 50.

**The Cheese Supplier** owns the Aged Brie rule. Aged Brie gains quality with age.

**The Concert Promoter** owns the backstage pass rule. The thresholds of 10 days and 5 days belong to the promoter, and so does the drop to zero after the concert.

**Ragnaros** owns Sulfuras. Sulfuras never changes.

**The Conjurer** owns Conjured items. Conjured items lose quality twice as fast.

Five actors write into one method. The Concert Promoter asks for a new threshold, and a developer edits the same lines that hold the cheese rule. That is why the kata is hard.

### The split

One use case serves the Innkeeper:

```ruby
class UpdateInventory
  def initialize(item_gateway:)
    @item_gateway = item_gateway
  end

  def execute
    items = @item_gateway.all
    items.each(&:pass_a_day)
    @item_gateway.save_all(items)
    {}
  end
end
```

The other four actors do not get a use case. They get a [domain object](../intermediate/extend-with-domain.md) each. A domain object also serves one actor.

```ruby
class BackstagePass
  MAXIMUM_QUALITY = 50

  attr_reader :sell_in, :quality

  def initialize(sell_in:, quality:)
    @sell_in = sell_in
    @quality = quality
  end

  def pass_a_day
    @sell_in -= 1
    return @quality = 0 if @sell_in.negative?

    increase_quality
    increase_quality if @sell_in < 10
    increase_quality if @sell_in < 5
  end

  private

  def increase_quality
    @quality = [@quality + 1, MAXIMUM_QUALITY].min
  end
end
```

```ruby
class LegendaryItem
  attr_reader :sell_in, :quality

  def initialize(sell_in:, quality:)
    @sell_in = sell_in
    @quality = quality
  end

  def pass_a_day
    nil
  end
end
```

The gateway builds the right domain object for each row. `UpdateInventory` calls `pass_a_day` and never reads a name.

### What each actor now touches

| Actor | Change the actor asks for | File that changes |
| --- | --- | --- |
| The Concert Promoter | Add 4 when 3 days or less remain | `backstage_pass.rb` |
| The Cheese Supplier | Aged Brie stops at 40 | `aged_brie.rb` |
| The Conjurer | Add a new Conjured item type | `conjured_item.rb`, plus one line in the gateway |
| Ragnaros | Add a second legendary item | The gateway only |
| The Innkeeper | Run the update twice a day | The delivery mechanism only |

No row lists two files that belong to two different actors. That is the result you want from use case analysis.

## The rule

For each use case, name the one actor who can ask for a change to it.

- One name: the use case is correct.
- Two names: split the use case, or accept the tradeoff and record it.
- No name: the class is not a use case. It is a gateway, a domain object, or dead code.

An actor can own many use cases. A use case serves one actor.

## The tradeoff

A split has a cost. Sometimes the cost is higher than the fault it removes.

`PauseBrew` and `KeepCoffeeHot` both read the pot sensor. The poll loop runs many times a second, and each run now reads the same sensor twice. Two use cases also need two entries in the [dependency factory](../intermediate/keep-your-wiring-DRY.md).

Keep two actors in one use case when all three of these are true:

1. The two actors have never changed a rule on their own. Check the history of the file.
2. The split repeats a gateway read on a path that runs often.
3. Neither actor needs the use case as a separate entry point.

When you accept the tradeoff, write the decision down next to the code. Name both actors, and name the condition that reverses the decision:

```ruby
# Serves two actors: the Now Drinker and the Hot Drinker.
# Both rules read the same pot sensor, and this use case runs on a
# 100ms loop. A split doubles the sensor read on that loop.
# Split this use case when either actor changes a rule on its own.
class UpdateForPotPosition
```

A comment without the reversal condition is a comment that nobody acts on. The condition tells the next reader what to look for.

## From the trenches

The actor fault hides inside a requirement written as one sentence. "The machine makes coffee" and "update the quality each night" both read as one job. Each one holds three or more actors.

Ask one question of every requirement: who asks for this, and who else can change it later. Two answers mean two use cases.

## Read next

- [Use Case](../../use_case.md)
- [Use Cases organise your code](../basics/use-cases-organise.md)
- [Extracting a Use Case from a Use Case](../intermediate/extract-use-case-from-another.md)
- [Extend Use Case behaviour with Domain objects](../intermediate/extend-with-domain.md)

# Presenters are more flexible

Returning a hash from a use case is the right default. It is simple, easy to test, and works well for most situations.

But as a system grows you will encounter use cases that need to communicate differently to different callers — a JSON API and an HTML view handling success and failure in completely different ways. This is where returning a hash starts to show its limits.

## The hash approach and its friction

```ruby
class TurnLightOn
  def execute(light_id:)
    light = @light_gateway.find(light_id)
    return { success: false, errors: [:light_not_found] } if light.nil?
    light.turn_on
    { success: true }
  end
end
```

The caller must inspect the result and branch on it:

```ruby
# In a controller
result = turn_light_on.execute(light_id: id)
if result[:success]
  redirect_to lights_path
else
  render :edit, status: :unprocessable_entity
end
```

The controller is now coupled to the shape of the hash. Every caller that handles failure must know that `errors: [:light_not_found]` is how this use case communicates that outcome.

## The presenter pattern

Instead of returning a hash, the use case accepts a presenter object and calls methods on it:

```ruby
class TurnLightOn
  def initialize(light_gateway:)
    @light_gateway = light_gateway
  end

  def execute(light_id:, presenter:)
    light = @light_gateway.find(light_id)
    return presenter.light_not_found if light.nil?
    light.turn_on
    presenter.success
  end
end
```

The use case defines the outcomes — `success` and `light_not_found` — but delegates the response entirely to the presenter. The caller provides its own implementation:

```ruby
# HTML controller presenter
class TurnLightOnPresenter
  attr_reader :redirect, :render

  def success
    @redirect = :lights_path
  end

  def light_not_found
    @render = { template: :edit, status: :unprocessable_entity }
  end
end

presenter = TurnLightOnPresenter.new
turn_light_on.execute(light_id: id, presenter: presenter)
redirect_to presenter.redirect if presenter.redirect
render presenter.render[:template], status: presenter.render[:status] if presenter.render
```

A JSON API caller provides a different implementation:

```ruby
class TurnLightOnJsonPresenter
  attr_reader :body, :status

  def success
    @status = 200
    @body = { ok: true }.to_json
  end

  def light_not_found
    @status = 404
    @body = { errors: ['light_not_found'] }.to_json
  end
end
```

The use case is unchanged. Both callers get exactly the interface they need.

## Testing with the presenter

In tests, a simple struct captures which outcome was called:

```ruby
describe TurnLightOn do
  let(:presenter) { double(:presenter) }
  let(:light_gateway) { instance_double(InMemoryLightGateway) }
  let(:use_case) { described_class.new(light_gateway: light_gateway) }

  context 'when the light exists' do
    before { allow(light_gateway).to receive(:find).and_return({ id: 1, on: false }) }

    it 'calls success on the presenter' do
      expect(presenter).to receive(:success)
      use_case.execute(light_id: 1, presenter: presenter)
    end
  end

  context 'when the light does not exist' do
    before { allow(light_gateway).to receive(:find).and_return(nil) }

    it 'calls light_not_found on the presenter' do
      expect(presenter).to receive(:light_not_found)
      use_case.execute(light_id: 1, presenter: presenter)
    end
  end
end
```

## When to use a presenter

The hash return is simpler — prefer it unless you have a concrete reason to reach for a presenter. Good reasons include:

- Multiple callers that handle outcomes fundamentally differently
- The use case has several distinct outcome paths that the caller must all handle explicitly
- You want the compiler (in typed languages) to enforce that callers handle every outcome

A use case that returns `{ success: true }` or `{ success: false, errors: [...] }` does not need a presenter. A use case that has four distinct outcomes — success, not found, not authorised, validation failure — probably does.

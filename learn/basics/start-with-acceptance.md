# Start with Acceptance Testing


Acceptance testing is where you should start before writing anything. 
Similarly, if in doubt, always check your acceptance tests and go from there.

Here, we're going to be describing something that looks like the A in [ATDD](https://en.wikipedia.org/wiki/Acceptance_test%E2%80%93driven_development), with [BDD](https://en.wikipedia.org/wiki/Behavior-driven_development) in the mix too.

## What is an acceptance test?

It is a high-level set of tests, written from the perspective of the user, showing clear steps through the step.

In BDD the behaviour of the system might be defined light so: 

```cucumber
Given the light is off
When I turn the light on
Then the light is on
```

Here is the same Cumcumber script written as RSpec Ruby:

```ruby
describe 'lighting' do
  let(:system) { LightingSystem.new }
  let(:create_light_use_case) { system.get_use_case(:create_light) }
  let(:turn_light_on_use_case) { system.get_use_case(:turn_light_on) }
  let(:view_light_status_use_case) { system.get_use_case(:view_light_status) }
  
  let(:light_id) do
    response = create_light_use_case.execute
    response[:id]
  end
  
  let(:view_light_status_response) do
    view_light_status_use_case.execute(light_id: light_id)
  end
  
  context 'given the light is off' do
    it 'is off' do
      expect(view_light_status_response[:on]).to be(false)
    end
    
    context 'when I turn the light on' do
      before { turn_light_on_use_case.execute(light_id: light_id) } 
      
      it 'is on' do
        expect(view_light_status_response[:on]).to be(true)
      end
    end
  end
end
```

# Domain

A Domain object models the domain in a way that does not depend on data storage.

A database stores data structures. An object-oriented language holds objects with behaviour. The two forms do not match, and that mismatch is the impedance mismatch. A [Gateway](gateway.md) converts between the two forms.

The hard question is which behaviour belongs in a Domain object, and which behaviour belongs in a [Use Case](use_case.md).

Use this rule: behaviour in a Domain object must be correct for every Use Case in the system.

Specialise Use Cases first. Specialised Use Cases produce an anemic domain model. Move behaviour into a Domain object after the same pattern appears in more than one Use Case.

This code shows a simple Domain object:

```ruby
class Light
   attr_reader :brightness

   def initialize(brightness:)
     @brightness = brightness
   end
end
```

## Alternative Names

* Entities

Made Tech Flavour Clean Architecture uses the name "Domain".

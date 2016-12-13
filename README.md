# clean-architecture

A Clean Architecture Project Structure


## RSpec (RSpec specific test layout)

### spec/acceptance

Contains end-to-end acceptance specs, without the Web Delivery mechanism
These specs call the interface that the Web Delivery mechanism uses

### spec/unit

Contains unit specs

### spec/fixtures

Contains raw fixtures

### spec/test_doubles

Contains "complex" test doubles

## Production Code

### (lib|src)/<insert customer name here>/**

* All customer code should be housed within a Client namespace e.g. ```AcmeIndustries::Financial::UseCase::CreateInvoice```
* All non-customer specfic code should be housed within a MadeTech namespace e.g. ```MadeTech::Authentication::UseCase::Login```

### use_case/

These contain the "Interactor", the Use Cases Framework and Database agnostic code

### domain/

These contain the "Entity" objects

### gateway/

Contains IO adapters (e.g. files, database or API calls)
These construct Domain objects for use by Use Cases, and, save Domain objects given to it

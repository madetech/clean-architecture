---
title: "Clean Architecture: Ruby"
---

# Made Tech Flavour Clean Architecture: Ruby

![Ruby Clean Architecture](clean-architecture.png)

## Testing 
* [RSpec](RSpec.md) (RSpec specific test layout)

## Production Code
``` (lib|src)/<insert customer name here>/**/*.rb```

Put customer code in a client namespace, such as ```AcmeIndustries::Financial::UseCase::CreateInvoice```

Put code that no single customer owns in the MadeTech namespace, such as ```MadeTech::Authentication::UseCase::Login```

* [Use Cases](UseCases.md) use_case/ 
* [Domain](Domain.md) domain/
* [Gateway](Gateway.md) gateway/

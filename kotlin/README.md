---
title: "Clean Architecture: Kotlin"
---

# Made Tech Flavour Clean Architecture: Kotlin 

Example project: [MLD Klean Architecture (Continuous Feedback)](https://github.com/madetech/dojos/tree/67eb97d93135ae0fc54bada70e2d2656f7873b88/mld-klean-architecture)

## [Testing](../learn/ATDD.md)
### Spek

#### Acceptance Test
Read an [executing example here](https://github.com/madetech/dojos/blob/67eb97d93135ae0fc54bada70e2d2656f7873b88/mld-klean-architecture/src/test/kotlin/io/continuousfeedback/core/test/acceptance/TeamNotificationsSpec.kt).

#### Unit Test
Read an [executing example here](https://github.com/madetech/dojos/blob/67eb97d93135ae0fc54bada70e2d2656f7873b88/mld-klean-architecture/src/test/kotlin/io/continuousfeedback/core/test/unit/CreateTeamMemberSpec.kt).


## Production Code

Put customer code in a client package, such as ```com.acmeindustries.widget```

Put code that no single customer owns in the MadeTech namespace, such as ```com.madetech.authentication```

* [Use Cases](UseCases.md) use_case/ 
* [Domain](Domain.md) domain/
* [Gateway](Gateway.md) gateway/

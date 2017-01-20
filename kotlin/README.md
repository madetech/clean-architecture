# Made Tech Flavour Clean Architecture: Kotlin 

Example project: [MLD Klean Architecture (Continuous Feedback)](https://github.com/madetech/dojos/tree/67eb97d93135ae0fc54bada70e2d2656f7873b88/mld-klean-architecture)

## [Testing](../learn/ATDD.md)
### Spek

#### Acceptance Test
An executing [example can be found here](https://github.com/madetech/dojos/blob/67eb97d93135ae0fc54bada70e2d2656f7873b88/mld-klean-architecture/src/test/kotlin/io/continuousfeedback/core/test/acceptance/TeamNotificationsSpec.kt).

#### Unit Test
An executing [example can be found here](https://github.com/madetech/dojos/blob/67eb97d93135ae0fc54bada70e2d2656f7873b88/mld-klean-architecture/src/test/kotlin/io/continuousfeedback/core/test/unit/CreateTeamMemberSpec.kt).


## Production Code

Customer code should be housed within a Client package e.g. ```com.acmeindustries.widget```

Non-customer specfic code should be housed within a MadeTech namespace e.g. ```com.madetech.authentication```

* [Use Cases](UseCases.md) use_case/ 
* [Domain](Domain.md) domain/
* [Gateway](Gateway.md) gateway/

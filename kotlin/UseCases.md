---
title: Clean Architecture: Kotlin Use Cases
---

# Use Cases

Use Cases can be both asynchronous and synchronous.

The primary difference is that a synchronous Use Case will return it's result, and an asynchronous Use Case will call a callback with it's result.

It is possible to generalise the boundary interfaces of these two types of Use Cases.

## Asynchronous Example

Asynchronous use cases provide greater control over rendering to the UI. However they add complexities to testing.

An [example generalisation can be found here](https://github.com/madetech/dojos/blob/master/mld-klean-architecture/src/main/kotlin/com/madetech/clean/usecase/AsynchronousUseCase.kt), 
with [a derivative here](https://github.com/madetech/dojos/blob/master/mld-klean-architecture/src/main/kotlin/io/continuousfeedback/core/usecase/CreateTeamMember.kt) for a specific use case.

```kotlin
package com.acmeindustries.widget.usecase

interface ViewWidgets {
    fun execute(request: Request, presenter: Presenter)
    
    data class Request(...)
    interface Presenter {
        fun onSuccess()
        fun onError()
    }
}
```


## Synchronous Example

Synchronous Use Cases provide a simpler interface for testing, but can make representing failure paths and control over the UI harder to maintain.

```kotlin
package com.acmeindustries.widget.usecase

interface ViewWidgetPerFooBarReport {
    fun execute(request: Request): Response
  
    data class Request(public val fromDate: String, public val endDate: String)
    data class Response(...)
}
```

```kotlin
package com.acmeindustries.widget

import com.acmeindustries.widget.usecase.ViewWidgetPerFooBarReport
import com.acmeindustries.widget.usecase.ViewWidgetPerFooBarReport.*
import com.acmeindustries.widget.domain.Widget

class WidgetPerFooBarReport(val widgetGateway: WidgetGateway) : ViewWidgetPerFooBarReport {
    fun execute(request: Request): Response {
        val widgets = widgetGateway.all()
        //secret sauce here
        return Response(...) //return response populated with data
    }
}

interface WidgetGateway {
    fun all(): List<Widget>
}
```

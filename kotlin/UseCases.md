---
title: "Clean Architecture: Kotlin Use Cases"
---

# Use Cases

A Use Case is synchronous or asynchronous.

A synchronous Use Case returns its result. An asynchronous Use Case passes its result to a callback.

You can generalise the boundary interface of each of the two types.

## Asynchronous Example

An asynchronous Use Case gives you more control over rendering to the UI. An asynchronous Use Case is harder to test.

Read an [example generalisation here](https://github.com/madetech/dojos/blob/master/mld-klean-architecture/src/main/kotlin/com/madetech/clean/usecase/AsynchronousUseCase.kt), 
and [a derivative here](https://github.com/madetech/dojos/blob/master/mld-klean-architecture/src/main/kotlin/io/continuousfeedback/core/usecase/CreateTeamMember.kt) for one specific Use Case.

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

A synchronous Use Case gives you a simpler interface to test. A synchronous Use Case makes failure paths and UI control harder to maintain.

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
        //the report rules go here
        return Response(...) //return the response with the data
    }
}

interface WidgetGateway {
    fun all(): List<Widget>
}
```

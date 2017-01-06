# Use Cases

## Example

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

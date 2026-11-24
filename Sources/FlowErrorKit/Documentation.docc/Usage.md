# How To Use Flow Errors

A general description of the library usage

## Overview

Error handling with FlowErrorKit is performed in three steps:

1. <doc:Usage#Catch-errors-and-turn-them-into-FlowError>
2. <doc:Usage#Present-flow-errors-in-the-user-interface>
3. <doc:Usage#Install-flow-error-handlers-for-specific-error-handling>

### Catch errors and turn them into FlowError

This step is performed by a SwiftUI view.

```swift
import FlowErrorKit
import SwiftUI

struct MyView: View {
    @State private var flowError: FlowError?

    var body: some View {
        Button("Try Me") {
            performFailableAction()
        }
    }

    func performFailableAction() {
        do {
            try failableMethod()
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
        }
    }
}
```

The view knows how to update the user interface, in response to the action chosen by the user after the error has occurred. For example, a `MySheet` view might want to let the user retry the failed action, or dismiss itself when the user acknowledges the failure. To do so, it provides the code to run in the `onCancel` and `onRetry` callbacks of ``FlowError``:

```swift
import FlowErrorKit
import SwiftUI

struct MySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flowError: FlowError?

    var body: some View {
        Button("Try Me") {
            performFailableAction()
        }
    }

    func performFailableAction() {
        do {
            try failableMethod()
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
                .onCancel { _ in dismiss() }
                .onRetry { performFailableAction() }
        }
    }
}
```

> Tip: At this step, most views do not handle specific kinds of errors, and just turn all errors into `FlowError`:
>
> ```swift
> // GOOD: Create a `FlowError` from a generic `catch` clause
> do {
>     try failableMethod()
> } catch {
>     flowError = FlowError(error: error)
> }
> ```
>
> **This is how the library is supposed to be used.** This technique is easy to remember, and reduces opportunities for error mishandling.
>
> Of course, some specific errors need specific handling. For example, a `CancellationError` should generally be ignored. When a `CoreLocation` error with code `denied` occurs, the user should be given the opportunity to open the Settings application and grant the missing permission. When a 401 Unauthorized HTTP error occurs, the user should be able to sign in again. Validation errors should display a message and focus the invalid field. Unrecoverable errors should not let the user retry the failed action.
>
> To this end, views can catch specific errors and perform specific actions, such as adjusting their `FlowError`, or not setting any `FlowError` at all.
>
> However, some errors are always handled in the same way throughout the application, and some errors need to trigger side effects somewhere up in the view hierarchy. In these cases, views should not catch specific errors, and instead let the **flow error handlers** registered in the SwiftUI environment perform their own error handling. Flow error handlers are introduced below.
>
> This is why views that catch specific errors should remain the exception. As far as views are concerned, at this step, their task is only to focus on the user interface by creating a `FlowError` instance with the needed callbacks. For example, provide an `onRetry` callback if the presented error should have a "Retry" button for recoverable errors.

### Present flow errors in the user interface

For example, a view can present an alert when an error occurs:

```swift
import FlowErrorKit
import SwiftUI

struct MyView: View {
    @State private var flowError: FlowError?

    var body: some View {
        Button("Try Me") {
            performFailableAction()
        }
        // Capture and present the flow error
        .presentError($flowError, with: .alert)
    }

    func performFailableAction() {
        do {
            try failableMethod()
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
        }
    }
}
```

There are other error presentation options, such as displaying an ``ErrorPresentationView`` instead of an alert.

> Tip: Make sure a SwiftUI view presents all flow errors, without exception, with an alert or another technique:
>
> ```swift
> // GOOD: Present all errors with an alert
> struct MyView: View {
>     @State private var flowError: FlowError?
>
>     var body: some View {
>         ContentView()
>             .presentError($flowError, with: .alert)
>     }
> }
> ```
>
> **This is how the library is supposed to be used.** This technique is easy to remember, and reduces opportunities for error mishandling.
>
> Granted, not all errors should be presented as an alert to the application user. For example, errors that represent user cancellation should not be presented at all. Validation errors should highlight invalid fields instead of showing an alert. HTTP errors such as 401 Unauthorized need specific handling. These cases are handled by **flow error handlers**, introduced below.
>
> As far as views are concerned, at this step, their task is to always be ready to present the error to the user.

### Install flow error handlers for specific error handling

The library comes with a default chain of error handlers (see ``FlowErrorHandlerChain/default``) that handles `CancellationError`, `CocoaError`, and `URLError`. Errors that are not handled by any error handler are presented with a generic, redacted, title. In the Debug configuration, the built-in presentations (alerts and ``ErrorPresentationView``) also display the raw error, so that developers can see what went wrong.

Below is a screenshot from the test app that shows the default presentation of an unhandled error when the library is compiled in the Debug configuration:

@Image(source: "DefaultErrorHandlerDEBUG.png", alt: "A screenshot from the test app that shows a standard alert. The title is \"An Error Occurred\". The message is \"DEBUG: ServerError(statusCode: 500)\", the raw description of the unhandled error. The alert has one OK button.")

Custom error handlers can alter the default behavior, and choose if and how an error should be presented. They conform to the ``FlowErrorHandler`` protocol, and must be registered in the SwiftUI environment with FlowErrorKit APIs. Once registered in the SwiftUI environment, an error handler can handle all errors caught in the SwiftUI view hierarchy.

One important task of flow error handlers is to define which message and buttons should be presented when a SwiftUI view displays the error. For example, you can register a `CLErrorHandler` that is responsible for all instances of `CLError` throughout the application:

```swift
// MyApp.swift
import SwiftUI
import FlowErrorKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MyView()
                .handleError(with: CLErrorHandler())
        }
    }
}

// CLErrorHandler.swift
import CoreLocation
import FlowErrorKit
import UIKit

// Handles CoreLocation errors.
struct CLErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? CLError else {
            // Not a CLError: pass to the next error handler.
            return .pass(flowError)
        }
        
        switch error {
        case CLError.denied:
            // Denied error is not recoverable: drop the retry action, and
            // let the user grant the required permissions.
            let presentedFlowError = flowError
                .droppingRetryAction()
                .appendingAction("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            
            return .present(ErrorPresentation(
                flowError: presentedFlowError,
                title: "Permission Required")
                .withMessage("Please grant access to your location in the Settings application."))
            
        case CLError.geocodeCanceled:
            // Don't present this error
            return .cancel
            
        default:
            return .present(ErrorPresentation(
                flowError: flowError,
                message: error.localizedDescription))
        }
    }
}
```

See ``FlowErrorHandler`` for more information and use cases of flow error handlers.

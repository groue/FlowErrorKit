# How To Use Flow Errors

A general description of the library usage

## Overview

Error handling with FlowErrorKit is performed in three steps:

1. <doc:Usage#Catch-and-present-errors>
2. <doc:Usage#Describe-the-failed-operation-and-its-actions>
3. <doc:Usage#Handle-specific-errors-with-flow-error-handlers>

### Catch and present errors

A SwiftUI view catches errors, turns them into a ``FlowError``, and presents them with the ``SwiftUICore/View/presentError(_:with:)`` method. For example, the view below presents errors with an alert:

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
        // ╭───────────────────────────╮
        // │ The Internet connection   │
        // │ appears to be offline.    │
        // ├───────────────────────────┤
        // │            OK             │
        // ╰───────────────────────────╯
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

There are other error presentation options, such as displaying an ``ErrorPresentationView`` in place of the view content (see ``FlowErrorPresenter/errorPresentationView``).

> Tip: Most views do not handle specific kinds of errors. They turn all errors into `FlowError`, and present all flow errors:
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
> **This is how the library is supposed to be used.** This technique reduces opportunities for error mishandling.
>
> Of course, some specific errors need specific handling. For example, a `CancellationError` should generally be ignored. When a `CoreLocation` error with code `denied` occurs, the user should be given the opportunity to open the Settings application and grant the missing permission. When a 401 Unauthorized HTTP error occurs, the user should be able to sign in again. Validation errors should display a message and focus the invalid field, instead of showing an alert. Unrecoverable errors should not let the user retry the failed action.
>
> To this end, views can catch specific errors and perform specific actions, such as adjusting their `FlowError`, or not setting any `FlowError` at all.
>
> However, some errors are always handled in the same way throughout the application, and some errors need to trigger side effects somewhere up in the view hierarchy. In these cases, views should not catch specific errors, and instead let the **flow error handlers** registered in the SwiftUI environment perform their own error handling. Flow error handlers are introduced in <doc:Usage#Handle-specific-errors-with-flow-error-handlers>.
>
> This is why views that catch specific errors should remain the exception. As far as views are concerned, their task is only to focus on the user interface: always be ready to present errors, and create `FlowError` instances with a title and the needed callbacks, as described in the next section.

### Describe the failed operation and its actions

The view that catches an error knows which operation has failed, and how to update the user interface in response to the action chosen by the user after the error has occurred. This makes it the right place to provide:

- The **cancel action**, with the `onCancel` callback of ``FlowError``. For example, a `MySheet` view might want to dismiss itself when the user acknowledges the failure.
- The **retry action**, with the `onRetry` callback, so that the user can retry the failed action.
- The **title**, with the `withTitle` method, which describes the failure to the user. The title is optional. But without a title, the user is only told what went wrong, not which operation has failed.

For example:

```swift
import FlowErrorKit
import SwiftUI

struct MySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flowError: FlowError?

    var body: some View {
        Button("Save") {
            save()
        }
        // ╭───────────────────────────────╮
        // │ Could not save the document   │
        // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
        // │ The Internet connection       │
        // │ appears to be offline.        │
        // ├───────────────┬───────────────┤
        // │    Cancel     │     Retry     │
        // ╰───────────────┴───────────────╯
        .presentError($flowError, with: .alert)
    }

    func save() {
        do {
            try saveDocument()
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
                .withTitle("Could not save the document")
                .onCancel { _ in dismiss() }
                .onRetry { save() }
        }
    }
}
```

The view does not have to check whether the error can be retried before it provides a retry action: removing the retry action of unrecoverable errors is the job of flow error handlers, described below. See <doc:FlowError#Error-Actions> for the list of error actions.

### Handle specific errors with flow error handlers

FlowErrorKit comes with ready-made handling of `CancellationError`, `CocoaError`, `URLError`, and `POSIXError`, so that they are handled in the best way for the application user. Other errors are, by default, presented with a generic, localized, title: "An Error Occurred". In the Debug configuration, the built-in presentations (alerts and ``ErrorPresentationView``) also display the raw error, so that developers can see what went wrong.

Below is a screenshot that shows the default presentation of an unhandled error in an alert, when the library is compiled in the Debug configuration:

@Image(source: "DefaultErrorHandlerDEBUG.png", alt: "An iPhone that displays a profile form, and a standard alert. The title is \"An Error Occurred\". The message is \"DEBUG: ServerError(statusCode: 401)\", the raw description of the unhandled error. The alert has one OK button.")

Custom error handlers can alter the default behavior, and choose if and how an error should be presented. They conform to the ``FlowErrorHandler`` protocol, and must be registered in the SwiftUI environment with the ``SwiftUICore/View/handleError(with:)`` view modifier. Once registered in the SwiftUI environment, an error handler can handle all flow errors presented in the SwiftUI view hierarchy below.

One important task of flow error handlers is to define which message and buttons should be presented when a SwiftUI view displays the error. For example, the application below registers a `CLErrorHandler` that is responsible for all instances of `CLError` throughout the application:

```swift
// MyApp.swift
import FlowErrorKit
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MyView()
        }
        .handleError(with: CLErrorHandler())
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
            return .pass(flowError)
        }

        switch error {
        case CLError.denied:
            // Denied error is not recoverable: drop the retry
            // action, and let the user grant the required
            // permissions.
            let presentedFlowError = flowError
                .droppingRetryAction()
                .appendingAction("Open Settings") {
                    openSettings()
                }

            return .present(ErrorPresentation(
                flowError: presentedFlowError,
                title: "Permission Required")
                .withMessage("""
                    Please grant access to your location \
                    in the Settings application.
                    """))

        case CLError.geocodeCanceled:
            // Don't present this error
            return .cancel

        default:
            return .present(ErrorPresentation(
                flowError: flowError,
                message: error.localizedDescription))
        }
    }

    func openSettings() {
        let string = UIApplication.openSettingsURLString
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
}
```

See ``FlowErrorHandler`` for more information and use cases of flow error handlers.

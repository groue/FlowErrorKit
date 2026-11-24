# ``FlowErrorKit/FlowErrorHandler``

A type that handles flow errors by performing side effects and determining how an error should be presented to the user.

## Overview

`FlowErrorHandler` is designed for SwiftUI integration. When an error handler enters the SwiftUI environment with the ``SwiftUICore/View/handleError(with:)`` view modifier, it can handle all presented flow errors, as specified by its ``handle(_:)`` method. For example:

```swift
// MyErrorHandler.swift
import FlowErrorKit

struct MyErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        if flowError.error is MyError {
            // Specific handling for MyError
            return .present(ErrorPresentation(
                flowError: flowError,
                title: "My Error Occurred"))
        } else {
            // Not MyError: pass to the next error handler.
            return .pass(flowError)
        }
    }
}

// MyView.swift
import FlowErrorKit
import SwiftUI

struct MyView: View {
    var body: some View {
        ContentView()
            .handleError(with: MyErrorHandler())
    }
}
```

### The Chain of Flow Error Handlers

As multiple error handlers enter the SwiftUI environment, they build a **chain of error handlers**.

When a flow error happens, the ``handle(_:)`` method of the first handler in the chain is called. It allows the handler to decide whether:

- The flow error is passed to the next handler in the chain.
- The flow error is presented to the user (ignoring remaining handlers in the chain).
- The flow error is cancelled (not presented, ignoring remaining handlers in the chain).

At the end of the chain, if no error handler has presented or cancelled the error, a default presentation is performed.

The position of a handler in the chain depends on where it is registered in the view hierarchy: handlers registered closer to the presenting view come first. In the following sample code, the error presented by `MyView` is handled by `ErrorHandlerC` first, then `ErrorHandlerB`, and finally `ErrorHandlerA`.

```swift
struct MyContainerView: View {
    var body: some View {
        MyView()
            .handleError(with: ErrorHandlerB())
            .handleError(with: ErrorHandlerA())
    }
}

struct MyView: View {
    @State private var flowError: FlowError?

    var body: some View {
        Button("Try Me") {
            performFailableAction()
        }
        // Capture and present the flow error
        
        // Handled by ErrorHandlerC first, then ErrorHandlerB,
        // and finally ErrorHandlerA.
        .presentError($flowError, with: .alert)

        .handleError(with: ErrorHandlerC())
    }

    func performFailableAction() {
        do {
            try failableMethod()
        } catch {
            flowError = FlowError(error: error)
        }
    }
}
```

### Observable Objects as FlowError Handlers

When an observable object conforms to `FlowErrorHandler`, it can update its inner state for particular flow errors, thrown anywhere in the view hierarchy.

In the example below, a form submission may fail because the user session has expired. Instead of presenting an alert, the session model, installed at the root of the app, signs the user out:

```swift
// Session.swift
import FlowErrorKit
import Observation

@MainActor @Observable final class Session {
    var isSignedIn = true
}

extension Session: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        if flowError.error is UnauthorizedError {
            // Don't present the error, and sign out instead.
            isSignedIn = false
            return .cancel
        } else {
            // Not an UnauthorizedError: pass to the next error handler.
            return .pass(flowError)
        }
    }
}

// RootView.swift
import FlowErrorKit
import SwiftUI

struct RootView: View {
    @State private var session = Session()

    var body: some View {
        Group {
            if session.isSignedIn {
                FormView()
            } else {
                SignInView()
            }
        }
        .handleError(with: session)
    }
}

// FormView.swift
import FlowErrorKit
import SwiftUI

struct FormView: View {
    @State private var name = ""
    @State private var flowError: FlowError?

    var body: some View {
        Form {
            TextField("Name", text: $name)
            Button("Submit") {
                do {
                    // May throw UnauthorizedError
                    try submit(name)
                } catch {
                    flowError = FlowError(error: error)
                }
            }
        }
        .presentError($flowError, with: .alert)
    }
}
```

## Topics

### Customize flow error handling

- ``handle(_:)-(FlowError)``
- ``handle(_:)-(Error)``

### Built-in Error Handlers

- ``CancellationErrorHandler``
- ``CocoaErrorHandler``
- ``URLErrorHandler``

### Supporting Types

- ``AnyFlowErrorHandler``
- ``FlowErrorHandling``

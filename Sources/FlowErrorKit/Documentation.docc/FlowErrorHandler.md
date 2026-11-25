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

Besides choosing how an error is presented, an error handler can add or remove the actions of a flow error, with methods such as ``FlowError/appendingAction(_:role:action:)-(LocalizedStringKey,_,_)`` and ``FlowError/droppingRetryAction()``. <doc:FlowError#Error-Actions> describes which actions are best handled by error handlers.

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

### Sharing Handlers Between the App and Its Previews

Application-wide error handlers are usually registered on the scene, with ``SwiftUI/Scene/handleError(with:)``, so that they apply to all windows. SwiftUI previews, however, do not run the `App` body, and do not use these handlers. For previews to present errors as the app does, the application-wide handlers can be declared once, in a ``FlowErrorHandlerChain``:

```swift
extension FlowErrorHandler where Self == FlowErrorHandlerChain {
    static var appErrorHandlers: Self {
        FlowErrorHandlerChain([
            MyErrorHandler(),
            CLErrorHandler(),
        ])
    }
}
```

The chain only contains the handlers of the application: the ready-made handling of `CancellationError`, `CocoaError`, and `URLError` provided by FlowErrorKit always comes last, after all registered handlers (see ``SwiftUICore/EnvironmentValues/errorHandler``).

This chain is then registered in the app, and in every preview:

```swift
WindowGroup { RootView() }
    .handleError(with: .appErrorHandlers)

#Preview {
    RecipeListView()
        .handleError(with: .appErrorHandlers)
}
```

## Topics

### Customize flow error handling

- ``handle(_:)-(FlowError)``
- ``handle(_:)-(Error)``

### Supporting Types

- ``AnyFlowErrorHandler``
- ``FlowErrorHandling``

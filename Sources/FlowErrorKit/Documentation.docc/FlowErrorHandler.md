# ``FlowErrorKit/FlowErrorHandler``

A type that handles flow errors by performing side effects and determining how an error should be presented to the user.

## Overview

`FlowErrorHandler` is designed for SwiftUI integration. When an error handler enters the SwiftUI environment with the ``SwiftUICore/View/handleError(with:)`` view modifier, it handles the flow errors presented by the modified view and its subviews, as specified by its ``handle(_:)-(FlowError)`` method. For example:

```swift
// MyErrorHandler.swift
import FlowErrorKit

struct MyError: Error { }

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

When a view presents a flow error, the ``handle(_:)-(FlowError)`` method of the first handler in the chain is called. It allows the handler to decide whether:

- The flow error is passed to the next handler in the chain.
- The flow error is presented to the user (ignoring remaining handlers in the chain).
- The flow error is cancelled (not presented, ignoring remaining handlers in the chain).

The position of a handler in the chain depends on where it is registered: handlers registered closer to the presenting view come first, and handlers registered on the scene come after the handlers registered on views. In the following sample code, the error presented by `MyView` is handled by `ErrorHandlerC` first, then `ErrorHandlerB`, and finally `ErrorHandlerA`.

```swift
import FlowErrorKit
import SwiftUI

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

The chain always ends with the ready-made handling that FlowErrorKit provides for `CancellationError`, `CocoaError`, `URLError`, and `POSIXError`. Because it comes last, the registered handlers can customize the handling of those errors. Finally, if no error handler has presented or cancelled the flow error, it is presented with a default presentation (see ``FlowErrorHandling/errorPresentation``).

The chain of handlers that apply to a view is available in the ``SwiftUICore/EnvironmentValues/errorHandler`` environment value.

### Adjusting Actions and Presentations

An error handler can pass or present a modified flow error, built with methods such as:

- ``FlowError/droppingRetryAction()`` removes the retry action of errors that retrying cannot fix.
- ``FlowError/appendingAction(_:role:action:)-(LocalizedStringKey,_,_)`` adds a supplementary action, such as an "Open Settings" action for errors that report a missing permission.
- ``FlowError/withError(_:)`` replaces the error, so that the next handlers in the chain can handle an underlying error (see ``FlowErrorHandlerChain/init(_:)``).

For example, the handler below asks the user to update the application when the server rejects its requests with the 426 Upgrade Required status code:

```swift
import FlowErrorKit
import UIKit

struct ServerError: Error {
    var statusCode: Int
}

struct UpgradeRequiredErrorHandler: FlowErrorHandler {
    var appStoreURL: URL

    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? ServerError,
              error.statusCode == 426
        else {
            return .pass(flowError)
        }

        // Retrying won't help: drop the retry action, and let
        // the user open the App Store.
        let presentedFlowError = flowError
            .droppingRetryAction()
            .appendingAction("Update") {
                UIApplication.shared.open(appStoreURL)
            }

        return .present(ErrorPresentation(
            flowError: presentedFlowError,
            title: "Update Required")
            .withMessage("""
                Please install the latest version \
                of the application.
                """))
    }
}
```

An error handler must not perform the actions of the flow error: the presenter and the user do. Nor must it add code to run with ``FlowError/onCancel(action:)`` or ``FlowError/finally(action:)``, because this code is not guaranteed to run (see ``handle(_:)-(FlowError)``).

### Observable Objects as FlowError Handlers

When an observable object conforms to `FlowErrorHandler`, it can update its inner state for particular flow errors, presented anywhere in the view hierarchy.

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
            UpgradeRequiredErrorHandler(appStoreURL: appStoreURL),
        ])
    }
}
```

Register this chain in the app, and in every preview:

```swift
WindowGroup { RootView() }
    .handleError(with: .appErrorHandlers)

#Preview {
    RecipeListView()
        .handleError(with: .appErrorHandlers)
}
```

Once registered with `handleError`, the application handlers run before the ready-made handling that FlowErrorKit provides for `CancellationError`, `CocoaError`, `URLError`, and `POSIXError`.

## Topics

### Customize flow error handling

- ``handle(_:)-(FlowError)``
- ``handle(_:)-(Error)``

### Supporting Types

- ``AnyFlowErrorHandler``
- ``FlowErrorHandling``

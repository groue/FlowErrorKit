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
                title: "My Error Occurred",
                flowError: flowError))
        } else {
            // Not MyError: pass to the next error handler.
            return .pass(flowError)
        }
    }
}

// MyView.swift
import FlowErrorKit

struct MyView: View {
    var body: some View {
        ContentView()
            .handleError(with: MyErrorHandler())
    }
}
```

## The Chain of Flow Error Handlers

As multiple error handlers enter the SwiftUI environment, they build a **chain of error handlers**.

When a flow error happens, the ``handle(_:)`` method of the first handler in the chain is called. It allows the handler to decide whether:

- The flow error is passed to the next handler in the chain.
- The flow error is presented to the user (ignoring remaining handlers in the chain).
- The flow error is cancelled (not presented, ignoring remaining handlers in the chain).

At the end of the chain, if no error handler has presented or cancelled the error, a default presentation is performed.

The position of a handler in the chain depends on the view that enqueues it in the SwiftUI environment. In the following sample code, the error presented by `MyView` is handled by `ErrorHandlerC` first, then `ErrorHandlerB`, and finally `ErrorHandlerA`.

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

## Observable Objects as FlowError Handlers

When an observable objects conforms to `FlowErrorHandler`, it can update its inner state for particular flow errors:

```swift
// MyViewModel.swift
import FlowErrorKit

@MainActor @Observable final class MyViewModel {
    // Updated when the view model catches a ValidationError.
    var errorLabel: String?
    ...
}

extension MyViewModel: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        if flowError.error is ValidationError {
            // Don't present the error, and display
            // a validation message instead:
            self.errorLabel = "Please fix your input"
            return .cancel
        } else {
            // Not a ValidationError: pass to the next error handler.
            return .pass(flowError)
        }
    }
}

// MyView.swift
import FlowErrorKit

struct MyView: View {
    @State var viewModel = MyViewModel()

    var body: some View {
        ContentView(errorLabel: viewModel.errorLabel)
            .handleError(with: viewModel)
    }
}
```

## Topics

### Customize flow error handling

- ``handle(_:)``

### Built-in Error Handlers

- ``CancellationErrorHandler``
- ``CocoaErrorHandler``
- ``URLErrorHandler``

### Supporting Types

- ``AnyFlowErrorHandler``
- ``FlowErrorHandling``

# ``FlowErrorKit/FlowError``

`FlowError` defines which actions are available after an error was caught.

## Overview

In the typical setup, a `FlowError` is created when an `Error` is caught, and the view presents the error with the ``SwiftUICore/View/presentError(_:with:)-7sikc`` method:

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

### Error Actions

`FlowError` allows the view to specify the **error actions** that the user can select when the error is presented:

- The **Cancel action** is run when the user hits the "Cancel" button:

    ```swift
    flowError = FlowError(error: error)
        .onCancel { _ in print("Cancelled") })
    ```

- The **Retry action** is run when the user hits the "Retry" button:

    ```swift
    flowError = FlowError(error: error)
        .onRetry { performFailableAction() })
    ```

- **Supplementary actions** can be provided if necessary, and they will be presented to the user:

    ```swift
    flowError = FlowError(error: error)
        .appendingAction("Repair") { repair() }
    ```

- The optional "finally" closure is run at the end of all error actions (cancel, retry, supplementary actions):

    ```swift
    flowError = FlowError(error: error)
        .finally { print("Error was handled") }
    ```

### Detailed Actions Handling

As long as the flow error is presented by the SwiftUI view, it is guaranteed that one error action will be performed:

- The performed action is the one selected by the user in the alert presented by the ``SwiftUICore/View/presentError(_:with:)-7sikc`` method.
- If a ``FlowErrorHandler`` cancels the error presentation, then the cancel action is automatically run.
- If a ``FlowErrorHandler`` appends a supplementary action, and the user selects it, then the cancel action is run before the supplementary action is run.
- If a view wants to present a new flow error while a previous one is still presented on screen, then the new error is not presented and its cancel action is run.

There are two exceptions:

- When a flow error is programmatically dismissed, no error action is run. The cancel action can be explicitly performed if deemed necessary, as below:

    ```swift
    struct MyView: View {
        @State private var flowError: FlowError?

        var body: some View {
            ContentView()
                .presentError($flowError, with: .alert)
        }

        func dismissError() {
            flowError?.discard(.presentationCancelled)
            flowError = nil
        }
    }
    ```

- ⚠️ When SwiftUI prevents the error presentation (because some unexpected modal alert or sheet is already presented), no error action is run. This is a known issue, and a future version of `FlowErrorKit` will have to handle this.

## Topics

### Creating a flow error

- ``init(error:allowMultipleActionExecutions:)``

### Flow error information

- ``error``
- ``cancelAction``
- ``retryAction``
- ``title``
- ``supplementaryActions``
- ``isSameError(as:)``

### Performing actions

- ``performAction(_:)``
- ``performCancelAction()``
- ``discard(_:)``

### Transforming flow errors

- ``onCancel(_:_:)-(LocalizedStringResource?,_)``
- ``onCancel(_:_:)-(String,_)``
- ``onCancel(verbatim:_:)-(String,_)``
- ``onRetry(_:)``
- ``onRetry(_:_:)``
- ``appendingAction(_:)``
- ``appendingAction(_:role:perform:)``
- ``droppingRetryAction()``
- ``finally(_:)``
- ``withError(_:)``
- ``withTitle(_:)``

### Supporting Types

- ``ErrorAction``
- ``CancelErrorAction``
- ``CancelErrorReason``

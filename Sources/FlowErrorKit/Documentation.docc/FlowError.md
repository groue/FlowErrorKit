# ``FlowErrorKit/FlowError``

`FlowError` defines which actions are available after an error has been caught.

## Overview

In the typical setup, a `FlowError` is created when an `Error` is caught, and the view presents the error with the ``SwiftUICore/View/presentError(_:with:)`` method:

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

### Where to Create Flow Errors

A good practice is to always create a `FlowError` from a `catch` clause, or from a callback that delivers each error once. Think of a `FlowError` as an event: an error was caught, and now it needs to be handled.

Avoid creating or handling flow errors from a view `body`, which SwiftUI evaluates many times. The same error could then be handled several times, and the flow error handlers registered in the SwiftUI environment could perform their side effects several times (see ``FlowErrorHandler``).

### Error Actions

`FlowError` allows the view to specify the **error actions** that the user can select when the error is presented:

- The **Cancel action** is run when the user dismisses the error, and in the other situations described in <doc:FlowError#Detailed-Actions-Handling>:

    ```swift
    flowError = FlowError(error: error)
        .onCancel { _ in print("Cancelled") }
    ```

- The **Retry action** is run when the user hits the "Retry" button. It is useful when the screen does not let the user run the failed operation again easily, or at all:

    ```swift
    flowError = FlowError(error: error)
        .onRetry { performFailableAction() }
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

> Tip: Besides the code that creates the flow error, error handlers can also add or remove actions before the error is presented (see ``FlowErrorHandler``). Each one is in a good position to decide about different actions:
>
> - The code that creates the flow error has run the failed operation, and knows what failed. This makes it the right place for the actions that depend on this operation, such as retrying it, or deleting a document that failed to load.
> - An error handler only sees the error, whatever the operation that failed. This makes it the right place for the actions that depend on the kind of error, such as an "Open Settings" action for `CLError.denied`, or the removal of the retry action for errors that retrying can't fix. This is why the code that creates the flow error can add a retry action without checking the error.

### Detailed Actions Handling

By default, once a flow error is given to ``SwiftUICore/View/presentError(_:with:)``, error actions are executed at most once:

- The performed action is the one selected by the user in the presentation.
- If a ``FlowErrorHandler`` cancels the error presentation, then the cancel action is automatically run.
- If the user selects a supplementary action, then the cancel action is run before the supplementary action.
- If a view wants to present a new flow error while a previous one is still presented on screen, then one of the errors is not presented and its cancel action is run (which one depends on the presenter provided to ``SwiftUICore/View/presentError(_:with:)``).

There are cases where no action is run, or actions are run multiple times:

- When a flow error is programmatically dismissed, no error action is run. The cancel action can be explicitly performed if deemed necessary, as below:

    ```swift
    struct MyView: View {
        @State private var flowError: FlowError?

        var body: some View {
            ContentView()
                .presentError($flowError, with: .alert)
        }

        func dismissError() {
            flowError?.discard()
            flowError = nil
        }
    }
    ```

- Some presentations do not offer every action. For example, the ``FlowErrorPresenter/errorPresentationView`` presentation hides the Cancel button by default, and stays idle until the flow error binding is set to nil. Unless the user selects the retry action or a supplementary action, no action is performed.

- Some presentations allow the application user to run multiple actions. For example, the ``FlowErrorPresenter/errorPresentationView`` presentation remains on screen until the flow error binding is set to nil. When such a case is expected, set the `allowMultipleActionExecutions` flag when you create the `FlowError` instance with ``FlowError/init(error:allowMultipleActionExecutions:)``, so that action buttons do not become disabled after the user has selected one.

- When SwiftUI itself prevents the error presentation, for example because an alert that is not managed by FlowErrorKit is already presented, no error action is run. It is the programmer's responsibility to avoid such conflicts.

> Tip: As described above, the cancel action does not only run when the user dismisses the error. So code that must run whatever the outcome fits best in `finally`, and code that is specific to an action fits best in the closure of this action:
>
> ```swift
> // Dismiss the screen whatever happens.
> flowError = FlowError(error: error)
>     .appendingAction("Delete Document", role: .destructive) {
>         deleteDocument()
>     }
>     .finally { dismiss() }
>
> // Dismiss the screen after deletion only.
> flowError = FlowError(error: error)
>     .appendingAction("Delete Document", role: .destructive) {
>         deleteDocument()
>         dismiss()
>     }
> ```
>
> When some code must only run in some of the situations of the cancel action, the ``ErrorCancelReason`` argument of `onCancel` tells which situation occurred.

### Localization

Like SwiftUI `Text`, the titles of flow errors and actions are localized when you provide a string literal, and displayed verbatim when you provide a `String`:

```swift
FlowError(error: error).withTitle("Could not save")  // localized
FlowError(error: error).withTitle(serverMessage)     // verbatim
```

## Topics

### Creating a flow error

- ``init(error:allowMultipleActionExecutions:)``

### Flow error information

- ``error``
- ``cancelTitle``
- ``retryAction``
- ``supplementaryActions``
- ``title``
- ``id``

### Performing actions

- ``performAction(_:)``
- ``performCancelAction()``
- ``discard(_:)``
- ``canPerformAction``

### Transforming flow errors

- ``onCancel(action:)``
- ``onCancel(_:action:)-(LocalizedStringKey,_)``
- ``onCancel(_:action:)-(LocalizedStringResource,_)``
- ``onCancel(_:action:)-(StringProtocol,_)``
- ``onCancel(verbatim:action:)``
- ``onRetry(action:)``
- ``onRetry(_:action:)-(LocalizedStringKey,_)``
- ``onRetry(_:action:)-(LocalizedStringResource,_)``
- ``onRetry(_:action:)-(StringProtocol,_)``
- ``onRetry(verbatim:action:)``
- ``appendingAction(_:)``
- ``appendingAction(_:role:action:)-(LocalizedStringKey,_,_)``
- ``appendingAction(_:role:action:)-(LocalizedStringResource,_,_)``
- ``appendingAction(_:role:action:)-(StringProtocol,_,_)``
- ``appendingAction(verbatim:role:action:)``
- ``droppingRetryAction()``
- ``finally(action:)``
- ``withError(_:)``
- ``withTitle(_:)-(LocalizedStringKey)``
- ``withTitle(_:)-(LocalizedStringResource)``
- ``withTitle(_:)-(StringProtocol)``
- ``withTitle(verbatim:)``

### Supporting Types

- ``ErrorAction``
- ``ErrorCancelReason``

# ``FlowErrorKit``

An error handling library

## Links

- [GitHub repository](https://github.com/groue/FlowErrorKit)

## Overview

FlowErrorKit helps you catch runtime errors, define how they should be presented in the user interface, and how to respond to user actions after an error has occurred.

For example, your application may:

- Display an alert in response to a failed network operation.
- Display validation error messages directly in a form view.
- Display a login screen in response to a 401 Unauthorized HTTP error.
- Let the user retry a failed operation.
- Let the user open the Settings application and grant a necessary permission.

## Topics

### Getting Started

- <doc:Usage>
- ``FlowError``

### Handling Errors from SwiftUI views

Handling a flow error means performing side effects and determining how the error should be presented to the user.

- ``SwiftUICore/View/handleError(with:)``
- ``SwiftUICore/View/handleError(handling:)``
- ``SwiftUICore/View/handleError(ofType:matching:handling:)``
- ``SwiftUI/Scene/handleError(with:)``
- ``FlowErrorHandler``

### Presenting Errors from SwiftUI views

Presenting a flow error means displaying the error in SwiftUI views.

- ``SwiftUICore/View/presentError(_:with:)-(_,FlowErrorPresenter)``
- ``ErrorPresentation``
- ``ErrorPresentationView``
- ``ErrorPresentationLabel``
- ``ErrorPresentationDescription``
- ``ErrorPresentationActions``
- ``FlowErrorPresenter``
- ``TextSource``

### SwiftUI Environment

- ``SwiftUICore/EnvironmentValues/errorHandler``
- ``FlowErrorHandlerChain``

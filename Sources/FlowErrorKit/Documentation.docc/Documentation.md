# ``FlowErrorKit``

An error handling library

## Overview

FlowErrorKit helps you catch runtime errors, define how they should be presented in the user interface, and how to respond to user actions after an error has occurred.

For example, your application may:

- Display an alert in response to a failed network operation.
- Display validation error messages right into a form view.
- Display a login screen in response to a 401 Unauthorized HTTP error.
- Let the user retry a failed operation.
- Let the user open the Settings application and grant a necessary permission.

## Topics

### Getting Started

- <doc:Usage>
- ``FlowError``

### Handling Errors from SwiftUI views

Handling a flow error is performing side effects and determining how the error should be presented to the user.

- ``SwiftUICore/View/handleError(with:)``
- ``SwiftUICore/View/handleError(_:)``
- ``SwiftUICore/View/handleError(ofType:_:)``
- ``SwiftUI/Scene/handleError(with:)``
- ``FlowErrorHandler``

### Presenting Errors from SwiftUI views

Presenting a flow error is displaying the error in SwiftUI views.  

- ``SwiftUICore/View/presentError(_:with:)-7sikc``
- ``SwiftUICore/View/presentError(_:with:)-3oiaj``
- ``ErrorPresentation``
- ``ErrorPresentationView``
- ``SwiftUI/ContentUnavailableView/error(_:cancelActionVisible:)``
- ``SwiftUI/ContentUnavailableView/error(_:cancelActionVisible:footer:)``
- ``FlowErrorPresenter``

### SwiftUI Environment

- ``SwiftUICore/EnvironmentValues/errorHandler``
- ``FlowErrorHandlerChain``

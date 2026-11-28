# ``FlowErrorKit/FlowErrorPresenter``

A type that presents a flow error from a SwiftUI view.

## Overview

A flow error presenter returns a view modifier that presents
flow errors. To do so, it calls the
``FlowErrorHandlerChain/handle(_:)-(FlowError)``
method on the chain of flow error handlers registered in the SwiftUI
environment (see ``SwiftUICore/EnvironmentValues/errorHandler``).

## Implementing a custom presenter

The view modifier of a presenter receives a binding to an optional
flow error. The presenter is responsible for letting the user perform
the actions of the flow error, and, whenever possible, for never
leaving a flow error unattended (see
<doc:FlowError#Detailed-Actions-Handling>). To do so:

- Read the chain of flow error handlers from the SwiftUI environment,
  with `@Environment(\.errorHandler)`. For every distinct `id` of the bound
  flow error, call ``FlowErrorHandler/handle(_:)-(FlowError)`` on the
  chain, and check the ``FlowErrorHandling/errorPresentation`` property of
  the result.

  When nil, the presentation is cancelled: discard the flow error with
  ``FlowError/discard(_:)``.

  When not nil, display the returned ``ErrorPresentation``, and call
  ``FlowError/performAction(_:)`` or ``FlowError/performCancelAction()``
  in response to user interactions.

  Check the observable property ``FlowError/canPerformAction`` in order to
  avoid multiple action executions for flow errors that were not created with
  the `allowMultipleActionExecutions` flag.

- When the presenter has no flow error to present, set the binding back
  to nil.

- If a new flow error is set while a previous one is presented, either
  replace the presented one, or ignore the new one. In both cases,
  discard the flow error that is not presented, with
  ``ErrorCancelReason/presentationCancelled``.

- If the parent view sets the binding to nil, stop the current presentation,
  if any, but do not perform any action.

For working examples, see the source code of the built-in presenters,
in the `AlertFlowErrorPresenter.swift` and
`ErrorPresentationPresenter.swift` files of FlowErrorKit.

## Topics

### Getting built-in flow error presenters

- ``alert``
- ``errorPresentationView``
- ``errorPresentationView(_:)``

### Creating custom flow error presenters

- ``Modifier``
- ``makeModifier(flowError:)``

### Supporting Types

- ``AlertFlowErrorPresenter``
- ``ErrorPresentationPresenter``

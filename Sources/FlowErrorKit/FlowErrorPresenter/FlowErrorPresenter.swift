import SwiftUI

/// A type that presents a flow error from a SwiftUI view.
///
/// A flow error presenter returns a view modifier that presents
/// flow errors. To do so, it calls the
/// ``FlowErrorHandlerChain/handle(_:)-(FlowError)``
/// method on the chain of flow error handlers registered in the SwiftUI
/// environment (see ``SwiftUICore/EnvironmentValues/errorHandler``).
///
/// ## Implementing a custom presenter
///
/// The view modifier of a presenter receives a binding to an optional
/// flow error. The presenter is responsible for letting the user perform
/// the actions of the flow error, and, whenever possible, for never
/// leaving a flow error unattended (see
/// <doc:FlowError#Detailed-Actions-Handling>). To do so:
///
/// - Read the chain of flow error handlers from the SwiftUI environment,
///   with `@Environment(\.errorHandler)`. Whenever the bound flow error
///   changes, including when the view appears, call
///   ``FlowErrorHandler/handle(_:)-(FlowError)`` on the chain. For
///   example, use `.onChange(of: flowError?.id, initial: true) { ... }`.
///
/// - If a handler cancels the presentation (the result has no
///   ``FlowErrorHandling/errorPresentation``), call
///   ``FlowError/discard(_:)`` with
///   ``ErrorCancelReason/presentationCancelled``, and set the binding
///   back to nil, unless another flow error is currently presented.
///
/// - Otherwise, display the ``ErrorPresentation``. When the user selects
///   an action, call ``FlowError/performAction(_:)`` or
///   ``FlowError/performCancelAction()``. Never call the action
///   closures in any other way.
///
///   Perform a single action, unless the flow error was created with the
///   `allowMultipleActionExecutions` flag. If the user can select an
///   action after another one, for example because the presentation
///   remains on screen, rely on ``FlowError/canPerformAction`` to prevent
///   it.
///
/// - If a new flow error is set while another one is presented, either
///   replace the presented one, or ignore the new one. In both cases,
///   discard the flow error that is not presented, with
///   ``ErrorCancelReason/presentationCancelled``.
///
/// - If the binding is set to nil while a flow error is presented, remove
///   the presentation, without performing any action. When the
///   presentation is dismissed, set the binding back to nil.
///
/// - When the user can no longer select any action of a presented flow
///   error, discard it with ``ErrorCancelReason/presentationCancelled``,
///   and set the binding back to nil. Only do so when the presenter can
///   tell it deterministically:
///
///   - The disappearance of a view does not tell it: when the user
///     switches to another tab and back, an in-place presentation comes
///     back on screen, and the user can still select an action. Do not
///     discard the flow error from `.onDisappear { ... }`.
///   - A `deinit` does not tell it either: your code does not control
///     when it runs.
///
///   A presenter that can not tell when to discard a flow error should
///   document that the application can discard it, with
///   ``FlowError/discard(_:)`` and
///   ``ErrorCancelReason/presentationCancelled``, when the application
///   knows that the user can no longer select any action.
///
/// For working examples, see the source code of the built-in presenters,
/// in the `AlertFlowErrorPresenter.swift` and
/// `ErrorPresentationPresenter.swift` files of FlowErrorKit.
///
/// ## Topics
///
/// ### Getting built-in flow error presenters
///
/// - ``alert``
/// - ``errorPresentationView``
/// - ``errorPresentationView(_:)``
///
/// ### Creating custom flow error presenters
///
/// - ``Modifier``
/// - ``makeModifier(flowError:)``
///
/// ### Supporting Types
///
/// - ``AlertFlowErrorPresenter``
/// - ``ErrorPresentationPresenter``
@MainActor
public protocol FlowErrorPresenter {
    /// The type of view modifier.
    associatedtype Modifier: ViewModifier
    
    /// Returns a view modifier that presents a flow error.
    ///
    /// - parameter flowError: A binding to an optional flow error.
    func makeModifier(flowError: Binding<FlowError?>) -> Modifier
}

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
/// The view modifier of a custom presenter receives a binding to an
/// optional flow error. It must uphold the guarantee that exactly one
/// action of a presented flow error is performed (see
/// <doc:FlowError#Detailed-Actions-Handling>). To do so:
///
/// - Read the chain of flow error handlers from the SwiftUI environment,
///   with `@Environment(\.errorHandler)`.
///
/// - Whenever the bound flow error changes, including when the view
///   appears, call ``FlowErrorHandler/handle(_:)-(FlowError)`` on the
///   chain. For example, use
///   `.onChange(of: flowError?.id, initial: true) { ... }`.
///
/// - If the result has no ``FlowErrorHandling/errorPresentation``
///   (the handler returned ``FlowErrorHandling/cancel``), call
///   ``FlowError/discard(_:)`` with
///   ``ErrorCancelReason/presentationCancelled``, and set the binding
///   back to nil, unless another flow error is currently presented.
///
/// - Otherwise, display the ``ErrorPresentation``. When the user selects
///   an action, call ``FlowError/performAction(_:)`` or
///   ``FlowError/performCancelAction()``. Never call the action
///   closures in any other way.
///
/// - If a new flow error is set while another one is presented, either
///   replace the presented one, or ignore the new one. In both cases,
///   call ``FlowError/discard(_:)`` with
///   ``ErrorCancelReason/presentationCancelled`` on the flow error that
///   is not presented.
///
/// - If the binding is set to nil while a flow error is presented, remove
///   the presentation from the screen, without performing any action
///   (see <doc:FlowError#Detailed-Actions-Handling>).
///
/// - When the presentation is dismissed, set the binding back to nil.
///
/// - When your code knows that the user can no longer select any action
///   of a presented flow error, call ``FlowError/discard(_:)`` with
///   ``ErrorCancelReason/presentationCancelled``, and set the binding
///   back to nil.
///
///   The disappearance of a view does not tell this: when the user
///   switches to another tab and back, an in-place presentation comes
///   back on screen, and the user can still select an action. Do not
///   discard it from `.onDisappear { ... }`. A `deinit` does not tell
///   this either: your code does not control when it runs.
///
///   A presenter that can not tell when to discard a flow error may
///   leave it unhandled forever. Such a presenter should document that
///   the application can discard the flow error by calling
///   ``FlowError/discard(_:)`` with
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
///
/// ### Creating custom flow error presenters
///
/// - ``Modifier``
/// - ``makeModifier(flowError:)``
///
/// ### Supporting Types
///
/// - ``AlertFlowErrorPresenter``
@MainActor
public protocol FlowErrorPresenter {
    /// The type of view modifier.
    associatedtype Modifier: ViewModifier
    
    /// Returns a view modifier that presents a flow error.
    ///
    /// - parameter flowError: A binding to an optional flow error.
    func makeModifier(flowError: Binding<FlowError?>) -> Modifier
}

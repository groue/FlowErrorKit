import SwiftUI

private struct FlowErrorHandlerChainKey: EnvironmentKey {
    static let defaultValue: FlowErrorHandlerChain = {
        MainActor.assumeIsolated { .default }
    }()
}

extension EnvironmentValues {
    /// The chain of flow error handlers in the SwiftUI environment.
    ///
    /// It is built from the flow error handlers registered with
    /// ``SwiftUICore/View/handleError(with:)`` and
    /// ``SwiftUI/Scene/handleError(with:)``, followed by the ready-made
    /// handling that FlowErrorKit provides for `CancellationError`,
    /// `CocoaError`, and `URLError`.
    ///
    /// This ready-made handling comes last, so that the handlers you
    /// register can customize the handling of those errors.
    ///
    /// You use `errorHandler` when you implement a custom
    /// ``FlowErrorPresenter``: see the documentation of this protocol.
    ///
    /// Views that do not intend to present errors can also use
    /// `errorHandler`, in order to trigger side effects.
    ///
    /// For example, if the SwiftUI environment contains a flow error
    /// handler that catches 401 Unauthorized errors and signs out the user,
    /// a view that performs a background network task can make sure those
    /// errors are properly handled:
    ///
    /// ```swift
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// struct MyView: View {
    ///     @Environment(\.errorHandler) var errorHandler
    ///
    ///     var body: some View {
    ///         ContentView().task {
    ///             do {
    ///                 try await someAction()
    ///             } catch {
    ///                 // Don't present the error, but automatically sign out
    ///                 // the user in case of 401 Unauthorized.
    ///                 _ = errorHandler.handle(error)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// An error passed to `errorHandler.handle(_:)` should not also be
    /// turned into a flow error displayed with
    /// ``SwiftUICore/View/presentError(_:with:)``:
    /// the handlers would run twice, and so would their side effects.
    public internal(set) var errorHandler: FlowErrorHandlerChain {
        get { self[FlowErrorHandlerChainKey.self] }
        set { self[FlowErrorHandlerChainKey.self] = newValue }
    }
}

extension View {
    /// Registers a flow error handler in the view.
    ///
    /// Whenever a flow error is presented by the modified view, or one of
    /// its subviews, the handler is invoked before the handlers registered
    /// by the enclosing views.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .presentError($flowError, with: .alert)
    ///             .handleError(with: MyErrorHandler())
    ///     }
    /// }
    /// ```
    ///
    /// In the sample code above, the flow errors presented with
    /// `presentError` are handled by `MyErrorHandler`, because the
    /// `presentError` modifier comes before the `handleError` modifier.
    ///
    /// When several `handleError` modifiers are applied, their handlers
    /// are invoked in the same order as the modifiers:
    ///
    /// ```swift
    /// ContentView()
    ///     .handleError(with: ErrorHandlerA()) // Invoked first
    ///     .handleError(with: ErrorHandlerB()) // Invoked next
    /// ```
    public func handleError(with handler: some FlowErrorHandler) -> some View {
        transformEnvironment(\.errorHandler) {
            $0 = $0.prepending([handler])
        }
    }
    
    /// Registers a closure that handles flow errors.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .presentError($flowError, with: .alert)
    ///             .handleError { flowError in
    ///                 if flowError.error is MyError {
    ///                     // Specific handling for MyError
    ///                     return .present(ErrorPresentation(
    ///                         flowError: flowError,
    ///                         title: "My Error Occurred"))
    ///                 } else {
    ///                     return .pass(flowError)
    ///                 }
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// In the sample code above, the flow errors presented with
    /// `presentError` are handled by the closure, because the
    /// `presentError` modifier comes before the `handleError` modifier.
    ///
    /// This convenience method registers a flow error handler, like the
    /// ``handleError(with:)`` method. For more information about the value
    /// returned by the closure, see ``FlowErrorHandler``.
    ///
    /// - Parameters:
    ///   - handling: A closure that returns how the flow error should
    ///     be handled.
    public func handleError(
        handling: @escaping @MainActor (FlowError) -> FlowErrorHandling
    ) -> some View {
        self.handleError(with: AnyFlowErrorHandler(handling))
    }
    
    /// Registers a closure that handles the flow errors of type `Err` that
    /// match a predicate.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .presentError($flowError, with: .alert)
    ///             .handleError(ofType: MyError.self) { flowError, _ in
    ///                 // Specific handling for MyError
    ///                 return .present(ErrorPresentation(
    ///                     flowError: flowError,
    ///                     title: "My Error Occurred"))
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// In the sample code above, the flow errors presented with
    /// `presentError` are handled by the closure, because the
    /// `presentError` modifier comes before the `handleError` modifier.
    ///
    /// This convenience method registers a flow error handler, like the
    /// ``handleError(with:)`` method. For more information about the value
    /// returned by the closure, see ``FlowErrorHandler``.
    ///
    /// - Parameters:
    ///   - errorType: The type of handled errors.
    ///   - predicate: A closure that returns whether the error should
    ///     be handled.
    ///   - handling: A closure that returns how the flow error should
    ///     be handled.
    public func handleError<Err: Swift.Error>(
        ofType errorType: Err.Type,
        matching predicate: @escaping @MainActor (Err) -> Bool = { _ in true },
        handling: @escaping @MainActor (FlowError, Err) -> FlowErrorHandling
    ) -> some View {
        self.handleError { flowError in
            guard let error = flowError.error as? Err,
                  predicate(error)
            else {
                return .pass(flowError)
            }
            return handling(flowError, error)
        }
    }
}

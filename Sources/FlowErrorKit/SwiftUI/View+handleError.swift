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
    /// handling of `CancellationError`, `CocoaError`, and `URLError`
    /// provided by FlowErrorKit.
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
    /// ``SwiftUICore/View/presentError(_:with:)-(_,FlowErrorPresenter)``:
    /// the handlers would run twice, and so would their side effects.
    public internal(set) var errorHandler: FlowErrorHandlerChain {
        get { self[FlowErrorHandlerChainKey.self] }
        set { self[FlowErrorHandlerChainKey.self] = newValue }
    }
}

extension View {
    /// Registers a flow error handler in the view.
    ///
    /// The handler becomes the first invoked handler whenever a flow error
    /// is presented by this view, or one of its subviews.
    ///
    /// For example:
    ///
    /// ```swift
    /// // MyErrorHandler.swift
    /// import FlowErrorKit
    ///
    /// struct MyErrorHandler: FlowErrorHandler {
    ///     func handle(_ flowError: FlowError) -> FlowErrorHandling {
    ///         if flowError.error is MyError {
    ///             // Specific handling for MyError
    ///             return .present(ErrorPresentation(
    ///                 flowError: flowError,
    ///                 title: "My Error Occurred"))
    ///         } else {
    ///             return .pass(flowError)
    ///         }
    ///     }
    /// }
    ///
    /// // MyView.swift
    /// import FlowErrorKit
    ///
    /// struct MyView: View {
    ///     var body: some View {
    ///         ContentView()
    ///             .handleError(with: MyErrorHandler())
    ///     }
    /// }
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
    ///
    /// struct MyView: View {
    ///     var body: some View {
    ///         ContentView()
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
    /// This convenience method registers a flow error handler. For more
    /// information, see ``FlowErrorHandler``.
    ///
    /// - Parameters:
    ///   - handling: A closure that returns how the flow error should
    ///     be handled.
    public func handleError(
        handling: @escaping @MainActor (FlowError) -> FlowErrorHandling
    ) -> some View {
        self.handleError(with: AnyFlowErrorHandler(handling))
    }
    
    /// Registers a closure that handles flow errors of type `Err`.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    ///
    /// struct MyView: View {
    ///     var body: some View {
    ///         ContentView()
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
    /// This convenience method registers a flow error handler. For more
    /// information, see ``FlowErrorHandler``.
    ///
    /// - Parameters:
    ///   - errorType: The type of handled errors.
    ///   - matching: A closure that returns whether the error should
    ///     be handled.
    ///   - handling: A closure that returns how the flow error should
    ///     be handled.
    public func handleError<Err: Swift.Error>(
        ofType errorType: Err.Type,
        matching: @escaping @MainActor (Err) -> Bool = { _ in true },
        handling: @escaping @MainActor (FlowError, Err) -> FlowErrorHandling
    ) -> some View {
        self.handleError { flowError in
            guard let error = flowError.error as? Err,
                  matching(error)
            else {
                return .pass(flowError)
            }
            return handling(flowError, error)
        }
    }
}

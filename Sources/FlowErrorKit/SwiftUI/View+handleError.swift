import SwiftUI

private struct FlowErrorHandlerChainKey: EnvironmentKey {
    static let defaultValue: FlowErrorHandlerChain = {
        MainActor.assumeIsolated { .default }
    }()
}

extension EnvironmentValues {
    /// The chain of flow error handlers in the SwiftUI environment.
    ///
    /// It is built from the chain of flow error handlers registered with
    /// ``SwiftUICore/View/handleError(with:)``.
    ///
    /// You use `errorHandler` when you implement a custom
    /// ``FlowErrorPresenter``: see the documentation of this protocol.
    ///
    /// Views that do not intend to present errors can also use
    /// `errorHandler`, in order to trigger side effects.
    ///
    /// For example, if the SwiftUI environment contains a flow error
    /// handler that catch 401 Unauthorized and signs out the user, a view
    /// that performs a faceless network task can make sure those errors are
    /// properly handled:
    ///
    /// ```swift
    /// struct MyView {
    ///     @Environment(\.errorHandler) var errorHandler
    ///
    ///     var body {
    ///         content.task {
    ///             do {
    ///                 try await someAction()
    ///             } catch {
    ///                 // Don't present error, but automatically signs out
    ///                 // the user in case of 401 Unauthorized.
    ///                 _ = errorHandler.handle(error)
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    public internal(set) var errorHandler: FlowErrorHandlerChain {
        get { self[FlowErrorHandlerChainKey.self] }
        set { self[FlowErrorHandlerChainKey.self] = newValue }
    }
}

extension View {
    /// Registers a flow error handler in the view.
    ///
    /// The handler becomes the first invoked handler whenever a flow error
    /// is presented by ``SwiftUICore/View/presentError(_:with:)-7sikc``.
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
    ///                 title: "My Error Occurred",
    ///                 flowError: flowError))
    ///         } else {
    ///             // Not MyError: pass to the next error handler.
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
    ///                         title: "My Error Occurred",
    ///                         flowError: flowError))
    ///                 } else {
    ///                     // Not MyError: pass to the next error handler.
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
    ///   - handleError: A closure that returns how the flow error should
    ///     be handled.
    public func handleError(
        _ handleError: @escaping @MainActor (FlowError) -> FlowErrorHandling
    ) -> some View {
        self.handleError(with: AnyFlowErrorHandler(handleError: handleError))
    }
    
    /// Registers a closure that handle flow errors of type `Err`.
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
    ///                     title: "My Error Occurred",
    ///                     flowError: flowError))
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
    ///   - handleError: A closure that returns how the flow error should
    ///     be handled.
    public func handleError<Err: Swift.Error>(
        ofType errorType: Err.Type,
        _ handleError: @escaping (FlowError, Err) -> FlowErrorHandling
    ) -> some View {
        self.handleError { flowError in
            guard let error = flowError.error as? Err else {
                return .pass(flowError)
            }
            return handleError(flowError, error)
        }
    }
}

import SwiftUI

extension Scene {
    /// Registers a flow error handler.
    ///
    /// The handler is invoked whenever a flow error is presented by
    /// a view of the scene, after the handlers registered in the views
    /// with ``SwiftUICore/View/handleError(with:)``, and before the
    /// default handlers (see ``FlowErrorHandlerChain/default``).
    ///
    /// For example:
    ///
    /// ```swift
    /// // MyApp.swift
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// @main
    /// struct MyApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///         }
    ///         .handleError(with: MyErrorHandler())
    ///     }
    /// }
    /// ```
    public func handleError(with handler: some FlowErrorHandler) -> some Scene {
        transformEnvironment(\.errorHandler) {
            $0 = $0.prepending([handler])
        }
    }
}

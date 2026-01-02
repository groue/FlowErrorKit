import SwiftUI

extension Scene {
    /// Registers a flow error handler.
    ///
    /// The handler is invoked whenever a flow error
    /// is presented by ``SwiftUICore/View/presentError(_:with:)-7sikc``.
    ///
    /// For example:
    ///
    /// ```swift
    /// // MyApp.swift
    /// import FlowErrorKit
    ///
    /// struct MyApp: App {
    ///     var body: some Scene {
    ///         WindowGroup {
    ///             ContentView()
    ///         }
    ///         .handleError(with: FlowErrorHandlerChain([...]))
    ///     }
    /// }
    /// ```
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    public func handleError(with handler: some FlowErrorHandler) -> some Scene {
        transformEnvironment(\.errorHandler) {
            $0 = $0.prepending([handler])
        }
    }
}

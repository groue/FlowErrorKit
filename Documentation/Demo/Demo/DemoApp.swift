import FlowErrorKit
import SwiftUI

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            AuthorizationView()
        }
        
        // Register error handlers
        .handleError(with: .defaultErrorHandlers)
    }
}

extension FlowErrorHandler where Self == FlowErrorHandlerChain {
    /// The default chain of flow error handlers.
    ///
    /// For example:
    ///
    /// ```swift
    /// MyView().handleError(with: .defaultErrorHandlers)
    /// ```
    static var defaultErrorHandlers: Self {
        FlowErrorHandlerChain.default.prepending([
            APIErrorHandler(),
        ])
    }
}

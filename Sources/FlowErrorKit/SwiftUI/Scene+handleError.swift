import SwiftUI

extension Scene {
    /// Registers a flow error handler in the scene.
    ///
    /// The handler is invoked whenever a flow error is presented by
    /// a view of the scene, including views in sheets and full screen
    /// covers.
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
    ///
    /// - Tip: SwiftUI previews do not run the `App` body, so they do not
    ///   use this handler. Registering the same handlers in previews is
    ///   described in
    ///   <doc:FlowErrorHandler#Sharing-Handlers-Between-the-App-and-Its-Previews>.
    public func handleError(with handler: some FlowErrorHandler) -> some Scene {
        transformEnvironment(\.errorHandler) {
            $0 = $0.prepending([handler])
        }
    }
}

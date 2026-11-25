import SwiftUI

extension Scene {
    /// Registers a flow error handler.
    ///
    /// The handler is invoked whenever a flow error is presented by
    /// a view of the scene, including views in sheets and full screen
    /// covers. It is invoked after the handlers registered in the views
    /// with ``SwiftUICore/View/handleError(with:)``, and before the
    /// ready-made handling of `CancellationError`, `CocoaError`, and
    /// `URLError` provided by FlowErrorKit (see
    /// ``SwiftUICore/EnvironmentValues/errorHandler``).
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

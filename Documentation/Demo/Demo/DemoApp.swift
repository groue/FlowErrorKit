import FlowErrorKit
import SwiftUI

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            AuthorizationView()
        }
        // Register error handlers
        .handleError(with: APIErrorHandler())
    }
}

import FlowErrorKit
import SwiftUI

struct AuthorizedView<Content: View>: View {
    private var content: Content
    @State private var isAuthorized = true
    
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if isAuthorized {
                content
            } else {
                VStack {
                    Text("You have been signed out.")
                    Button("Sign in") {
                        isAuthorized = true
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        
        // Customize the presentation of UnauthorizedError
        .handleError(ofType: UnauthorizedError.self) { _, _ in
            isAuthorized = false
            return .cancel
        }
    }
}

#Preview {
    AuthorizedView {
        AlertWithErrorActionsView(error: UnauthorizedError())
    }
}

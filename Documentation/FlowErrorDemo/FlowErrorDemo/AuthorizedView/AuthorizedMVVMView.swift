import FlowErrorKit
import Observation
import SwiftUI

@MainActor @Observable final class AuthorizedMVVMViewModel {
    private(set) var isAuthorized = true
    
    func signIn() {
        isAuthorized = true
    }
}

extension AuthorizedMVVMViewModel: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard flowError.error is UnauthorizedError else {
            // Not an UnauthorizedError: pass to the next error handler.
            return .pass(flowError)
        }
        
        isAuthorized = false
        return .cancel
    }
}

struct AuthorizedMVVMView<Content: View>: View {
    @State var viewModel = AuthorizedMVVMViewModel()
    private var content: Content
    
    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Group {
            if viewModel.isAuthorized {
                content
            } else {
                VStack {
                    Text("You have been signed out.")
                    Button("Sign in") {
                        viewModel.signIn()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        
        // Let the viewModel customize the presentation of errors
        .handleError(with: viewModel)
    }
}

#Preview {
    AuthorizedMVVMView {
        AlertWithErrorActionsView(error: UnauthorizedError())
    }
}

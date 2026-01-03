import FlowErrorKit
import SwiftUI

struct AuthorizationView: View {
    @State var viewModel = AuthorizationViewModel()
    @State var flowError: FlowError?
    
    var body: some View {
        content
            .presentError($flowError, with: .alert)
        // Let the view model handle 401 Unauthorized
            .handleError(with: viewModel)
    }
    
    @ViewBuilder
    var content: some View {
        if let session = viewModel.session {
            signedInContent(session)
        } else {
            signedOutContent
        }
    }
    
    func signedInContent(_ session: Session) -> some View {
        MainView()
            .environment(\.session, session)
    }
    
    var signedOutContent: some View {
        VStack {
            signInButton
            
            ErrorPicker(selection: $viewModel.demoError, availableErrors: [
                .URLError_notConnectedToInternet,
                .APIError_unauthorized,
            ])
        }
        .padding(.horizontal)
    }
    
    var signInButton: some View {
        Button {
            Task { await signIn() }
        } label: {
            ZStack {
                ProgressView()
                    .opacity(viewModel.isSigningIn ? 1 : 0)
                Text("Sign In")
                    .opacity(viewModel.isSigningIn ? 0 : 1)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isSigningIn)
    }
    
    func signIn() async {
        do {
            try await viewModel.signIn()
        } catch {
            flowError = FlowError(error: error)
        }
    }
}

// MARK: - Preview

#Preview {
    AuthorizationView()
}

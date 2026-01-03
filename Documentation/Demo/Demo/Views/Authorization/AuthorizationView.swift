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
        List {
            Section {
                signInButton
            }
            
            ErrorPicker(selection: $viewModel.signInError) {
                Label("Sign In Error", systemImage: "hand.raised")
            }
            .pickerStyle(.inline)
        }
    }
    
    var signInButton: some View {
        Button {
            Task { await signIn() }
        } label: {
            if viewModel.isSigningIn {
                ProgressView()
            } else {
                Text("Sign In")
            }
        }
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

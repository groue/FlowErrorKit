import FlowErrorKit
import SwiftUI

struct AuthorizationView: View {
    @State var viewModel = AuthorizationViewModel()
    @State var flowError: FlowError?
    
    var body: some View {
        ZStack {
            Color.demoYellow.ignoresSafeArea()
            content
        }
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
            .environment(\.signOut, SignOutAction {
                viewModel.signOut()
            })
    }
    
    var signedOutContent: some View {
        VStack(spacing: 40) {
            VStack {
                Image(systemName: "person.crop.circle")
                    .imageScale(.large)
                    .font(.largeTitle.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("Please sign in")
                    .fontWeight(.semibold)
                    .font(.title2)
            }
            .foregroundStyle(.demoDeepBlue)
            
            HStack {
                signInButton
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                
                ErrorPicker(selection: $viewModel.demoError, availableErrors: [
                    .URLError_notConnectedToInternet,
                    .APIError_unauthorized,
                ])
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(4)
            .background {
                Capsule()
                    .fill(.tint.opacity(0.05))
                    .stroke(.tint.opacity(0.5), lineWidth: 1)
            }
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

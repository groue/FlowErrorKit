import FlowErrorKit
import Foundation
import Observation

@Observable final class AuthorizationViewModel {
    private(set) var session: Session?
    private(set) var isSigningIn = false
    var expiredSessionAlertisVisible = false
    
    var demoError: Error?
    
    /// When this method returns without error, there is a user session.
    func signIn() async throws {
        if session != nil {
            return
        }
        
        assert(!isSigningIn, "Already signing in")
        isSigningIn = true
        defer { isSigningIn = false }
        
        try await Task.sleep(for: .seconds(0.5))
        
        if let demoError {
            throw demoError
        }
        
        session = Session()
    }
    
    func signOut() {
        session = nil
    }
}

extension AuthorizationViewModel: FlowErrorHandler {
    func handle(_ flowError: FlowErrorKit.FlowError) -> FlowErrorKit.FlowErrorHandling {
        guard case APIError.unauthorized = flowError.error else {
            return .pass(flowError)
        }
        
        if session != nil {
            // User is no longer signed in.
            session = nil
            
            // Don't attempt at presenting the error, because the view that
            // caught the error is about to stop being rendered. Instead,
            // present the dedicated expired session alert.
            expiredSessionAlertisVisible = true
            return .cancel
        } else {
            return .present(ErrorPresentation(
                title: "Sign-in failed",
                message: "Please check your credentials.",
                flowError: flowError))
        }
    }
}

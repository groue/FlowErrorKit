import FlowErrorKit
import Foundation
import Observation

@Observable final class AuthorizationViewModel {
    private(set) var session: Session?
    private(set) var isSigningIn = false
    
    var signInError: Error?
    
    func signIn() async throws {
        assert(!isSigningIn)
        isSigningIn = true
        defer { isSigningIn = false }
        
        try await Task.sleep(for: .seconds(1))
        
        if let signInError {
            throw signInError
        }
        
        session = Session()
    }
}

extension AuthorizationViewModel: FlowErrorHandler {
    func handle(_ flowError: FlowErrorKit.FlowError) -> FlowErrorKit.FlowErrorHandling {
        // Specific handling of APIError.unauthorized: drop session.
        if session != nil,
           case APIError.unauthorized = flowError.error
        {
            session = nil
            return .present(ErrorPresentation(
                title: "Your session has expired",
                message: "Please sign in again.",
                flowError: flowError))
        } else {
            return .pass(flowError)
        }
    }
}

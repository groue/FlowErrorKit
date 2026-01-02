import FlowErrorKit
import SwiftUI

struct DemoRootView: View {
    @State var isSignedIn = true
    
    var body: some View {
        Group {
            if isSignedIn {
                ErrorListView()
            } else {
                Button("Sign In") { isSignedIn = true }
                    .buttonStyle(.borderedProminent)
            }
        }
        .handleError(ofType: ExpiredSessionError.self) { _, _ in
            // Signed out!
            isSignedIn = false
            return .cancel
        }
        .handleError(with: CodeSigningErrorHandler())
        .handleError(with: IgnoredErrorHandler())
        .handleError(with: PermissionErrorHandler())
        .handleError(with: VerbatimErrorHandler()) // last in the chain
    }
}

struct DemoRootView_Previews: PreviewProvider {
    static var previews: some View {
        DemoRootView()
    }
}

struct CodeSigningErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? CodeSigningError else {
            return .pass(flowError)
        }
        
        return .present(ErrorPresentation(
            title: error.errorDescription,
            flowError: flowError.appendingAction("Create Development Team") { }))
    }
}

struct IgnoredErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard flowError.error is IgnoredError else {
            return .pass(flowError)
        }
        
        return .cancel
    }
}

struct PermissionErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? PermissionError else {
            return .pass(flowError)
        }
        
        return .present(ErrorPresentation(
            title: error.errorDescription,
            message: nil,
            flowError: flowError
                .droppingRetryAction()
                .appendingAction("Open Settings") {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }))
    }
}

struct VerbatimErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? VerbatimError else {
            return .pass(flowError)
        }
        
        return .present(ErrorPresentation(
            title: error.errorDescription,
            flowError: flowError))
    }
}

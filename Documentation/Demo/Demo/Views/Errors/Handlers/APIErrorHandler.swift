import Foundation
import FlowErrorKit

struct APIErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowErrorKit.FlowError) -> FlowErrorKit.FlowErrorHandling {
        guard let error = flowError.error as? APIError else {
            return .pass(flowError)
        }
        
        switch error {
        case .unauthorized:
            return .present(ErrorPresentation(
                title: "Your session has expired",
                flowError: flowError))
            
        case .forbidden:
            return .present(ErrorPresentation(
                title: "You’re not authorized to perform this action",
                message: "You don’t have the required permissions.",
                flowError: flowError))
        }
    }
}

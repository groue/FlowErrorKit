import CoreLocation
import FlowErrorKit
import UIKit

// Handles CoreLocation errors.
struct CLErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? CLError else {
            // Not a CLError: pass to the next error handler.
            return .pass(flowError)
        }
        
        switch error {
        case CLError.denied:
            // Denied error is not recoverable: drop the retry action, and
            // let the user grant the required permissions.
            let presentedFlowError = flowError
                .droppingRetryAction()
                .appendingAction(String(localized: "Open Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            
            return .present(ErrorPresentation(
                title: String(localized: "Permission Required"),
                message: String(localized: "Please grant access to your location in the Settings application."),
                flowError: presentedFlowError))
            
        case CLError.geocodeCanceled:
            // Don't present this error
            return .cancel
            
        default:
            return .present(ErrorPresentation(
                message: error.localizedDescription,
                flowError: flowError))
        }
    }
}

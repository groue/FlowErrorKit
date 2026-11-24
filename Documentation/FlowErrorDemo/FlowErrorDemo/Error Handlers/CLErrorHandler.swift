import CoreLocation
import FlowErrorKit
import SwiftUI
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
                .appendingAction("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            
            return .present(ErrorPresentation(
                flowError: presentedFlowError,
                title: "Permission Required")
                .withMessage("Please grant access to your location in the Settings application."))
            
        case CLError.geocodeCanceled:
            // Don't present this error
            return .cancel
            
        default:
            return .present(ErrorPresentation(
                flowError: flowError,
                message: error.localizedDescription))
        }
    }
}

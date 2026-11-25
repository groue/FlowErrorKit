import Foundation

/// Handles `CocoaError`.
struct CocoaErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let error = flowError.error as? CocoaError else {
            // Not a CocoaError: pass to the next error handler.
            return .pass(flowError)
        }
        
        switch error.code {
        case .userCancelled:
            // <https://developer.apple.com/documentation/foundation/nsusercancellederror-swift.var>
            // > This code is for errors that do not require a dialog
            // > displayed and might be candidates for special-casing.
            //
            // Don't present the error.
            return .cancel
            
        case CocoaError.Code(rawValue: 3010):
            // "remote notifications are not supported in the simulator"
            // The localized message must be shown so that the developer
            // understands what's wrong.
            return .present(ErrorPresentation(
                flowError: flowError.droppingRetryAction(),
                title: error.localizedDescription))
            
        default:
            // Present a generic redacted error, because most CocoaErrors
            // have an English or technical message that is not suitable for
            // user display.
            return .present(ErrorPresentation(flowError: flowError))
        }
    }
}

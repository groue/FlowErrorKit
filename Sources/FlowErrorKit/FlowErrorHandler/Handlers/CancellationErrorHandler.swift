import Foundation

/// Handles `CancellationError`.
struct CancellationErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        if flowError.error is CancellationError {
            return .cancel
        } else {
            return .pass(flowError)
        }
    }
}

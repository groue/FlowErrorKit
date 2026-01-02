import Foundation

/// Handles `CancellationError`.
public struct CancellationErrorHandler: FlowErrorHandler {
    public func handle(_ flowError: FlowError) -> FlowErrorHandling {
        if flowError.error is CancellationError {
            return .cancel
        } else {
            return .pass(flowError)
        }
    }
}

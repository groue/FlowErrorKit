import FlowErrorKit

struct FrobnicateErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard let frobnicateError = flowError.error as? FrobnicateError else {
            // Not a FrobnicateError: pass to the next error handler.
            return .pass(flowError)
        }
        
        // Remove the retry action if the error is not recoverable.
        var presentedFlowError = flowError
        if frobnicateError.isRecoverable == false {
            presentedFlowError = presentedFlowError.droppingRetryAction()
        }
        
        // Present the error
        return .present(ErrorPresentation(
            flowError: presentedFlowError,
            title: frobnicateError.title,
            message: frobnicateError.message))
    }
}

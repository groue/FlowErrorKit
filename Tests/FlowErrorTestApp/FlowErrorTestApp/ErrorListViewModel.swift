import Observation
import FlowErrorKit
import Foundation

@MainActor @Observable final class ErrorListViewModel {
    var flowError: FlowError?
    var errorIsCancelled = false
    var validationErrorBackground = false
    
    // MARK: - Default Error
    
    func throwDefaultError() {
        errorIsCancelled = false
        do {
            throw makeDefaultError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwDefaultErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw makeDefaultError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    func throwDefaultErrorWithRetry() {
        errorIsCancelled = false
        do {
            throw makeDefaultError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
                .onRetry(action: throwDefaultErrorWithRetry)
        }
    }
    
    // MARK: - VerbatimError
    
    func throwVerbatimError() {
        errorIsCancelled = false
        do {
            throw VerbatimError(errorDescription: "Custom Error Message")
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwVerbatimErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw VerbatimError(errorDescription: "Custom Error Message")
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    func throwVerbatimErrorWithRetry() {
        errorIsCancelled = false
        do {
            throw VerbatimError(errorDescription: "Custom Error Message")
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
                .onRetry(action: throwVerbatimErrorWithRetry)
        }
    }
    
    // MARK: - IgnoredError
    
    func throwIgnoredError() {
        errorIsCancelled = false
        do {
            throw IgnoredError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwIgnoredErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw IgnoredError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    // MARK: - ValidationError
    
    func throwValidationError() {
        errorIsCancelled = false
        do {
            throw ValidationError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwValidationErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw ValidationError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    // MARK: - PermissionError
    
    func throwPermissionError() {
        errorIsCancelled = false
        do {
            throw PermissionError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwPermissionErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw PermissionError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    func throwPermissionErrorWithRetry() {
        errorIsCancelled = false
        do {
            throw PermissionError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
                .onRetry(action: throwPermissionErrorWithRetry)
        }
    }
    
    // MARK: - ExpiredSessionError
    
    func throwExpiredSessionError() {
        errorIsCancelled = false
        do {
            throw ExpiredSessionError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    // MARK: - CodeSigningError
    
    func throwCodeSigningError() {
        errorIsCancelled = false
        do {
            throw CodeSigningError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwCodeSigningErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw CodeSigningError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    func throwCodeSigningErrorWithRetry() {
        errorIsCancelled = false
        do {
            throw CodeSigningError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
                .onRetry(action: throwCodeSigningErrorWithRetry)
        }
    }
    
    // MARK: - Random Error
    
    func throwRandomErrorWithRetry() {
        do {
            let errors: [Error] = [
                makeDefaultError(),
                IgnoredError(),
                ValidationError(),
                PermissionError(),
                ExpiredSessionError(),
                CodeSigningError(),
                VerbatimError(errorDescription: "Not Implemented Yet"),
            ]
            throw errors.randomElement()!
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in self.flashCancelled() }
                .onRetry(action: throwRandomErrorWithRetry)
        }
    }
    
    // MARK: - Error Conflicts
    
    func throwTwoErrorsInARow() {
        errorIsCancelled = false
        flowError = FlowError(error: VerbatimError(errorDescription: "First Error"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.flowError = FlowError(error: VerbatimError(errorDescription: "Second Error"))
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    func throwIgnoredErrorAfterInitialError() {
        errorIsCancelled = false
        flowError = FlowError(error: VerbatimError(errorDescription: "First Error"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.flowError = FlowError(error: IgnoredError())
                .onCancel { _ in self.flashCancelled() }
        }
    }
    
    func throwDismissedErrorWithCancel() {
        errorIsCancelled = false
        flowError = FlowError(error: makeDefaultError())
            .onCancel { _ in self.flashCancelled() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.flowError = nil
        }
    }
    
    private func makeDefaultError() -> Error {
        // An error that is not handled by any error handler.
        ServerError(statusCode: 500)
    }
    
    private func flashCancelled() {
        errorIsCancelled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.errorIsCancelled = false
        })
    }
}

extension ErrorListViewModel: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        if flowError.error is ValidationError {
            validationErrorBackground = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.validationErrorBackground = false
            })
            return .cancel
        }
        
        return .pass(flowError)
    }
}

struct ValidationError: Error { }

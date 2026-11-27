// See documentation in FlowErrorHandler.md.
@MainActor public protocol FlowErrorHandler {
    /// Returns how a flow error should be handled.
    ///
    /// See ``FlowErrorHandling`` for the available options.
    /// Generally speaking:
    ///
    /// - Return ``FlowErrorHandling/pass(_:)`` for unknown errors.
    /// - Return ``FlowErrorHandling/cancel`` when an error must not be
    ///   presented to the application user.
    /// - Otherwise, return ``FlowErrorHandling/present(_:)``.
    ///
    /// The passed or presented flow error can be a modified version of
    /// the input flow error, built with methods such as
    /// ``FlowError/droppingRetryAction()``,
    /// ``FlowError/appendingAction(_:)``, or ``FlowError/withError(_:)``.
    /// For examples, see <doc:FlowErrorHandler#Adjusting-Actions-and-Presentations>.
    ///
    /// - Note: Don't invoke any action of the flow error from this method.
    /// The cancel action is automatically performed when you return
    /// ``FlowErrorHandling/cancel``, and the user will select their desired
    /// action when you return ``FlowErrorHandling/present(_:)``.
    func handle(_ flowError: FlowError) -> FlowErrorHandling
}

extension FlowErrorHandler {
    /// Returns how an error should be handled.
    public func handle(_ error: Error) -> FlowErrorHandling {
        handle(FlowError(error: error))
    }
}

/// `FlowErrorHandling` specifies how a flow error should be handled.
///
/// You return a `FlowErrorHandling` from
/// ``FlowErrorHandler/handle(_:)-(FlowError)``.
@MainActor public enum FlowErrorHandling {
    /// Pass the flow error to the next error handler in the chain of flow
    /// error handlers (see ``FlowErrorHandler``).
    ///
    /// A flow error can be transformed before it is passed to the next
    /// handler: see
    /// <doc:FlowErrorHandler#Adjusting-Actions-and-Presentations>.
    case pass(FlowError)
    
    /// Don't present the error, and stop error handling. Remaining error
    /// handlers in the chain are ignored. The `onCancel` callback of the
    /// flow error is performed, with the
    /// ``ErrorCancelReason/presentationCancelled`` reason.
    case cancel
    
    /// Present the error to the user, with the specified presentation.
    ///
    /// A flow error can be transformed before it is presented:
    /// see <doc:FlowErrorHandler#Adjusting-Actions-and-Presentations>.
    case present(ErrorPresentation)
    
    /// The presentation of the flow error, or nil if the flow error should
    /// not be presented.
    public var errorPresentation: ErrorPresentation? {
        switch self {
        case .cancel:
            return nil
            
        case let .pass(flowError):
            return ErrorPresentation(flowError: flowError)
            
        case let .present(presentation):
            return presentation
        }
    }
}


import Foundation

/// A chain of flow error handlers.
@MainActor public struct FlowErrorHandlerChain: FlowErrorHandler {
    /// All handlers in the chain. The first element in the array is invoked
    /// first by `handle(_:)`.
    private(set) var handlers: [any FlowErrorHandler]
    
    /// Creates a chain of flow error handlers.
    ///
    /// The first element in the `handlers` array is invoked
    /// first by `handle(_:)`.
    init(_ handlers: [any FlowErrorHandler] = []) {
        self.handlers = handlers
    }
    
    /// Returns a chain extended with flow error handlers.
    ///
    /// The first element in the `handlers` array is invoked
    /// first by ``handle(_:)-83zz5``.
    public func prepending(_ handlers: [any FlowErrorHandler]) -> Self {
        FlowErrorHandlerChain(handlers + self.handlers)
    }
    
    /// Returns how the flow error should be handled.
    ///
    /// This method iterates registered handlers until one of them returns
    /// `.present` or `.cancel`, and returns the same result.
    ///
    /// If no registered handler returns `.present` or `.cancel`, the
    /// result is `.pass`.
    public func handle(_ flowError: FlowError) -> FlowErrorHandling {
        var flowError = flowError
        
        for handler in handlers {
            let handling = handler.handle(flowError)
            switch handling {
            case let .pass(newFlowError):
                flowError = newFlowError
            case .present, .cancel:
                return handling
            }
        }
        
        return .pass(flowError)
    }
    
    /// Returns how the error should be handled.
    ///
    /// See ``handle(_:)-83zz5``.
    public func handle(_ error: Error) -> FlowErrorHandling {
        handle(FlowError(error: error))
    }

    /// Returns the error presentation for the flow error.
    ///
    /// Use this method when you implement custom error presenters that
    /// conform to ``FlowErrorPresenter``.
    ///
    /// - Parameters:
    ///   - flowError: A flow error.
    ///   - defaultPresentation: A closure that returns a default error
    ///     presentation. Unless specified, it returns a
    ///     redacted presentation.
    public func errorPresentation(
        _ flowError: FlowError,
        defaultPresentation: (FlowError) -> ErrorPresentation = { ErrorPresentation(flowError: $0) }
    ) -> ErrorPresentation? {
        switch handle(flowError) {
        case .cancel:
            return nil
            
        case let .pass(flowError):
            return defaultPresentation(flowError)
            
        case let .present(presentation):
            return presentation
        }
    }
}

extension FlowErrorHandlerChain {
    /// The default chain handles `CancellationError`, `CocoaError`,
    /// and `URLError`.
    public static let `default` = FlowErrorHandlerChain([
        CocoaErrorHandler(),
        URLErrorHandler(),
        CancellationErrorHandler(),
    ])
}

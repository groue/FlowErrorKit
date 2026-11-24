import Foundation

/// A chain of flow error handlers.
///
/// You don't create a chain directly. Read the chain from the SwiftUI
/// ``SwiftUICore/EnvironmentValues/errorHandler`` environment value, which
/// defaults to ``default``.
public struct FlowErrorHandlerChain: FlowErrorHandler {
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
    /// first by ``handle(_:)``.
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

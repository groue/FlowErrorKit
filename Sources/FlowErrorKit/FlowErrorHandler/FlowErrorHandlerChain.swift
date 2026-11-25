import Foundation

/// A chain of flow error handlers.
///
/// A chain is itself a flow error handler, which lets you register
/// several handlers at once:
///
/// ```swift
/// ContentView()
///     .handleError(with: FlowErrorHandlerChain([
///         MyErrorHandler(),
///         CLErrorHandler(),
///     ]))
/// ```
///
/// It is possible to register the same handlers in an app and in its
/// previews: see
/// <doc:FlowErrorHandler#Sharing-Handlers-Between-the-App-and-Its-Previews>.
///
/// The chain of handlers that apply to a view is available in the
/// ``SwiftUICore/EnvironmentValues/errorHandler`` environment value.
public struct FlowErrorHandlerChain: FlowErrorHandler {
    /// All handlers in the chain. The first element in the array is invoked
    /// first by `handle(_:)`.
    private(set) var handlers: [any FlowErrorHandler]
    
    /// Creates a chain of flow error handlers.
    ///
    /// The first element in the `handlers` array is invoked first by
    /// ``handle(_:)``.
    ///
    /// The order of handlers matters when a handler passes a modified flow
    /// error to the next handlers. For example, an API client may throw a
    /// `ClientError` that wraps the actual error, such as a `URLError` or
    /// a `ServerError`. A handler can unwrap it with
    /// ``FlowError/withError(_:)``, so that subsequent handlers can
    /// handle it:
    ///
    /// ```swift
    /// struct ClientErrorHandler: FlowErrorHandler {
    ///     func handle(_ flowError: FlowError) -> FlowErrorHandling {
    ///         guard let error = flowError.error as? ClientError else {
    ///             return .pass(flowError)
    ///         }
    ///         // Pass the underlying error to the next handlers.
    ///         return .pass(flowError.withError(error.underlyingError))
    ///     }
    /// }
    ///
    /// // ClientErrorHandler comes first, so that ServerErrorHandler can
    /// // handle the unwrapped errors.
    /// let chain = FlowErrorHandlerChain([
    ///     ClientErrorHandler(),
    ///     ServerErrorHandler(),
    /// ])
    /// ```
    ///
    /// The chain of handlers in the SwiftUI environment always ends with
    /// the ready-made handling of `CancellationError`, `CocoaError`, and
    /// `URLError` provided by FlowErrorKit (see
    /// ``SwiftUICore/EnvironmentValues/errorHandler``). In the above
    /// example, FlowErrorKit handles the `URLError` unwrapped by
    /// `ClientErrorHandler`.
    ///
    /// - parameter handlers: The handlers in the chain.
    public init(_ handlers: [any FlowErrorHandler] = []) {
        self.handlers = handlers
    }

    /// Returns a chain extended with flow error handlers.
    ///
    /// The first element in the `handlers` array is invoked first by
    /// ``handle(_:)``, and all of them are invoked before the handlers of
    /// the extended chain.
    ///
    /// - parameter handlers: The handlers to invoke first.
    func prepending(_ handlers: [any FlowErrorHandler]) -> Self {
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
    /// and `URLError`. The chain of handlers in the SwiftUI environment
    /// always ends with it.
    static let `default` = FlowErrorHandlerChain([
        CocoaErrorHandler(),
        URLErrorHandler(),
        CancellationErrorHandler(),
    ])
}

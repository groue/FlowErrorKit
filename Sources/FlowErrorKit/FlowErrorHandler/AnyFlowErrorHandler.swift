/// A type-erased handler of flow errors.
///
/// An instance of `AnyFlowErrorHandler` forwards its operations to an
/// underlying base handler, hiding the specifics of the underlying handler.
@MainActor public struct AnyFlowErrorHandler {
    var _handle: @MainActor (FlowError) -> FlowErrorHandling
    
    /// Creates a new handler that wraps and forwards operations to `base`.
    public init(_ base: some FlowErrorHandler) {
        self._handle = { base.handle($0) }
    }
    
    /// Creates a handler whose `handle(_:)` method forwards to
    /// `handleError`.
    public init(handleError: @escaping @MainActor (FlowError) -> FlowErrorHandling) {
        _handle = handleError
    }
}

extension AnyFlowErrorHandler: FlowErrorHandler {
    public func handle(_ flowError: FlowError) -> FlowErrorHandling {
        _handle(flowError)
    }
}

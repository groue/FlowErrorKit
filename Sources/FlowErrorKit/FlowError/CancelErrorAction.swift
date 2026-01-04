/// A `CancelErrorAction` defines a button in an error alert displayed
/// by `FlowErrorKit`.
public struct CancelErrorAction {
    public let title: TextContent?
    
    // MUST NOT BE PUBLIC, because actions MUST be run by `FlowError`.
    /// The function called when the user selects the action.
    let perform: @MainActor (CancelErrorReason) -> Void
}

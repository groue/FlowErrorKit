// `ErrorAction` is a class because making it a struct would have made it less
// easy to use with SwiftUI. `ForEach` likes to iterate collections of
// `Identifiable` values. `Identifiable` conformance is free for classes, but it
// is not for structs - and we do not want our users to invent a unique id for
// every action they create.
//
// Now, `ErrorAction` is a reference type, but it must not have any mutable
// state. It is essential that an action registered by a view model or an error
// handler in a `FlowError` cannot be altered. The peace of mind of the
// developer needs this immutability.
//
// And that's why all ErrorAction properties are let (and immutable).
//
// In summary, it was all about convenience. Making `ErrorAction` a struct is
// quite possible, but we would have to make the SwiftUI view that renders the
// error alert more complex in order to deal with the missing
// `Identifiable` conformance.

/// An `ErrorAction` defines a button in an error alert, or in an
/// ``ErrorPresentationView``, displayed by `FlowErrorKit`.
///
/// You cannot execute an action directly: use
/// ``FlowError/performAction(_:)`` instead. If this looks inconvenient to
/// you, please consider that `FlowError` preserves important invariants,
/// such as making sure that only one error action is ever run. Actions
/// cannot be executed directly, so that it is not possible to mess with
/// the state of the view model that created the `FlowError`.
///
/// ## Topics
///
/// ### Supporting Types
///
/// - ``ErrorActionRole``
public final class ErrorAction: Identifiable {
    /// The action title ("Cancel", "Retry", etc.)
    public let title: String
    
    /// The action role.
    public let role: ErrorActionRole?
    
    // MUST NOT BE PUBLIC, because actions MUST be run by `FlowError`.
    /// The function called when the user selects the action.
    let perform: @MainActor () -> Void
    
    /// Creates an `ErrorAction`.
    public init(
        title: String,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.role = role
        self.perform = perform
    }
}

/// The role of an ``ErrorAction``.
///
/// ## Topics
///
/// ### Building SwiftUI ButtonRole
///
/// - ``SwiftUI/ButtonRole/init(role:)``
public enum ErrorActionRole: Sendable {
    case destructive
}

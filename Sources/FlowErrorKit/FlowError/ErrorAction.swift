import SwiftUI

// `ErrorAction` is a class because making it a struct would have made it less
// easy to use with SwiftUI. `ForEach` likes to iterate collections of
// `Identifiable` values. `Identifiable` conformance is free for classes, but it
// is not for structs - and we do not want our users to invent a unique id for
// every action they create.
//
// Now, `ErrorAction` is a reference type, but it must not have any mutable
// state. It is essential that an action registered by an app or an error
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
/// An error action cannot be executed directly: it is performed by its
/// flow error, with ``FlowError/performAction(_:)``. This lets the flow
/// error preserve important invariants, such as making sure that only
/// one error action is ever run, and protects the state of the view that
/// created the flow error.
///
/// ## Topics
///
/// ### Creating an error action
///
/// - ``init(_:role:action:)-(LocalizedStringKey,_,_)``
/// - ``init(_:role:action:)-(LocalizedStringResource,_,_)``
/// - ``init(_:role:action:)-(StringProtocol,_,_)``
/// - ``init(verbatim:role:action:)``
///
/// ### Error action information
///
/// - ``title``
/// - ``role``
///
/// ### Supporting Types
///
/// - ``ErrorActionRole``
@MainActor public final class ErrorAction: Identifiable {
    /// The action title ("Cancel", "Retry", etc.)
    public let title: TextSource
    
    /// The action role.
    public let role: ErrorActionRole?
    
    // MUST NOT BE PUBLIC, because actions MUST be run by `FlowError`.
    /// The function called when the user selects the action.
    private let action: @MainActor () -> Void
    
    /// Creates an `ErrorAction`.
    init(
        titleSource: TextSource,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = titleSource
        self.role = role
        self.action = action
    }
    
    /// Creates an `ErrorAction` with a title that is not localized.
    ///
    /// - parameters:
    ///     - title: The action title, displayed without localization.
    ///     - role: The action role.
    ///     - action: The closure called when the user selects the action.
    @_disfavoredOverload
    convenience public init(
        _ title: some StringProtocol,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.init(titleSource: .verbatim(title), role: role, action: action)
    }
    
    /// Creates an `ErrorAction` with a localized title.
    ///
    /// - parameters:
    ///     - title: The localized action title.
    ///     - role: The action role.
    ///     - action: The closure called when the user selects the action.
    convenience public init(
        _ title: LocalizedStringKey,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.init(titleSource: .localizedStringKey(title), role: role, action: action)
    }
    
    /// Creates an `ErrorAction` with a localized title.
    ///
    /// - parameters:
    ///     - title: The localized action title.
    ///     - role: The action role.
    ///     - action: The closure called when the user selects the action.
    @_disfavoredOverload
    convenience public init(
        _ title: LocalizedStringResource,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.init(titleSource: .localizedStringResource(title), role: role, action: action)
    }
    
    /// Creates an `ErrorAction` with a title that is not localized.
    ///
    /// - parameters:
    ///     - title: The action title, displayed without localization.
    ///     - role: The action role.
    ///     - action: The closure called when the user selects the action.
    convenience public init(
        verbatim title: String,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.init(title, role: role, action: action)
    }
    
    // MUST NOT BE PUBLIC, because actions MUST be run by `FlowError`.
    func callAsFunction() {
        action()
    }
}

/// The role of an ``ErrorAction``.
///
/// ## Topics
///
/// ### Building SwiftUI ButtonRole
///
/// - ``SwiftUI/ButtonRole/init(_:)``
public enum ErrorActionRole: Sendable {
    /// A role that indicates a destructive action, such as deleting
    /// user data.
    ///
    /// It is displayed as a SwiftUI `Button` with the
    /// `ButtonRole.destructive` role.
    case destructive
}

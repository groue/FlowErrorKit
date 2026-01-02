import SwiftUI

// `ErrorAction` is a class because making it a struct would have made them less
// easy to use with SwiftUI. `ForEach` likes to iterate collections of
// `Identifiable` values. `Identifiable` conformance is free for classes, but it
// is not for structs - and we do not want our users to invent a unique id for
// every action they create.
//
// Now, `ErrorAction` is a reference type, but it must not have any mutable
// state. It is essential that an action registered by a view model or an error
// handler in a `FlowError` can not be altered. The peace of mind of the
// developer needs this immutability.
//
// And that's why all ErrorAction properties are let (and immutable).
//
// In summary, it was all about convenience. Making `ErrorAction` a struct is
// quite possible, but we'll have to make the SwiftUI view that renders the
// error alert more complex in order to deal with the missing
// `Identifiable` conformance.

/// An `ErrorAction` defines a button in an error alert displayed
/// by `FlowErrorKit`.
///
/// You can not execute actions. If this looks inconvenient to you,
/// please consider that `FlowError` preserves important invariants, such as
/// making sure that only one error action is ever run. You can not execute
/// actions so that it is not possible to mess up with the state of the view
/// model that did create the `FlowError`.
///
/// ## Topics
///
/// ### Supporting Types
///
/// - ``ErrorActionRole``
public final class ErrorAction: Identifiable, Sendable {
    /// The action role.
    public let role: ErrorActionRole?
    
    let title: TextContent
    
    // MUST NOT BE PUBLIC, because actions MUST be run by `FlowError`.
    /// The function called when the user selects the action.
    let perform: @MainActor () -> Void
    
    init(
        title: TextContent,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.role = role
        self.perform = perform
    }
    
    /// Creates an `ErrorAction` with a title without localization.
    @_disfavoredOverload
    public convenience init(
        _ title: String,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) {
        self.init(title: .verbatim(title), role: role, perform: perform)
    }
    
    /// Creates an `ErrorAction` with a title without localization.
    public convenience init(
        verbatim title: String,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) {
        self.init(title: .verbatim(title), role: role, perform: perform)
    }
    
    /// Creates an `ErrorAction` with a localized title.
    public convenience init(
        _ title: LocalizedStringResource,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) {
        self.init(title: .resource(title), role: role, perform: perform)
    }
    
    /// The title for the action, for the given locale.
    public func title(locale: Locale = .current) -> String {
        switch title {
        case .verbatim(let title):
            return title
        case .resource(var title):
            title.locale = locale
            return String(localized: title)
        }
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

extension Text {
    /// Creates a text view that displays the title of the action.
    public init(_ errorAction: ErrorAction) {
        switch errorAction.title {
        case .verbatim(let title):
            self.init(title)
        case .resource(let title):
            self.init(title)
        }
    }
}

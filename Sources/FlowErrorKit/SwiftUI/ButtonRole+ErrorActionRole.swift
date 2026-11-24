import SwiftUI

extension ButtonRole {
    /// Creates a button role from the role of an error action.
    ///
    /// Use this initializer when you display an ``ErrorAction`` with a
    /// SwiftUI `Button`:
    ///
    /// ```swift
    /// Button(role: action.role.map(ButtonRole.init)) {
    ///     flowError.performAction(action)
    /// } label: {
    ///     Text(action.title)
    /// }
    /// ```
    ///
    /// - parameter role: The role of an error action.
    public init(_ role: ErrorActionRole) {
        switch role {
        case .destructive:
            self = .destructive
        }
    }
}

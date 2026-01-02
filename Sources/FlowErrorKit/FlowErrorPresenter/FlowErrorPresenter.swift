import SwiftUI

/// A type that presents a flow error from a SwiftUI view.
///
/// A flow error presenter returns a view modifier that presents
/// flow errors. To do so, it calls the `resolve(_:)` method on the chain of
/// flow error handlers registered in the SwiftUI environment.
///
/// ## Topics
///
/// ### Getting built-in flow error presenters
///
/// - ``alert``
///
/// ### Creating custom flow error presenters
///
/// - ``Modifier``
/// - ``makeModifier(flowError:)``
///
/// ### Supporting Types
///
/// - ``AlertFlowErrorPresenter``
@MainActor public protocol FlowErrorPresenter {
    /// The type of view modifier.
    associatedtype Modifier: ViewModifier
    
    /// Returns a view modifier that presents a flow error.
    ///
    /// - parameter flowError: A binding to an optional flow error.
    func makeModifier(flowError: Binding<FlowError?>) -> Modifier
}

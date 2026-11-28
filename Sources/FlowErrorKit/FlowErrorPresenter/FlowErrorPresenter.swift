import SwiftUI

// See documentation in FlowErrorPresenter.md.
@MainActor
public protocol FlowErrorPresenter {
    /// The type of view modifier.
    associatedtype Modifier: ViewModifier
    
    /// Returns a view modifier that presents a flow error.
    ///
    /// - parameter flowError: A binding to an optional flow error.
    func makeModifier(flowError: Binding<FlowError?>) -> Modifier
}

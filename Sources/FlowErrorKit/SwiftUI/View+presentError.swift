import SwiftUI

extension View {
    /// Presents a flow error with the given presenter.
    ///
    /// For example, to present a flow error with an alert:
    ///
    /// ```swift
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .presentError($flowError, with: .alert)
    ///     }
    /// }
    /// ```
    ///
    /// Or display an ``ErrorPresentationView`` in place of the view
    /// content:
    ///
    /// ```swift
    /// ContentView()
    ///     .presentError($flowError, with: .errorPresentationView)
    /// ```
    ///
    /// Before a flow error is presented, it is handled by the chain of
    /// flow error handlers of the SwiftUI environment (see
    /// ``SwiftUICore/EnvironmentValues/errorHandler``). The handlers
    /// decide whether, and how, the flow error is presented.
    ///
    /// When the user selects an action, the presenter performs it.
    /// Setting `flowError` to nil removes the presentation without
    /// performing any action.
    ///
    /// - parameter flowError: A binding to an optional flow error.
    /// - parameter presenter: A flow error presenter, such as
    ///   ``FlowErrorPresenter/alert``,
    ///   ``FlowErrorPresenter/errorPresentationView``, or
    ///   ``FlowErrorPresenter/errorPresentationView(_:)``.
    public func presentError(
        _ flowError: Binding<FlowError?>,
        with presenter: some FlowErrorPresenter)
    -> some View
    {
        modifier(presenter.makeModifier(flowError: flowError))
    }
}

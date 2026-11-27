import SwiftUI

extension View {
    /// Presents a flow error with the given presenter.
    ///
    /// For example, present a flow error with an alert:
    ///
    /// ```swift
    /// import FlowErrorKit
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

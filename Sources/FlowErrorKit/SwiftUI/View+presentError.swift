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
    /// - parameter flowError: A binding to an optional flow error.
    /// - parameter presenter: A flow error presenter.
    public func presentError(
        _ flowError: Binding<FlowError?>,
        with presenter: some FlowErrorPresenter)
    -> some View
    {
        modifier(presenter.makeModifier(flowError: flowError))
    }
    
    /// Presents a flow error with the given binding to an
    /// error presentation.
    ///
    /// Applications should display an ``ErrorPresentationView``
    /// with the provided error presentation.
    ///
    /// Unlike an alert, the error presentation is not cleared when the
    /// user selects an error action. Applications should set `flowError`
    /// to nil in order to clear the `errorPresentation` binding (for
    /// example, when a retried action succeeds).
    ///
    /// If a new flow error is set while a previous one is presented, the
    /// new error replaces the previous one, and the cancel action of the
    /// previous one is run.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///     @State private var errorPresentation: ErrorPresentation?
    ///
    ///     var body: some View {
    ///         Group {
    ///             if let errorPresentation {
    ///                 ErrorPresentationView(errorPresentation)
    ///             } else {
    ///                 Button("Try Me", action: performFailableAction)
    ///             }
    ///         }
    ///         // Capture and present the flow error
    ///         .presentError($flowError, with: $errorPresentation)
    ///     }
    ///
    ///     func performFailableAction() {
    ///         do {
    ///             try failableMethod()
    ///         } catch {
    ///             // Turn the error into a FlowError
    ///             flowError = FlowError(error: error)
    ///                 .onRetry(action: performFailableAction)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - parameter flowError: A binding to an optional flow error.
    /// - parameter errorPresentation: A binding to an optional error
    ///   presentation. It is set, or cleared, whenever `flowError`
    ///   is modified.
    public func presentError(
        _ flowError: Binding<FlowError?>,
        with errorPresentation: Binding<ErrorPresentation?>
    ) -> some View {
        presentError(flowError, with: ErrorPresentationPresenter(errorPresentation: errorPresentation))
    }
}

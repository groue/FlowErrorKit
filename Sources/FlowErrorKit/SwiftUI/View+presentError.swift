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
    /// with the provided error presentation. For example:
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
    ///             // Success: remove the ErrorPresentationView
    ///             flowError = nil
    ///         } catch {
    ///             // Turn the error into a FlowError
    ///             flowError = FlowError(error: error)
    ///                 .onRetry(action: performFailableAction)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// Unlike an alert, the error presentation is not automatically
    /// cleared when the user selects an error action. Applications clear
    /// it by setting `flowError` to nil (for example, when a retried
    /// action succeeds), as in the sample code above.
    ///
    /// Once the user has selected an action, the ``ErrorPresentationView``
    /// disables its buttons. To let the user select an action again (for
    /// example, after coming back from "Open Settings"), create the flow
    /// error with `allowMultipleActionExecutions`.
    ///
    /// If a new flow error is set while a previous one is presented, the
    /// new error replaces the previous one, and the cancel action of the
    /// previous one is run.
    ///
    /// However, a ``FlowErrorHandler`` may prevent the presentation of a
    /// flow error (see ``FlowErrorHandling/cancel``). In this case, the
    /// cancel action of this flow error runs, and `errorPresentation` is
    /// not modified: a previously presented error, if any, remains on
    /// screen, and is not replaced.
    ///
    /// The presented flow error is not discarded when the view
    /// disappears, because the presentation may come back on screen (for
    /// example, when the user switches to another tab and back). When the
    /// application knows that the user can no longer select any action,
    /// it can discard the flow error, so that its cancel action runs:
    ///
    /// ```swift
    /// errorPresentation?.flowError.discard(.presentationCancelled)
    /// ```
    ///
    /// - parameter flowError: A binding to an optional flow error.
    /// - parameter errorPresentation: A binding to an optional error
    ///   presentation. It is set when a flow error is presented, and
    ///   cleared when `flowError` is set to nil.
    public func presentError(
        _ flowError: Binding<FlowError?>,
        with errorPresentation: Binding<ErrorPresentation?>
    ) -> some View {
        presentError(flowError, with: ErrorPresentationPresenter(errorPresentation: errorPresentation))
    }
}

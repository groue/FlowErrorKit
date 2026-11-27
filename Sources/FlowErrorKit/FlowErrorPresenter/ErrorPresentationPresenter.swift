import SwiftUI

/// A presenter that displays an error view in place of the view content
/// when a flow error occurs.
///
/// You don't create this type directly: use
/// ``SwiftUICore/View/presentError(_:with:)-(_,FlowErrorPresenter)``
/// with the ``FlowErrorPresenter/errorPresentationView`` or
/// ``FlowErrorPresenter/errorPresentationView(_:)`` presenter.
public struct ErrorPresentationPresenter<ErrorContent: View> {
    var errorContent: (ErrorPresentation) -> ErrorContent
}

extension ErrorPresentationPresenter: FlowErrorPresenter {
    /// The view modifier that displays an error view in place of the
    /// view content.
    ///
    /// You don't create this type directly: use
    /// ``SwiftUICore/View/presentError(_:with:)-(_,FlowErrorPresenter)``
    /// with the ``FlowErrorPresenter/errorPresentationView`` or
    /// ``FlowErrorPresenter/errorPresentationView(_:)`` presenter.
    public struct Modifier: ViewModifier {
        @Binding var flowError: FlowError?
        var errorContent: (ErrorPresentation) -> ErrorContent
        @Environment(\.errorHandler) private var errorHandler
        @State private var errorPresentation: ErrorPresentation?

        public func body(content: Content) -> some View {
            Group {
                if let errorPresentation {
                    errorContent(errorPresentation)
                } else {
                    content
                }
            }
            .onChange(of: flowError?.id, initial: true, handleFlowError)
        }

        private func handleFlowError() {
            if let flowError {
                if let newPresentation = errorHandler.handle(flowError).errorPresentation {
                    // Replace the current presentation, if any.
                    if let errorPresentation {
                        errorPresentation.flowError.discard(.presentationCancelled)
                    }
                    errorPresentation = newPresentation
                } else {
                    // Presentation cancelled by error handler.
                    flowError.discard(.presentationCancelled)
                    // Don't discard current presentation, if any
                    if errorPresentation == nil {
                        self.flowError = nil
                    }
                }
            } else if errorPresentation != nil {
                // Flow error programmatically dismissed: remove the presentation
                // without performing any action.
                self.errorPresentation = nil
            }
        }
    }

    public func makeModifier(flowError: Binding<FlowError?>) -> Modifier {
        Modifier(flowError: flowError, errorContent: errorContent)
    }
}

extension FlowErrorPresenter {
    /// A presenter that displays a custom error view in place of the
    /// view content when a flow error occurs.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///     @State private var isLoading = false
    ///
    ///     var body: some View {
    ///         ContentView()
    ///             .presentError($flowError, with: .errorPresentationView { errorPresentation in
    ///                 ErrorPresentationView(errorPresentation) {
    ///                     ProgressView().opacity(isLoading ? 1 : 0)
    ///                 }
    ///                 .disabled(isLoading)
    ///             })
    ///     }
    /// }
    /// ```
    ///
    /// The presenter behaves like
    /// ``FlowErrorPresenter/errorPresentationView``.
    ///
    /// - parameter errorContent: A closure that returns the error view,
    ///   displayed in place of the view content. Display the error
    ///   presentation in an ``ErrorPresentationView``.
    public static func errorPresentationView<ErrorContent: View>(
        @ViewBuilder _ errorContent: @escaping (ErrorPresentation) -> ErrorContent
    ) -> Self where Self == ErrorPresentationPresenter<ErrorContent> {
        ErrorPresentationPresenter(errorContent: errorContent)
    }
}

extension FlowErrorPresenter where Self == ErrorPresentationPresenter<ErrorPresentationView<EmptyView>> {
    /// A presenter that displays an ``ErrorPresentationView`` in place of
    /// the view content when a flow error occurs.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///
    ///     var body: some View {
    ///         Button("Try Me", action: performFailableAction)
    ///             // Capture and present the flow error
    ///             .presentError($flowError, with: .errorPresentationView)
    ///     }
    ///
    ///     func performFailableAction() {
    ///         do {
    ///             try failableMethod()
    ///             // Success: remove the error view
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
    /// To customize the error view, use
    /// ``FlowErrorPresenter/errorPresentationView(_:)``.
    ///
    /// The error view replaces the view content, including the modifiers
    /// applied before `presentError`. Apply the modifiers that must remain
    /// visible, such as `navigationTitle` or `toolbar`, after
    /// `presentError`.
    ///
    /// When the error view goes away, the view content is created again:
    /// the state of its subviews is reset, and its `task` and `onAppear`
    /// modifiers run again. Apply the modifiers that load the content
    /// after `presentError`, so that the content is not loaded twice
    /// after a successful retry:
    ///
    /// ```swift
    /// List(news) { article in Text(article.title) }
    ///     .presentError($flowError, with: .errorPresentationView)
    ///     .task { await load() } // After presentError
    /// ```
    ///
    /// Unlike an alert, the error view is not automatically removed when
    /// the user selects an error action. Applications remove it by
    /// setting `flowError` to nil, as soon as the view content is
    /// available (for example, when a retried action succeeds), as in the
    /// sample code above. Setting `flowError` to nil does not perform any
    /// action.
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
    /// cancel action of this flow error runs, and the screen does not
    /// change: the view content remains displayed, or the previously
    /// presented error, if any, remains on screen, and is not replaced.
    ///
    /// The presented flow error is not discarded when the view
    /// disappears, because the presentation may come back on screen (for
    /// example, when the user switches to another tab and back). When the
    /// application knows that the user can no longer select any action,
    /// it can discard the flow error, so that its cancel action runs:
    ///
    /// ```swift
    /// flowError?.discard(.presentationCancelled)
    /// ```
    public static var errorPresentationView: Self {
        ErrorPresentationPresenter(errorContent: { ErrorPresentationView($0) })
    }
}

#if DEBUG
private struct MyError: Error {
    var value: Int = Int.random(in: 1...1000)
}

private struct MyView: View {
    @State private var flowError: FlowError?
    @State var isSuccess = false

    var body: some View {
        VStack {
            Button {
                performFailableAction()
            } label: {
                Text(verbatim: "Flip a Coin")
            }
            .controlSize(.small)
            .buttonBorderShape(.capsule)
            .buttonStyle(.borderedProminent)

            Text(verbatim: "Success!")
                .opacity(isSuccess ? 1 : 0)
                .animation(isSuccess ? nil : .easeOut, value: isSuccess)
                .task(id: isSuccess) {
                    if isSuccess {
                        try? await Task.sleep(for: .seconds(0.5))
                        isSuccess = false
                    }
                }
        }
        // Capture and present the flow error
        .presentError($flowError, with: .errorPresentationView)
    }

    func performFailableAction() {
        do {
            if Bool.random() {
                throw MyError()
            }
            isSuccess = true
            // Success: remove the error view
            flowError = nil
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
                .onRetry(action: performFailableAction)
        }
    }
}

#Preview {
    MyView()
}
#endif

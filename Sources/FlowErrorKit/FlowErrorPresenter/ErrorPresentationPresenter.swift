import SwiftUI

/// A presenter that displays an error view in place of the view content
/// when a flow error occurs.
///
/// You don't create this type directly: use
/// ``SwiftUICore/View/presentError(_:with:)``
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
    /// ``SwiftUICore/View/presentError(_:with:)``
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
                        errorPresentation.flowError.discard()
                    }
                    errorPresentation = newPresentation
                } else {
                    // Presentation cancelled by error handler.
                    flowError.discard()
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
    /// This presenter behaves like
    /// ``FlowErrorPresenter/errorPresentationView``, with one difference:
    /// the error view is the one returned by the `errorContent` closure.
    /// The closure receives the ``ErrorPresentation`` of the presented
    /// flow error.
    ///
    /// For example, the error view below displays a progress indicator,
    /// and disables its buttons, while the content is loading:
    ///
    /// ```swift
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///     @State private var isLoading = false
    ///
    ///     var body: some View {
    ///         ContentView().presentError(
    ///             $flowError,
    ///             with: .errorPresentationView { errorPresentation in
    ///                 ErrorPresentationView(errorPresentation, footer: {
    ///                     ProgressView().opacity(isLoading ? 1 : 0)
    ///                 })
    ///                 .disabled(isLoading)
    ///             })
    ///     }
    /// }
    /// ```
    ///
    /// - parameter errorContent: A closure that returns the error view,
    ///   given the error presentation to display.
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
    /// import SwiftUI
    ///
    /// struct NewsView: View {
    ///     @State private var news: [Article] = []
    ///     @State private var flowError: FlowError?
    ///
    ///     var body: some View {
    ///         List(news) { article in
    ///             Text(article.title)
    ///         }
    ///         .presentError($flowError, with: .errorPresentationView)
    ///         .task { await load() }
    ///     }
    ///
    ///     func load() async {
    ///         do {
    ///             news = try await fetchNews()
    ///             // Success: remove the error view
    ///             flowError = nil
    ///         } catch {
    ///             flowError = FlowError(error: error)
    ///                 .withTitle("Could not load the news")
    ///                 .onRetry { Task { await load() } }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// To configure the error view, use
    /// ``FlowErrorPresenter/errorPresentationView(_:)``.
    ///
    /// Unlike an alert, the error view is not automatically removed when
    /// the user selects an action. The application removes the error view
    /// by setting `flowError` to nil, as the `load()` method does in the
    /// sample code above.
    ///
    /// Once the user has selected an action, the buttons of the error view
    /// are disabled. To let the user select an action again, such as an
    /// "Open Settings" action after they come back from the Settings
    /// application, create the flow error with the
    /// `allowMultipleActionExecutions` flag (see
    /// ``FlowError/init(error:allowMultipleActionExecutions:)``).
    ///
    /// When the view presents a new flow error while the error view is
    /// displayed, the new flow error replaces the previous one. If the user
    /// has not selected any action of the previous flow error, its cancel
    /// action is run.
    ///
    /// ## Discarding the Presented Error
    ///
    /// The presented flow error is not discarded when the view
    /// disappears, because the error view may come back on screen, for
    /// example when the user switches to another tab and back. When the
    /// application knows that the user can no longer select any action,
    /// it should discard the flow error explicitly, so that its cancel
    /// action runs:
    ///
    /// ```swift
    /// flowError?.discard()
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

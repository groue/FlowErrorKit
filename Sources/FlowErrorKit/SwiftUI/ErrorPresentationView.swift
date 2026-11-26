import SwiftUI

// MARK: - ErrorPresentationView

/// A view that conveys an error state.
///
/// You get the displayed error presentation by presenting a flow error
/// with ``SwiftUICore/View/presentError(_:with:)-(_,Binding<ErrorPresentation?>)``.
///
/// The view displays the retry and supplementary actions, and
/// optionally the cancel action.
///
/// Unlike an alert, the view remains on screen after the user selects an
/// action, until your application removes it (by setting the flow error
/// to nil). Meanwhile, the action buttons are disabled, unless the flow
/// error was created with the `allowMultipleActionExecutions` flag (see
/// ``FlowError/canPerformAction``).
///
/// If the flow error can no longer perform an action when the view first
/// displays it (for example, after a ``FlowErrorHandler`` has cancelled
/// its presentation), the action buttons are hidden instead.
///
/// In the DEBUG configuration, the view also describes the presented
/// error.
public struct ErrorPresentationView<Footer: View>: View {
    /// Whether the actions of a flow error are hidden.
    private struct ActionsVisibility {
        var flowErrorID: ObjectIdentifier
        var isHidden: Bool
        
        @MainActor init(_ flowError: FlowError) {
            self.flowErrorID = flowError.id
            self.isHidden = !flowError.canPerformAction
        }
    }
    
    private var errorPresentation: ErrorPresentation
    private var cancelButton: Visibility
    private var footer: Footer
    
    /// The visibility of actions, determined when a flow error is first
    /// displayed.
    ///
    /// It is not determined in the initializer, which runs during the
    /// body of the parent view: reading the observable
    /// ``FlowError/canPerformAction`` there would invalidate the parent
    /// view when an action is performed.
    @State private var actionsVisibility: ActionsVisibility?
    
    /// Creates a view that displays an error presentation.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter cancelButton: The visibility of the cancel button,
    ///   hidden unless `.visible`.
    /// - parameter footer: A view to display below the action buttons.
    public init(
        _ errorPresentation: ErrorPresentation,
        cancelButton: Visibility = .automatic,
        @ViewBuilder footer: (() -> Footer) = { EmptyView() })
    {
        self.errorPresentation = errorPresentation
        self.cancelButton = cancelButton
        self.footer = footer()
    }
    
    public var body: some View {
        ContentUnavailableView.error(
            errorPresentation,
            actionsHidden: actionsHidden,
            cancelButton: cancelButton,
            footer: { footer })
        .onChange(of: errorPresentation.flowError.id, initial: true) {
            actionsVisibility = ActionsVisibility(errorPresentation.flowError)
        }
    }
    
    private var actionsHidden: Bool {
        let flowError = errorPresentation.flowError
        if let actionsVisibility, actionsVisibility.flowErrorID == flowError.id {
            return actionsVisibility.isHidden
        } else {
            // `actionsVisibility` is not determined yet for this flow
            // error (first render, or new flow error).
            return !flowError.canPerformAction
        }
    }
}

// MARK: - ContentUnavailableView

extension ContentUnavailableView {
    /// Creates a `ContentUnavailableView` instance that conveys an
    /// error state.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter actionsHidden: Whether the action buttons are hidden.
    /// - parameter cancelButton: The visibility of the cancel button.
    /// - parameter footer: A view to display below the action buttons.
    @MainActor
    fileprivate static func error<Footer: View>(
        _ errorPresentation: ErrorPresentation,
        actionsHidden: Bool,
        cancelButton: Visibility,
        @ViewBuilder footer: () -> Footer)
    -> ContentUnavailableView<Label, Description, Actions>
    where Label == ErrorPresentationContent<Footer>.Label,
          Description == ErrorPresentationContent<Footer>.Description,
          Actions == ErrorPresentationContent<Footer>.Actions
    {
        let content = ErrorPresentationContent<Footer>(
            errorPresentation: errorPresentation,
            actionsHidden: actionsHidden,
            cancelButton: cancelButton,
            footer: footer())
        
        return ContentUnavailableView(
            label: content.label,
            description: content.description,
            actions: content.actions)
    }
}

// MARK: - ErrorPresentationContent

/// The label, description, and actions of the `ContentUnavailableView`
/// displayed by ``ErrorPresentationView``.
@MainActor
struct ErrorPresentationContent<Footer: View> {
    var errorPresentation: ErrorPresentation
    var actionsHidden: Bool
    var cancelButton: Visibility
    var footer: Footer
    
    struct Label: View {
        var title: TextSource
        var systemImage: String
        
        var body: some View {
            SwiftUI.Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
            }
        }
    }
    
    struct Description: View {
        var subtitle: TextSource?
        var message: TextSource?
        var error: any Error
        @ScaledMetric private var spacing = 2
        
        var body: some View {
            VStack(spacing: spacing) {
                if let subtitle {
                    Text(subtitle)
                        .fontWeight(.semibold)
                }
                if let message {
                    Text(message)
                }
#if DEBUG
                Text(verbatim: "DEBUG: \(error)")
#endif
            }
        }
    }
    
    struct Actions: View {
        var flowError: FlowError
        var actionsHidden: Bool
        var cancelButtonVisibility: Visibility
        var footer: Footer
        
        var body: some View {
            if !actionsHidden {
                Group {
                    ForEach(flowError.supplementaryActions) { action in
                        actionButton(action)
                    }
                    
                    if let retryAction = flowError.retryAction {
                        if cancelButtonVisibility == .visible {
                            actionButton(retryAction)
                        } else {
                            actionButton(retryAction)
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    
                    if cancelButtonVisibility == .visible {
                        cancelButton()
                            .buttonStyle(.borderedProminent)
                    }
                }
                .disabled(!flowError.canPerformAction)
            }
            
            footer
        }
        
        func actionButton(_ action: ErrorAction) -> some View {
            Button(role: action.role.map(ButtonRole.init)) {
                flowError.performAction(action)
            } label: {
                Text(action.title)
            }
        }
        
        func cancelButton() -> some View {
            Button(role: .cancel) {
                flowError.performCancelAction()
            } label: {
                Text(cancelTitle)
            }
        }
        
        var cancelTitle: TextSource {
            if let cancelTitle = flowError.cancelTitle {
                return cancelTitle
            } else if flowError.retryAction == nil && flowError.supplementaryActions.isEmpty {
                // Only possible action is cancel.
                return .localizedStringResource(.ok)
            } else {
                return .localizedStringResource(.cancel)
            }
        }
    }
    
    func label() -> Self.Label {
        Label(
            title: errorPresentation.title,
            systemImage: errorPresentation.systemImage)
    }
    
    func description() -> Self.Description {
        Description(
            subtitle: errorPresentation.subtitle,
            message: errorPresentation.message,
            error: errorPresentation.flowError.error)
    }
    
    func actions() -> Self.Actions {
        Actions(
            flowError: errorPresentation.flowError,
            actionsHidden: actionsHidden,
            cancelButtonVisibility: cancelButton,
            footer: footer)
    }
}

// MARK: - Previews

#if DEBUG
struct PreviewError: Error { }
#Preview("Minimal") {
    VStack {
        ErrorPresentationView(
            ErrorPresentation(
                flowError: FlowError(error: PreviewError()),
                verbatimTitle: "An Error Occurred"))
        
        Divider()
        
        ErrorPresentationView(
            ErrorPresentation(
                flowError: FlowError(error: PreviewError()),
                verbatimTitle: "Not connected to Internet",
                systemImage: "wifi.exclamationmark"))
    }
}

#Preview("Subtitle") {
    // The flow error title wins, and the presentation title becomes
    // the subtitle.
    ErrorPresentationView(
        ErrorPresentation(
            flowError: FlowError(error: PreviewError()).withTitle(verbatim: "Could not frobnicate"),
            verbatimTitle: "Not connected to Internet",
            message: "Please check your connection.",
            systemImage: "wifi.exclamationmark"))
}

#Preview("Retry") {
    ErrorPresentationView(
        ErrorPresentation(
            flowError: FlowError(error: PreviewError()).onRetry { },
            verbatimTitle: "An Error Occurred",
            message: "Could not frobnicate the fubar."))
}

#Preview("Visible Cancel Action") {
    ErrorPresentationView(
        ErrorPresentation(
            flowError: FlowError(error: PreviewError()).onRetry { },
            verbatimTitle: "An Error Occurred",
            message: "Could not frobnicate the fubar."),
        cancelButton: .visible)
}

#Preview("Hidden Actions") {
    let flowError = {
        let flowError = FlowError(error: PreviewError())
            .onRetry { }
            .appendingAction("Repair") { }
        flowError.performCancelAction()
        return flowError
    }()
    
    ErrorPresentationView(
        ErrorPresentation(
            flowError: flowError,
            verbatimTitle: "An Error Occurred",
            message: "Could not frobnicate the fubar."))
}

#Preview("Custom Actions") {
    ErrorPresentationView(
        ErrorPresentation(
            flowError: FlowError(error: PreviewError())
                .onRetry { }
                .appendingAction("Quit") { }
                .appendingAction("Repair") { },
            verbatimTitle: "An Error Occurred",
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."))
}

#Preview("Footer") {
    ErrorPresentationView(
        ErrorPresentation(
            flowError: FlowError(error: PreviewError()).onRetry { },
            verbatimTitle: "An Error Occurred",
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
        footer: {
            ProgressView()
        })
    .disabled(true)
}
#endif

import SwiftUI

// MARK: - ErrorPresentationView

/// A view that conveys an error state.
///
/// You get the displayed error presentation by presenting a flow error
/// with ``SwiftUICore/View/presentError(_:with:)-(_,Binding<ErrorPresentation?>)``.
///
/// In the DEBUG configuration, the view also describes the presented
/// error.
///
/// Unlike an alert, the view remains on screen after the user selects an
/// action, until your application removes it.
public struct ErrorPresentationView<Footer: View>: View {
    private var errorPresentation: ErrorPresentation
    private var actions: ErrorActionsVisibility
    private var footer: Footer
    
    /// Creates a view that displays an error presentation.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter actions: The visibility of the error action buttons.
    ///   The default `.automatic` shows the retry and supplementary
    ///   actions, but not the cancel action. Use `.includingCancel` to
    ///   also show the cancel action, and `.hidden` to hide all actions.
    /// - parameter footer: A view to display below error actions.
    public init(
        _ errorPresentation: ErrorPresentation,
        actions: ErrorActionsVisibility = .automatic,
        @ViewBuilder footer: (() -> Footer) = { EmptyView() })
    {
        self.errorPresentation = errorPresentation
        self.actions = actions
        self.footer = footer()
    }
    
    public var body: some View {
        ContentUnavailableView.error(
            errorPresentation,
            actions: actions,
            footer: { footer })
    }
}

// MARK: - ErrorActionsVisibility

/// The visibility of the error action buttons in an
/// ``ErrorPresentationView``.
public enum ErrorActionsVisibility: Sendable, Hashable {
    /// The retry and supplementary actions are visible, but not the
    /// cancel action.
    case automatic
    
    /// All actions are visible, including the cancel action.
    case includingCancel
    
    /// No action is visible.
    ///
    /// For example, use `.hidden` when no action can be performed, such as
    /// after a ``FlowErrorHandler`` has cancelled the presentation of the
    /// flow error, and the application still needs to display an error
    /// state.
    case hidden
}

// MARK: - ContentUnavailableView

extension ContentUnavailableView {
    /// Creates a `ContentUnavailableView` instance that conveys an
    /// error state.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter actions: The visibility of the error actions.
    /// - parameter footer: A view to display below error actions.
    @MainActor
    fileprivate static func error<Footer: View>(
        _ errorPresentation: ErrorPresentation,
        actions: ErrorActionsVisibility = .automatic,
        @ViewBuilder footer: () -> Footer)
    -> ContentUnavailableView<Label, Description, Actions>
    where Label == ErrorPresentationContent<Footer>.Label,
          Description == ErrorPresentationContent<Footer>.Description,
          Actions == ErrorPresentationContent<Footer>.Actions
    {
        let content = ErrorPresentationContent<Footer>(
            errorPresentation: errorPresentation,
            actionsVisibility: actions,
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
    var actionsVisibility: ErrorActionsVisibility
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
        var visibility: ErrorActionsVisibility
        var footer: Footer
        
        var body: some View {
            switch visibility {
            case .automatic:
                ForEach(flowError.supplementaryActions) { action in
                    supplementaryActionButton(action)
                }
                
                if let retryAction = flowError.retryAction {
                    retryButton(retryAction)
                        .buttonStyle(.borderedProminent)
                }
                
            case .includingCancel:
                ForEach(flowError.supplementaryActions) { action in
                    supplementaryActionButton(action)
                }
                
                if let retryAction = flowError.retryAction {
                    retryButton(retryAction)
                }
                
                cancelButton()
                    .buttonStyle(.borderedProminent)
                
            case .hidden:
                EmptyView()
            }
            
            footer
        }
        
        func supplementaryActionButton(_ action: ErrorAction) -> some View {
            Button(role: action.role.map(ButtonRole.init)) {
                flowError.performAction(action)
            } label: {
                Text(action.title)
            }
        }
        
        func retryButton(_ action: ErrorAction) -> some View {
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
            visibility: actionsVisibility,
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
        actions: .includingCancel)
}

#Preview("Hidden Actions") {
    ErrorPresentationView(
        ErrorPresentation(
            flowError: FlowError(error: PreviewError())
                .onRetry { }
                .appendingAction("Repair") { },
            verbatimTitle: "An Error Occurred",
            message: "Could not frobnicate the fubar."),
        actions: .hidden)
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

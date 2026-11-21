import IssueReporting
import SwiftUI

// MARK: - ErrorPresentationView

/// A view that conveys an error state.
///
/// - Tip: In some scenarios, you might need to create a `FlowError`
/// with the `allowMultipleActionExecutions` flag, or the user might not
/// be able to select an action multiple times from the error
/// presentation view (such as an "Open Settings" supplementary action).
public struct ErrorPresentationView<Footer: View>: View {
    private enum ErrorSource: Equatable {
        case errorPresentation(ErrorPresentation)
        case flowError(FlowError)
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch(lhs, rhs) {
            case (.errorPresentation(let lhs), .errorPresentation(let rhs)):
                lhs == rhs
            case (.flowError(let lhs), .flowError(let rhs)):
                lhs.id == rhs.id
            default:
                false
            }
        }
    }
    
    @Environment(\.errorHandler) private var errorHandler
    @State private var errorPresentation: ErrorPresentation?
    private var source: ErrorSource
    private var cancelActionVisible: Bool
    private var footer: Footer
    
    /// Creates a view that displays an error presentation.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter cancelActionVisible: Whether the cancel action should
    ///   be visible.
    /// - parameter footer: A view to display below error actions.
    public init(
        _ errorPresentation: ErrorPresentation,
        cancelActionVisible: Bool = false,
        @ViewBuilder footer: (() -> Footer) = { EmptyView() })
    {
        self.source = .errorPresentation(errorPresentation)
        self.cancelActionVisible = cancelActionVisible
        self.footer = footer()
    }
    
    /// Creates a view that handles a flow error and displays an error
    /// presentation.
    ///
    /// - parameter flowError: A flow error.
    /// - parameter cancelActionVisible: Whether the cancel action should
    ///   be visible.
    /// - parameter footer: A view to display below error actions.
    public init(
        _ flowError: FlowError,
        cancelActionVisible: Bool = false,
        @ViewBuilder footer: (() -> Footer) = { EmptyView() })
    {
        self.source = .flowError(flowError)
        self.cancelActionVisible = cancelActionVisible
        self.footer = footer()
    }
    
    public var body: some View {
        content.onChange(of: source, initial: true) {
            switch source {
            case .errorPresentation(let presentation):
                errorPresentation = presentation
            case .flowError(let flowError):
                errorPresentation?.flowError.discard(.presentationCancelled)
                let presentation = errorHandler.handle(flowError).errorPresentation
                errorPresentation = presentation ?? ErrorPresentation(flowError: flowError)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let errorPresentation {
            ContentUnavailableView.error(
                errorPresentation,
                cancelActionVisible: cancelActionVisible,
                footer: { footer })
        } else {
            Color.clear
        }
    }
}

// MARK: - ContentUnavailableView

extension ContentUnavailableView {
    /// Creates a `ContentUnavailableView` instance that conveys an
    /// error state.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter cancelActionVisible: Whether the cancel action should
    ///   be visible.
    /// - parameter footer: A view to display below error actions.
    @MainActor
    fileprivate static func error<Footer: View>(
        _ errorPresentation: ErrorPresentation,
        cancelActionVisible: Bool = false,
        @ViewBuilder footer: () -> Footer)
    -> ContentUnavailableView<Label, Description, Actions>
    where Label == ErrorPresentationContent<Footer>.Label,
          Description == ErrorPresentationContent<Footer>.Description,
          Actions == ErrorPresentationContent<Footer>.Actions
    {
        let content = ErrorPresentationContent<Footer>(
            errorPresentation: errorPresentation,
            cancelActionVisible: cancelActionVisible,
            footer: footer())
        
        return ContentUnavailableView(
            label: content.label,
            description: content.description,
            actions: content.actions)
    }
}

// MARK: - ErrorPresentationContent

/// A structure that represents the body of an error view.
///
/// You don’t create this type directly. FlowErrorKit creates it when you
/// build an ``ErrorPresentationView``, or an error `ContentUnavailableView`.
@MainActor
struct ErrorPresentationContent<Footer: View> {
    var errorPresentation: ErrorPresentation
    var cancelActionVisible: Bool
    var footer: Footer
    
    public struct Label: View {
        var title: String
        var systemImage: String
        
        public var body: some View {
            SwiftUI.Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
            }
        }
    }
    
    public struct Description: View {
        var message: String?
        
        public var body: some View {
            if let message {
                Text(message)
            }
        }
    }
    
    public struct Actions: View {
        var flowError: FlowError
        var cancelActionVisible: Bool
        var footer: Footer
        
        public var body: some View {
            ForEach(flowError.supplementaryActions) { action in
                supplementaryActionButton(action)
            }
            
            if let retryAction = flowError.retryAction {
                if cancelActionVisible {
                    retryButton(retryAction)
                } else {
                    retryButton(retryAction)
                        .buttonStyle(.borderedProminent)
                }
            }
            
            if cancelActionVisible {
                cancelButton()
                    .buttonStyle(.borderedProminent)
            }
            
            footer
        }
        
        func supplementaryActionButton(_ action: ErrorAction) -> some View {
            Button(action.title, role: action.role.map(ButtonRole.init(role:))) {
                flowError.performAction(action)
            }
        }
        
        func retryButton(_ action: ErrorAction) -> some View {
            Button(action.title, role: action.role.map(ButtonRole.init(role:))) {
                flowError.performAction(action)
            }
        }
        
        func cancelButton() -> some View {
            Button(cancelTitle, role: .cancel) {
                flowError.performCancelAction()
            }
        }
        
        var cancelTitle: String {
            if let cancelTitle = flowError.cancelTitle {
                return cancelTitle
            } else if flowError.retryAction == nil && flowError.supplementaryActions.isEmpty {
                // Only possible action is cancel.
                return String(localized: .ok, bundle: .module)
            } else {
                return String(localized: .cancel, bundle: .module)
            }
        }
    }
    
    func label() -> Self.Label {
        Label(
            title: errorPresentation.title,
            systemImage: errorPresentation.systemImage)
    }
    
    func description() -> Self.Description {
        Description(message: errorPresentation.message)
    }
    
    func actions() -> Self.Actions {
        Actions(
            flowError: errorPresentation.flowError,
            cancelActionVisible: cancelActionVisible,
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
                title: "An Error Occurred",
                flowError: FlowError(error: PreviewError())
            )
        )
        
        Divider()
        
        ErrorPresentationView(
            ErrorPresentation(
                title: "Not connected to Internet",
                systemImage: "wifi.exclamationmark",
                flowError: FlowError(error: PreviewError())
            )
        )
    }
}

#Preview("Retry ErrorPresentation") {
    ErrorPresentationView(
        ErrorPresentation(
            title: "An Error Occurred",
            message: "Could not frobnicate the fubar.",
            flowError: FlowError(error: PreviewError()).onRetry { }
        )
    )
}

#Preview("Retry FlowError") {
    let flowError = FlowError(error: PreviewError()).onRetry { }
    ErrorPresentationView(flowError)
}

#Preview("Visible Cancel Action") {
    ErrorPresentationView(
        ErrorPresentation(
            title: "An Error Occurred",
            message: "Could not frobnicate the fubar.",
            flowError: FlowError(error: PreviewError()).onRetry { }
        ),
        cancelActionVisible: true
    )
}

#Preview("Custom Actions") {
    ErrorPresentationView(
        ErrorPresentation(
            title: "An Error Occurred",
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            flowError: FlowError(error: PreviewError())
                .onRetry { }
                .appendingAction("Quit") { }
                .appendingAction("Repair") { }
        )
    )
}

#Preview("Footer") {
    ErrorPresentationView(
        ErrorPresentation(
            title: "An Error Occurred",
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            flowError: FlowError(error: PreviewError()).onRetry { }
        ),
        footer: {
            ProgressView()
        }
    )
    .disabled(true)
}
#endif

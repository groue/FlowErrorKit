import IssueReporting
import SwiftUI

// MARK: - ErrorPresentationView

/// A view that conveys an error state.
///
/// - Tip: In some scenarios, you might need to create a `FlowError`
/// with the `allowMultipleActionExecutions` flag, or the user might not
/// be able to select an action multiple times from the error
/// presentation view (such as an "Open Settings" supplementary action).
///
/// ## Topics
///
/// ### Supporting Types
///
/// - ``ErrorPresentationContent``
public struct ErrorPresentationView<Footer: View>: View {
    @Environment(\.errorHandler) var handleError
    
    enum Source {
        case errorPresentation(ErrorPresentation)
        case flowError(FlowError)
    }
    var source: Source
    var cancelActionVisible: Bool
    var footer: Footer
    
    init(
        source: Source,
        cancelActionVisible: Bool,
        @ViewBuilder footer: (() -> Footer))
    {
        self.source = source
        self.cancelActionVisible = cancelActionVisible
        self.footer = footer()
    }
    
    public init(
        _ errorPresentation: ErrorPresentation,
        cancelActionVisible: Bool = false,
        @ViewBuilder footer: (() -> Footer) = { EmptyView() })
    {
        self.init(
            source: .errorPresentation(errorPresentation),
            cancelActionVisible: cancelActionVisible,
            footer: footer)
    }
    
    public init(
        _ flowError: FlowError,
        cancelActionVisible: Bool = false,
        @ViewBuilder footer: (() -> Footer) = { EmptyView() })
    {
        self.init(
            source: .flowError(flowError),
            cancelActionVisible: cancelActionVisible,
            footer: footer)
    }
    
    public init(
        _ error: any Error,
        cancelActionVisible: Bool = false,
        @ViewBuilder footer: (() -> Footer) = { EmptyView() })
    {
        self.init(
            FlowError(error: error),
            cancelActionVisible: false,
            footer: footer)
    }
    
    public var body: some View {
        if #available(iOS 17.0, *) {
            ContentUnavailableView.error(
                errorPresentation,
                cancelActionVisible: cancelActionVisible,
                footer: { footer })
        } else {
            legacyContent
        }
    }
    
    private var errorPresentation: ErrorPresentation {
        switch source {
        case let .errorPresentation(errorPresentation):
            return errorPresentation
        case let .flowError(flowError):
            if let errorPresentation = handleError.errorPresentation(flowError) {
                return errorPresentation
            } else {
                // TODO: we should make it statically impossible for ErrorPresentationView to have to deal with `.cancel` error handling.
                // For example, the user should provide specific code to run
                // when the error is "cancelled".
                reportIssue("""
                    ErrorPresentationView displays an error that was \
                    resolved to FlowErrorHandling.cancel: \(flowError.error)
                    """)
                return ErrorPresentation(flowError: flowError)
            }
        }
    }
    
    private var legacyContent: some View {
        let content = ErrorPresentationContent(
            errorPresentation: errorPresentation,
            cancelActionVisible: cancelActionVisible,
            footer: footer)
        
        return LegacyErrorPresentationView(
            label: content.label,
            description: content.description,
            actions: content.actions)
    }
}

/// A view that displays an `ErrorPresentation` when
/// `ContentUnavailableView` is not available.
private struct LegacyErrorPresentationView<Label: View, Description: View, Actions: View>: View {
    let label: Label
    let description: Description
    let actions: Actions
    
    init(
        @ViewBuilder label: () -> Label,
        @ViewBuilder description: () -> Description = { EmptyView() },
        @ViewBuilder actions: () -> Actions = { EmptyView() })
    {
        self.label = label()
        self.description = description()
        self.actions = actions()
    }
    
    var body: some View {
        // Mimic appearance of ContentUnavailableView
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                label
                    .labelStyle(ErrorLabelSyle())
                
                description
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
            VStack {
                actions
                    .controlSize(.small)
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
    }
    
    struct ErrorLabelSyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            VStack(spacing: 20) {
                configuration.icon
                    .imageScale(.large)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                configuration.title
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }
}

// MARK: - ErrorPresentationContent

/// A structure that represents the body of an error view.
///
/// You don’t create this type directly. SwiftUI creates it when you build
/// an error `ContentUnavailableView`.
@MainActor public struct ErrorPresentationContent<Footer: View> {
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
            Button(role: action.role.map(ButtonRole.init(role:))) {
                flowError.performAction(action)
            } label: {
                Text(action)
            }
        }
        
        func retryButton(_ action: ErrorAction) -> some View {
            Button(role: action.role.map(ButtonRole.init(role:))) {
                flowError.performAction(action)
            } label: {
                Text(action)
            }
        }
        
        func cancelButton() -> some View {
            Button(role: .cancel) {
                flowError.performCancelAction()
            } label: {
                cancelActionText
            }
        }
        
        var cancelActionText: Text {
            let defaulText: Text
            if flowError.retryAction == nil && flowError.supplementaryActions.isEmpty {
                // Only possible action is cancel.
                defaulText = Text(.ok)
            } else {
                defaulText = Text(.cancel)
            }
            
            if let cancelAction = flowError.cancelAction {
                return Text(cancelAction) ?? defaulText
            } else {
                return defaulText
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

#Preview("Retry") {
    ErrorPresentationView(
        ErrorPresentation(
            title: "An Error Occurred",
            message: "Could not frobnicate the fubar.",
            flowError: FlowError(error: PreviewError()).onRetry { }
        )
    )
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

#Preview("Direct Error or FlowError") {
    VStack {
        ErrorPresentationView(PreviewError())
        
        Divider()
        
        ErrorPresentationView(FlowError(error: PreviewError()).onRetry { })
        
        Divider()
        
        ErrorPresentationView(PreviewError())
            .handleError { flowError in
                    .present(ErrorPresentation(title: "Hey", flowError: flowError))
            }
    }
}
#endif

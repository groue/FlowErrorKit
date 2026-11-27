import SwiftUI

// MARK: - ErrorPresentationView

/// A view that conveys an error state.
///
/// An error presentation view is usually displayed by the
/// ``FlowErrorPresenter/errorPresentationView`` presenter, in place of
/// the content of a view that presents a flow error. To configure it,
/// use ``FlowErrorPresenter/errorPresentationView(_:)``:
///
/// ```swift
/// import FlowErrorKit
/// import SwiftUI
///
/// struct MyView: View {
///     @State private var flowError: FlowError?
///
///     var body: some View {
///         ContentView().presentError(
///             $flowError,
///             with: .errorPresentationView { errorPresentation in
///                 ErrorPresentationView(
///                     errorPresentation,
///                     cancelButton: .visible)
///             })
///     }
/// }
/// ```
///
/// When the user selects a button, the corresponding action of the flow
/// error is performed. The buttons are then disabled, unless the flow
/// error was created with the `allowMultipleActionExecutions` flag (see
/// ``FlowError/init(error:allowMultipleActionExecutions:)``).
///
/// In the DEBUG configuration, the error presentation view also
/// describes the presented error, so that developers can see what went
/// wrong.
///
/// ## Topics
///
/// ### Creating an Error Presentation View
///
/// - ``init(_:cancelButton:footer:)``
///
/// ### Building Custom Error Views
///
/// - ``ErrorPresentationLabel``
/// - ``ErrorPresentationDescription``
/// - ``ErrorPresentationActions``
public struct ErrorPresentationView<Footer: View>: View {
    private var errorPresentation: ErrorPresentation
    private var cancelButton: Visibility
    private var footer: Footer
    
    /// Creates a view that displays an error presentation.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter cancelButton: The visibility of the cancel button:
    ///   hidden unless `.visible`. This parameter is ignored when the view
    ///   starts presenting a flow error that cannot perform any
    ///   action, as reported by ``FlowError/canPerformAction``. In this
    ///   case, all action buttons are hidden.
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
        ContentUnavailableView {
            ErrorPresentationLabel(errorPresentation)
        } description: {
            ErrorPresentationDescription(errorPresentation)
        } actions: {
            ErrorPresentationActions(errorPresentation, cancelButton: cancelButton)
            footer
        }
    }
}

// MARK: - ErrorPresentationLabel

/// A view that displays the title and image of an error presentation.
///
/// For example:
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
///             .presentError(
///                 $flowError,
///                 with: .errorPresentationView { errorPresentation in
///                     ContentUnavailableView {
///                         ErrorPresentationLabel(errorPresentation)
///                     } description: {
///                         ErrorPresentationDescription(errorPresentation)
///                     } actions: {
///                         ErrorPresentationActions(errorPresentation)
///                     }
///                 })
///     }
/// }
/// ```
public struct ErrorPresentationLabel: View {
    private var errorPresentation: ErrorPresentation
    
    /// Creates a view that displays the title and image of an
    /// error presentation.
    public init(_ errorPresentation: ErrorPresentation) {
        self.errorPresentation = errorPresentation
    }
    
    public var body: some View {
        Label {
            Text(errorPresentation.title)
        } icon: {
            errorPresentation.image
        }
    }
}

// MARK: - ErrorPresentationDescription

/// A view that displays the subtitle and message of an
/// error presentation.
///
/// For example:
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
///             .presentError(
///                 $flowError,
///                 with: .errorPresentationView { errorPresentation in
///                     ContentUnavailableView {
///                         ErrorPresentationLabel(errorPresentation)
///                     } description: {
///                         ErrorPresentationDescription(errorPresentation)
///                     } actions: {
///                         ErrorPresentationActions(errorPresentation)
///                     }
///                 })
///     }
/// }
/// ```
///
/// In the DEBUG configuration, it also describes the presented error, so
/// that developers can see what went wrong.
public struct ErrorPresentationDescription: View {
    private var errorPresentation: ErrorPresentation
    @ScaledMetric private var spacing = 2
    
    /// Creates a view that displays the subtitle and message of an
    /// error presentation.
    public init(_ errorPresentation: ErrorPresentation) {
        self.errorPresentation = errorPresentation
    }
    
    public var body: some View {
        VStack(spacing: spacing) {
            if let subtitle = errorPresentation.subtitle {
                // Distinguish the subtitle from the text below.
                Text(subtitle)
                    .fontWeight(hasTextBelowSubtitle ? .semibold : nil)
            }
            if let message = errorPresentation.message {
                Text(message)
            }
#if DEBUG
            Text(verbatim: "DEBUG: \(errorPresentation.flowError.error)")
#endif
        }
    }
    
    private var hasTextBelowSubtitle: Bool {
#if DEBUG
        true
#else
        errorPresentation.message != nil
#endif
    }
}

// MARK: - ErrorPresentationActions

/// A view that displays the action buttons of an error presentation.
///
/// For example:
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
///             .presentError(
///                 $flowError,
///                 with: .errorPresentationView { errorPresentation in
///                     ContentUnavailableView {
///                         ErrorPresentationLabel(errorPresentation)
///                     } description: {
///                         ErrorPresentationDescription(errorPresentation)
///                     } actions: {
///                         ErrorPresentationActions(errorPresentation)
///                     }
///                 })
///     }
/// }
/// ```
///
/// When the user selects a button, the corresponding action of the flow
/// error is performed. The buttons are then disabled, unless the flow
/// error was created with the `allowMultipleActionExecutions` flag (see
/// ``FlowError/init(error:allowMultipleActionExecutions:)``).
public struct ErrorPresentationActions: View {
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
    private var cancelButtonVisibility: Visibility
    
    /// The visibility of actions, determined when a flow error is first
    /// displayed.
    ///
    /// It is not determined in the initializer, which runs during the
    /// body of the parent view: reading the observable
    /// ``FlowError/canPerformAction`` there would invalidate the parent
    /// view when an action is performed.
    @State private var actionsVisibility: ActionsVisibility?
    
    /// Creates a view that displays the action buttons of an
    /// error presentation.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter cancelButton: The visibility of the cancel button:
    ///   hidden unless `.visible`. This parameter is ignored when the view
    ///   starts presenting a flow error that cannot perform any
    ///   action. In this case, all action buttons are hidden.
    public init(
        _ errorPresentation: ErrorPresentation,
        cancelButton: Visibility = .automatic)
    {
        self.errorPresentation = errorPresentation
        self.cancelButtonVisibility = cancelButton
    }
    
    public var body: some View {
        Group {
            if !actionsHidden {
                buttons.disabled(!flowError.canPerformAction)
            }
        }
        .onChange(of: flowError.id, initial: true) {
            actionsVisibility = ActionsVisibility(flowError)
        }
    }
    
    private var flowError: FlowError {
        errorPresentation.flowError
    }
    
    private var actionsHidden: Bool {
        if let actionsVisibility, actionsVisibility.flowErrorID == flowError.id {
            return actionsVisibility.isHidden
        } else {
            // `actionsVisibility` is not determined yet for this flow
            // error (first render, or new flow error).
            return !flowError.canPerformAction
        }
    }
    
    @ViewBuilder
    private var buttons: some View {
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
            cancelButton
                .buttonStyle(.borderedProminent)
        }
    }
    
    private func actionButton(_ action: ErrorAction) -> some View {
        Button(role: action.role.map(ButtonRole.init)) {
            flowError.performAction(action)
        } label: {
            Text(action.title)
        }
    }
    
    private var cancelButton: some View {
        Button(role: .cancel) {
            flowError.performCancelAction()
        } label: {
            Text(cancelTitle)
        }
    }
    
    private var cancelTitle: TextSource {
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

#Preview("Components") {
    let errorPresentation = ErrorPresentation(
        flowError: FlowError(error: PreviewError()).onRetry { },
        verbatimTitle: "An Error Occurred",
        message: "Could not frobnicate the fubar.")
    
    ContentUnavailableView {
        ErrorPresentationLabel(errorPresentation)
    } description: {
        ErrorPresentationDescription(errorPresentation)
    } actions: {
        ErrorPresentationActions(errorPresentation, cancelButton: .visible)
    }
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

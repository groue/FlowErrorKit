import SwiftUI

/// A presenter that presents an alert when a flow error occurs.
///
/// In the DEBUG configuration, the alert message also describes the
/// presented error.
public struct AlertFlowErrorPresenter {
}

extension AlertFlowErrorPresenter: FlowErrorPresenter {
    /// The view modifier that presents flow errors with an alert.
    ///
    /// You don't create this type directly: use
    /// ``SwiftUICore/View/presentError(_:with:)``
    /// with the ``FlowErrorPresenter/alert`` presenter.
    public struct Modifier: ViewModifier {
        @Binding var flowError: FlowError?
        
        private struct AlertItem: Identifiable {
            var id: FlowError.ID { flowError.id }
            var errorPresentation: ErrorPresentation
            var flowError: FlowError { errorPresentation.flowError }
        }
        
        private enum Phase {
            /// No alert.
            case idle
            
            /// The alert waits for presentation (see the iOS workaround in
            /// `handleFlowError`).
            case pending(AlertItem)
            
            /// The alert is presented.
            case presented(AlertItem)
            
            /// The alert item, whether it is pending or presented.
            var alertItem: AlertItem? {
                switch self {
                case .idle:
                    nil
                case let .pending(item), let .presented(item):
                    item
                }
            }
            
            /// The alert item, only if it is presented: nil while the
            /// alert is pending.
            var presentedAlertItem: AlertItem? {
                if case let .presented(item) = self { item } else { nil }
            }
        }
        
        @Environment(\.errorHandler) private var errorHandler
        
        /// The presentation phase. Unless idle, the `flowError` binding
        /// holds the flow error of the alert.
        @State private var phase = Phase.idle
        
        private var dismissableAlertItem: Binding<AlertItem?> {
            Binding(
                get: { phase.presentedAlertItem },
                set: { newItem, transaction in
                    // SwiftUI only sets nil, when the alert is dismissed.
                    guard newItem == nil, let item = phase.presentedAlertItem else {
                        return
                    }

                    // SwiftUI also dismisses the alert without any user
                    // action, when the view disappears. No-op if the user
                    // has selected an action.
                    item.flowError.discard()

                    withTransaction(transaction) {
                        // Set flowError to nil, unless an action has set it
                        // to a new flow error.
                        if flowError?.id == item.id {
                            flowError = nil
                        }
                        phase = .idle
                    }
                })
        }
        
        public func body(content: Content) -> some View {
            content
                .alert(
                    alertTitle,
                    item: dismissableAlertItem,
                    actions: actions,
                    message: { item in
                        if let message = alertMessage(item) {
                            message
                        }
                    })
                .onChange(of: flowError?.id, initial: true, handleFlowError)
                .onDisappear(perform: didDisappear)
        }
        
        private func handleFlowError() {
            guard let flowError else {
                // Flow error programmatically dismissed: remove the alert
                // without performing any action.
                phase = .idle
                return
            }
            
            if let item = phase.alertItem {
                if flowError.id == item.id {
                    // The binding was restored below.
                    return
                }
                
                // Can't present because an alert is already presented, or
                // about to be presented. Discard the new flow error, and
                // restore the binding.
                _ = errorHandler.handle(flowError)
                flowError.discard()
                self.flowError = item.flowError
                return
            }
            
            guard let errorPresentation = errorHandler.handle(flowError).errorPresentation else {
                // Presentation cancelled by error handler.
                flowError.discard()
                self.flowError = nil
                return
            }
            
            // Present an alert.
            // The delay is a workaround for an iOS bug.
            let item = AlertItem(errorPresentation: errorPresentation)
            phase = .pending(item)
            Task {
                try? await Task.sleep(for: .seconds(0.1))
                // Present unless the flow error was dismissed in the
                // meantime.
                if case let .pending(pendingItem) = phase, pendingItem.id == item.id {
                    phase = .presented(item)
                }
            }
        }
        
        private func didDisappear() {
            phase = .idle
            if let flowError {
                flowError.discard()
                self.flowError = nil
            }
        }
        
        @ViewBuilder
        private func actions(_ presentedAlertItem: AlertItem) -> some View {
            let flowError = presentedAlertItem.flowError
            
            Button(role: .cancel) {
                perform(presentedAlertItem) { $0.performCancelAction() }
            } label: {
                Text(cancelButtonTitle(flowError))
            }
            
            ForEach(flowError.supplementaryActions) { action in
                Button(role: action.role.map(ButtonRole.init)) {
                    perform(presentedAlertItem) { $0.performAction(action) }
                } label: {
                    Text(action.title)
                }
            }
            
            if let retryAction = flowError.retryAction {
                Button(role: retryAction.role.map(ButtonRole.init)) {
                    perform(presentedAlertItem) { $0.performAction(retryAction) }
                } label: {
                    Text(retryAction.title)
                }
            }
        }
        
        private func perform(_ presentedAlertItem: AlertItem, action: (FlowError) -> Void) {
            guard phase.presentedAlertItem?.id == presentedAlertItem.id else {
                // This alert item is no longer presented
                return
            }
            action(presentedAlertItem.flowError)
        }
        
        
        private var alertTitle: TextSource? {
            phase.presentedAlertItem?.errorPresentation.title
        }
        
        /// Returns the alert message, as a single `Text`, because alerts
        /// only display the first `Text` of their message.
        private func alertMessage(_ item: AlertItem) -> Text? {
            var lines: [Text] = []
            if let subtitle = item.errorPresentation.subtitle {
                lines.append(Text(subtitle))
            }
            if let message = item.errorPresentation.message {
                lines.append(Text(message))
            }
#if DEBUG
            lines.append(Text(verbatim: "DEBUG: \(item.flowError.error)"))
#endif
            return lines.reduce(nil) { result, line in
                guard let result else { return line }
                return Text(
                    "\(result)\n\(line)",
                    bundle: .module,
                    comment: "Two lines of an error alert message. Do not translate.")
            }
        }
        
        private func cancelButtonTitle(_ flowError: FlowError) -> TextSource {
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
    
    public func makeModifier(flowError: Binding<FlowError?>) -> Modifier {
        Modifier(flowError: flowError)
    }
}

extension FlowErrorPresenter where Self == AlertFlowErrorPresenter {
    /// A presenter that presents an alert when a flow error occurs.
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
    ///             .presentError($flowError, with: .alert)
    ///     }
    /// }
    /// ```
    public static var alert: Self {
        AlertFlowErrorPresenter()
    }
}

#if DEBUG
private struct MyError: Error { }

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
        .presentError($flowError, with: .alert)
    }
    
    func performFailableAction() {
        do {
            if Bool.random() {
                throw MyError()
            }
            isSuccess = true
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

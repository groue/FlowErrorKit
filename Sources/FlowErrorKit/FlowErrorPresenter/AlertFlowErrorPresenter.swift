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
    /// ``SwiftUICore/View/presentError(_:with:)-(_,FlowErrorPresenter)``
    /// with the ``FlowErrorPresenter/alert`` presenter.
    public struct Modifier: ViewModifier {
        @Binding var flowError: FlowError?
        
        private struct AlertItem: Identifiable {
            var id: FlowError.ID { flowError.id }
            var errorPresentation: ErrorPresentation
            var flowError: FlowError { errorPresentation.flowError }
        }
        
        @Environment(\.errorHandler) private var errorHandler
        @State private var alertItem: AlertItem?
        /// The alert item that waits for presentation (see the iOS
        /// workaround in `handleFlowError`).
        @State private var pendingAlertItem: AlertItem?
        /// The id of a flow error that was not presented, because another
        /// alert was presented or about to be presented, and that is still
        /// held by the `flowError` binding.
        @State private var unpresentedFlowErrorID: FlowError.ID?
        private var dismissableAlertItem: Binding<AlertItem?> {
            Binding(
                get: { alertItem },
                set: { newItem in
                    // Set flowError to nil when alert is dismissed, unless
                    // it was set to a new flow error (from an error action,
                    // for example).
                    if newItem == nil, let alertItem, let flowError,
                       flowError.id == alertItem.id || flowError.id == unpresentedFlowErrorID
                    {
                        self.flowError = nil
                    }
                    alertItem = newItem
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
            if let flowError {
                if let errorPresentation = errorHandler.handle(flowError).errorPresentation {
                    if alertItem != nil || pendingAlertItem != nil {
                        // Can't present because an alert is already
                        // presented, or about to be presented.
                        flowError.discard(.presentationCancelled)
                        unpresentedFlowErrorID = flowError.id
                    } else {
                        // Present an alert.
                        // The delay is a workaround for an iOS bug.
                        let item = AlertItem(errorPresentation: errorPresentation)
                        pendingAlertItem = item
                        Task {
                            try? await Task.sleep(for: .seconds(0.1))
                            // Present unless the flow error was
                            // dismissed in the meantime.
                            if pendingAlertItem?.id == item.id {
                                pendingAlertItem = nil
                                alertItem = item
                            }
                        }
                    }
                } else {
                    // Presentation cancelled by error handler.
                    flowError.discard(.presentationCancelled)
                    // Don't discard current alert, if any
                    if alertItem == nil && pendingAlertItem == nil {
                        self.flowError = nil
                    } else {
                        unpresentedFlowErrorID = flowError.id
                    }
                }
            } else {
                // Flow error programmatically dismissed: remove the alert
                // without performing any action.
                pendingAlertItem = nil
                alertItem = nil
                unpresentedFlowErrorID = nil
            }
        }
        
        private func didDisappear() {
            if let flowError {
                flowError.discard(.presentationCancelled)
                self.flowError = nil
            }
            if let pendingAlertItem {
                pendingAlertItem.flowError.discard(.presentationCancelled)
                self.pendingAlertItem = nil
            }
            if let alertItem {
                alertItem.flowError.discard(.presentationCancelled)
                self.alertItem = nil
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
            guard alertItem?.id == presentedAlertItem.id else {
                // This alert item is no longer presented
                return
            }
            action(presentedAlertItem.flowError)
        }
        
        
        private var alertTitle: TextSource? {
            alertItem?.errorPresentation.title
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

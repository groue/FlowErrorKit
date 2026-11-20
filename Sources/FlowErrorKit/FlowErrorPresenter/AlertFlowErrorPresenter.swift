import SwiftUI

/// A presenter that presents an alert when a flow error occurs.
public struct AlertFlowErrorPresenter {
}

extension AlertFlowErrorPresenter: FlowErrorPresenter {
    public struct Modifier: ViewModifier {
        @Binding var flowError: FlowError?
        
        private struct AlertItem: Identifiable {
            var id: FlowError.ID { flowError.id }
            var errorPresentation: ErrorPresentation
            var flowError: FlowError { errorPresentation.flowError }
        }
        
        @Environment(\.errorHandler) private var errorHandler
        @State private var alertItem: AlertItem?
        private var dismissableAlertItem: Binding<AlertItem?> {
            Binding(
                get: { alertItem },
                set: { newItem in
                    // Set flowError to nil when alert is dismissed
                    if newItem == nil, let alertItem, alertItem.id == flowError?.id {
                        flowError = nil
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
                    message: {
                        if let message = $0.errorPresentation.message {
                            Text(message)
                        }
                    })
                .onChange(of: flowError?.id, initial: true, handleFlowError)
                .onDisappear(perform: didDisappear)
        }
        
        private func handleFlowError() {
            if let flowError {
                if let errorPresentation = errorHandler.handle(flowError).errorPresentation {
                    if alertItem != nil {
                        // Can't present because an alert is already presented.
                        flowError.discard(.presentationCancelled)
                    } else {
                        // Present an alert.
                        // The delay is a workaround for an iOS bug.
                        Task {
                            try? await Task.sleep(for: .seconds(0.1))
                            if self.flowError?.id == flowError.id {
                                alertItem = AlertItem(errorPresentation: errorPresentation)
                            }
                        }
                    }
                } else {
                    // Presentation cancelled by error handler.
                    flowError.discard(.presentationCancelled)
                    // Don't discard current alert, if any
                    if alertItem == nil {
                        self.flowError = nil
                    }
                }
            } else if let alertItem {
                // Flow error programmatically cancelled.
                alertItem.flowError.discard(.presentationCancelled)
                self.alertItem = nil
            }
        }
        
        private func didDisappear() {
            if let flowError {
                flowError.discard(.presentationCancelled)
                self.flowError = nil
            }
            if let alertItem {
                alertItem.flowError.discard(.presentationCancelled)
                self.alertItem = nil
            }
        }
        
        @ViewBuilder
        private func actions(_ presentedAlertItem: AlertItem) -> some View {
            let flowError = presentedAlertItem.flowError
            
            Button(cancelButtonTitle(flowError), role: .cancel) {
                perform(presentedAlertItem) { $0.performCancelAction() }
            }
            
            ForEach(flowError.supplementaryActions) { action in
                Button(action.title, role: action.role.map(ButtonRole.init(role:))) {
                    perform(presentedAlertItem) { $0.performAction(action) }
                }
            }
            
            if let retryAction = flowError.retryAction {
                Button(retryAction.title, role: retryAction.role.map(ButtonRole.init(role:))) {
                    perform(presentedAlertItem) { $0.performAction(retryAction) }
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
        
        
        private var alertTitle: String {
            alertItem?.errorPresentation.title ?? ""
        }
        
        private func cancelButtonTitle(_ flowError: FlowError) -> String {
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
                .onRetry(performFailableAction)
        }
    }
}

#Preview {
    MyView()
}
#endif

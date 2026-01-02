import SwiftUI

/// A presenter than presents an alert when a flow error occurs.
public struct AlertFlowErrorPresenter {
    public struct Modifier: ViewModifier {
        @Binding var flowError: FlowError?
        private var context: Context
        private var errorPresentation: ErrorPresentation? {
            context.errorPresentation
        }

        init(flowError: Binding<FlowError?>) {
            self._flowError = flowError
            self.context = Context(flowError: flowError)
        }
        
        public func body(content: Content) -> some View {
            content.alert(
                errorPresentation.map { Text(titleFor: $0) } ?? Text(verbatim: ""),
                isPresented: context.isErrorPresented,
                presenting: errorPresentation,
                actions: {
                    errorActions($0.flowError)
                },
                message: { errorPresentation in
                    Text(messageFor: errorPresentation)
                })
        }
        
        @ViewBuilder private func errorActions(_ flowError: FlowError) -> some View {
            if #available(iOS 26.0, *) {
                Button(role: .confirm) {
                    // Run user code on the next runloop cycle, so that it can
                    // immediately present another error.
                    DispatchQueue.main.async {
                        flowError.performCancelAction()
                    }
                } label: {
                    cancelActionText(flowError) 
                }
                .keyboardShortcut(.defaultAction)
            } else {
                Button(role: .cancel) {
                    // Run user code on the next runloop cycle, so that it can
                    // immediately present another error.
                    DispatchQueue.main.async {
                        flowError.performCancelAction()
                    }
                } label: {
                    cancelActionText(flowError)
                }
            }
            
            ForEach(flowError.supplementaryActions) { action in
                Button(role: action.role.map(ButtonRole.init(role:))) {
                    // Run user code on the next runloop cycle, so that it can
                    // immediately present another error.
                    DispatchQueue.main.async {
                        flowError.performAction(action)
                    }
                } label: {
                    Text(action)
                }
            }
            
            if let retryAction = flowError.retryAction {
                Button(role: retryAction.role.map(ButtonRole.init(role:))) {
                    // Run user code on the next runloop cycle, so that it can
                    // immediately present another error.
                    DispatchQueue.main.async {
                        flowError.performAction(retryAction)
                    }
                } label: {
                    Text(retryAction)
                }
            }
        }
        
        private func cancelActionText(_ flowError: FlowError) -> Text {
            let defaulText: Text
            if flowError.retryAction == nil && flowError.supplementaryActions.isEmpty {
                // Only possible action is cancel.
                defaulText = Text(.ok)
            } else {
                defaulText = Text(.close)
            }
            
            if let cancelAction = flowError.cancelAction {
                return Text(cancelAction) ?? defaulText
            } else {
                return defaulText
            }
        }
    }
    
    /// A DynamicProperty that updates view when a flowError binding changes.
    @MainActor private struct Context: DynamicProperty {
        @Environment(\.errorHandler) private var handleError
        
        /// A binding to the presented flow error.
        @Binding var flowError: FlowError?
        
        /// Inner state, tracks the currently presented error.
        @StateObject private var core = Core()
        
        /// The current error presentation.
        var errorPresentation: ErrorPresentation? {
            core.errorPresentation
        }
        
        /// A binding to a Boolean value that determines whether to present the
        /// error alert.
        var isErrorPresented: Binding<Bool> {
            Binding(
                get: { core.errorPresentation != nil },
                set: { presented in
                    if presented == false {
                        // TODO: this triggers a runtime warning when the error
                        // is programmatically dismissed. But when we postpone
                        // this code with DispatchQueue.main.async, this breaks
                        // the retry button (nothing happens when the retry
                        // button should present another alert). To investigate.
                        if flowError === core.presentedFlowError {
                            flowError = nil
                        } else {
                            core.presentedFlowError?.discard(.presentationCancelled)
                        }
                        core.presentedFlowError = nil
                        core.errorPresentation = nil
                    }
                })
        }
        
        nonisolated func update() {
            // Avoid the "Publishing changes from within view updates is not allowed" warning
            // by setting changing the error presentation on the next runloop cycle.
            DispatchQueue.main.async {
                core.updateErrorPresentation(
                    flowError: flowError,
                    handleError: handleError,
                    onCancelledPresentation: { (cancelledFlowError, cancelReason) in
                        // Update the flowError binding so that it reflect the reality
                        flowError = core.presentedFlowError
                        cancelledFlowError.discard(cancelReason)
                    })
            }
        }
        
        @MainActor private final class Core: ObservableObject {
            /// The current error presentation.
            @Published var errorPresentation: ErrorPresentation?
            
            /// The flow error that is currently presented.
            ///
            /// Note: it may be different from `errorPresentation.flowError`,
            /// because error handlers can transform flow errors. In this
            /// property we only store raw flow errors.
            var presentedFlowError: FlowError?
            
            /// - parameter onCancelledPresentation: A function that
            ///   is called if its flow error argument could not be presented.
            func updateErrorPresentation(
                flowError newFlowError: FlowError?,
                handleError: FlowErrorHandlerChain,
                onCancelledPresentation: (_ cancelledFlowError: FlowError, _ cancelReason: CancelErrorReason) -> Void)
            {
                // Only update error presentation if error identity has changed
                if newFlowError === self.presentedFlowError {
                    return
                }
                
                guard let newFlowError else {
                    // Error not set yet, or programmatically dismissed:
                    // stop presenting any error.
                    self.presentedFlowError = nil
                    self.errorPresentation = nil
                    return
                }
                
                // Log new flow error
                flowErrorLogger.error("❗️\(newFlowError.error)")
                
                // How is the new error presented?
                guard let newPresentation = handleError.errorPresentation(newFlowError) else {
                    // The new error is not presented (ignored error):
                    onCancelledPresentation(newFlowError, .presentationCancelled)
                    return
                }
                
                // Is there a conflict because we're already presenting an error?
                guard presentedFlowError == nil else {
                    // Don't replace the alert with another one: cancel the
                    // new error.
                    onCancelledPresentation(newPresentation.flowError, .presentationCancelled)
                    return
                }
                
                // Update the presentation
                self.presentedFlowError = newFlowError
                self.errorPresentation = newPresentation
            }
        }
    }
    
    public init() { }
}

extension AlertFlowErrorPresenter: FlowErrorPresenter {
    public func makeModifier(flowError: Binding<FlowError?>) -> Modifier {
        Modifier(flowError: flowError)
    }
}

extension FlowErrorPresenter where Self == AlertFlowErrorPresenter {
    /// A presenter than presents an alert when a flow error occurs.
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

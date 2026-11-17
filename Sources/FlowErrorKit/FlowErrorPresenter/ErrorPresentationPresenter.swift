import SwiftUI
import os.log

/// A presenter that updates an error presentation when a flow error occurs.
struct ErrorPresentationPresenter {
    @Binding var errorPresentation: ErrorPresentation?
    
    struct Modifier: ViewModifier {
        var context: Context
        
        init(flowError: Binding<FlowError?>, errorPresentation: Binding<ErrorPresentation?>) {
            context = Context(flowError: flowError, errorPresentation: errorPresentation)
        }
        
        func body(content: Content) -> some View {
            content
            // Apply some modifier so that the dynamic property can do its job
                .background { Color.clear }
        }
    }
    
    @MainActor
    struct Context: DynamicProperty {
        @Environment(\.errorHandler) private var handleError
        @Binding var flowError: FlowError?
        @Binding var errorPresentation: ErrorPresentation?
        
        /// The flow error that is currently presented.
        ///
        /// Note: it may be different from `errorPresentation.flowError`,
        /// because error handlers can transform flow errors. In this
        /// property we only store raw flow errors.
        @State var presentedFlowError: FlowError?
        
        nonisolated func update() {
            DispatchQueue.main.async {
                // Only update error presentation if error identity has changed
                if flowError === presentedFlowError {
                    return
                }
                
                guard let newFlowError = flowError else {
                    // Error not set yet, or programmatically dismissed:
                    // stop presenting any error.
                    presentedFlowError = nil
                    errorPresentation = nil
                    return
                }
                
                // Log new flow error
                flowErrorLogger.error("❗️\(newFlowError.error)")
                
                // How is the new error presented?
                guard let newPresentation = handleError.errorPresentation(newFlowError)
                else {
                    // The new error is not presented (ignored error):
                    newFlowError.discard(.presentationCancelled)
                    
                    // Update flowError so that it reflects reality
                    flowError = presentedFlowError
                    return
                }
                
                // Is there a conflict because we're already presenting an error?
                if let presentedFlowError {
                    presentedFlowError.discard(.presentationCancelled)
                }
                
                // Update the presentation
                presentedFlowError = newFlowError
                errorPresentation = newPresentation
            }
        }
    }
}

extension ErrorPresentationPresenter: FlowErrorPresenter {
    func makeModifier(flowError: Binding<FlowError?>) -> Modifier {
        Modifier(flowError: flowError, errorPresentation: $errorPresentation)
    }
}

#if DEBUG
private struct MyError: Error { }

private struct MyView: View {
    @State private var flowError: FlowError?
    @State private var errorPresentation: ErrorPresentation?
    @State var isSuccess = false
    
    var body: some View {
        Group {
            if let errorPresentation {
                ErrorPresentationView(errorPresentation)
            } else {
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
            }
        }
        // Capture and present the flow error
        .presentError($flowError, with: $errorPresentation)
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

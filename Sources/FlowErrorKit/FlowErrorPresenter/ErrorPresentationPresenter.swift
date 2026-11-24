import SwiftUI

/// A presenter that updates an error presentation when a flow error occurs.
struct ErrorPresentationPresenter {
    var errorPresentation: Binding<ErrorPresentation?>
}

extension ErrorPresentationPresenter: FlowErrorPresenter {
    func makeModifier(flowError: Binding<FlowError?>) -> ErrorPresentationModifier {
        ErrorPresentationModifier(flowError: flowError, errorPresentation: errorPresentation)
    }
}

struct ErrorPresentationModifier: ViewModifier {
    @Binding var flowError: FlowError?
    @Binding var errorPresentation: ErrorPresentation?
    @Environment(\.errorHandler) private var errorHandler
    
    func body(content: Content) -> some View {
        content
            .onChange(of: flowError?.id, initial: true, handleFlowError)
    }
    
    private func handleFlowError() {
        if let flowError {
            if let newPresentation = errorHandler.handle(flowError).errorPresentation {
                // Replace the current presentation, if any.
                if let errorPresentation {
                    errorPresentation.flowError.discard(.presentationCancelled)
                }
                errorPresentation = newPresentation
            } else {
                // Presentation cancelled by error handler.
                flowError.discard(.presentationCancelled)
                // Don't discard current presentation, if any
                if errorPresentation == nil {
                    self.flowError = nil
                }
            }
        } else if errorPresentation != nil {
            // Flow error programmatically dismissed: remove the presentation
            // without performing any action.
            self.errorPresentation = nil
        }
    }
}

#if DEBUG
private struct MyError: Error {
    var value: Int = Int.random(in: 1...1000)
}

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
                .onRetry(action: performFailableAction)
        }
    }
}

#Preview {
    MyView()
}
#endif

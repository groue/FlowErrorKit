import SwiftUI
import FlowErrorKit

private struct IgnoredError: Error, CustomStringConvertible {
    var count: Int
    
    var description: String {
        "IgnoredError(\(count))"
    }
}

private struct CountedError: Error, CustomStringConvertible {
    var count: Int
    
    var description: String {
        "CountedError(\(count))"
    }
}

struct ConflictingErrorPresentationsView: View {
    @State var count = 0
    @State var events: [String] = []
    @State var flowError: FlowError?
    @State var errorPresentation: ErrorPresentation?
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack {
                    Button("Clear log") {
                        events = []
                    }
                    
                    errorButtons()
                    
                    Button("Discard error") {
                        flowError = nil
                    }
                    
                    if let flowError {
                        Text("flowError: \(String(describing: flowError.error))")
                    } else {
                        Text("flowError: none")
                    }
                }
                .buttonStyle(.bordered)
            }
            
            Divider()
            
            ScrollView {
                Text("""
                    There should be as many ➡️ as ⬅️ after errors have \
                    been handled by the user. Unless an error is \
                    discarded, in which case no action is not executed and \
                    there is no ⬅️.
                    """)
                
                .padding(.bottom)
                .padding(.horizontal)
                Text(events.joined(separator: "\n"))
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            
            Divider()
            
            if let errorPresentation {
                ErrorPresentationView(errorPresentation, cancelActionVisible: true, footer: {
                    errorButtons()
                })
            } else {
                Color.clear.frame(maxHeight: .infinity)
            }
        }
        .presentError($flowError, with: $errorPresentation)
        .handleError(ofType: IgnoredError.self) { _, _ in
            return .cancel
        }
        .handleError(ofType: CountedError.self) { flowError, err in
            return .present(ErrorPresentation(
                title: String(describing: err),
                flowError: flowError))
        }
    }
    
    @ViewBuilder
    func errorButtons() -> some View {
        Button("Throw CountedError") {
            count += 1
            throwError(CountedError(count: count))
        }
        
        Button("Throw IgnoredError") {
            count += 1
            throwError(IgnoredError(count: count))
        }
    }
    
    func throwError(_ error: Error) {
        events.append("➡️ \(error)")
        flowError = FlowError(error: error, allowMultipleActionExecutions: true)
            .onCancel { reason in
                events.append("⏹️ \(error)")
                if reason == .userCancelled {
                    // Discard the error
                    flowError = nil
                }
            }
            .onRetry {
                events.append("🔄 \(error)")
                throwError(error)
            }
            .finally {
                events.append("⬅️ \(error)")
            }
    }
}

#Preview {
    ConflictingErrorPresentationsView()
}

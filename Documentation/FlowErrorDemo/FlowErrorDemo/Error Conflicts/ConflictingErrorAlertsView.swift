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

struct ConflictingErrorAlertsView: View {
    @State var count = 0
    @State var events: [String] = []
    @State var flowError: FlowError?
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack {
                    errorButtons()
                    
                    if let flowError {
                        Text("flowError: \(String(describing: flowError.error))")
                    } else {
                        Text("flowError: nil")
                    }
                }
                .buttonStyle(.bordered)
                
            }
            
            Divider()
            
            ScrollView {
                Text("""
                    There should be as many ➡️ as ⬅️ after errors have \
                    been handled by the user, unless an error is \
                    discarded, in which case no action is executed and \
                    there is no ⬅️.
                    """)
                .padding(.bottom)
                .padding(.horizontal)
                
                Text(events.joined(separator: "\n"))
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .presentError($flowError, with: .alert)
        .handleError(ofType: IgnoredError.self) { _, _ in
            return .cancel
        }
        .handleError(ofType: CountedError.self) { flowError, err in
            return .present(ErrorPresentation(
                title: "\(err)",
                flowError: flowError))
        }
    }
    
    @ViewBuilder
    func errorButtons() -> some View {
        Button("Clear log") {
            events = []
        }
        
        Button("Throw CountedError") {
            count += 1
            throwError(CountedError(count: count))
        }
        
        Button("Throw CountedError in 3s") {
            Task {
                try? await Task.sleep(for: .seconds(3))
                count += 1
                throwError(CountedError(count: count))
            }
        }
        
        Button("Throw IgnoredError") {
            count += 1
            throwError(IgnoredError(count: count))
        }
        
        Button("Throw IgnoredError in 3s") {
            Task {
                try? await Task.sleep(for: .seconds(3))
                count += 1
                throwError(IgnoredError(count: count))
            }
        }
        
        Button("Discard error in 3s") {
            Task {
                try? await Task.sleep(for: .seconds(3))
                flowError = nil
            }
        }
    }
    
    func throwError(_ error: Error) {
        events.append("➡️ \(error)")
        flowError = FlowError(error: error, allowMultipleActionExecutions: true)
            .onCancel { reason in
                events.append("⏹️ \(error)")
                if reason == .userCancelled {
                    #warning("TODO: why?")
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
    ConflictingErrorAlertsView()
}

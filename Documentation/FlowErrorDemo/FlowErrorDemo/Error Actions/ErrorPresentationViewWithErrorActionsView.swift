import Foundation
import SwiftUI
import FlowErrorKit

struct ErrorPresentationViewWithErrorActionsView: View {
    private var sourceLocation: SourceLocation
    private var allowMultipleActionExecutions: Bool
    private var failureProbability: Double
    private var makeError: () -> Error
    @Environment(\.dismiss) var dismiss
    @State private var emoji: String?
    @State private var flowError: FlowError?
    
    /// - Parameters:
    ///   - error: The thrown error.
    ///   - failureProbability: The probability that the error is thrown.
    init(
        error: @autoclosure @escaping () -> Error,
        allowMultipleActionExecutions: Bool = false,
        failureProbability: Double = 0.5,
        file: StaticString = #fileID,
        line: Int = #line)
    {
        self.sourceLocation = SourceLocation(file: file, line: line)
        self.makeError = error
        self.failureProbability = failureProbability
        self.allowMultipleActionExecutions = allowMultipleActionExecutions
    }
    
    var body: some View {
        VStack {
            EmojiView(emoji: emoji)
            
            Button("Pick an Emoji") { pickEmoji() }
                .buttonStyle(.bordered)
            
            Text("Failure probability: \(failureProbability, format: .percent)")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        
        // Capture and present the flow error
        .presentError($flowError, with: .errorPresentationView { errorPresentation in
            ErrorPresentationView(errorPresentation, cancelButton: .visible)
        })
        
        .sourceLocation(sourceLocation: sourceLocation)
    }
    
    func pickEmoji() {
        do {
            emoji = try randomEmoji(
                throwing: makeError(),
                failureProbability: failureProbability)
            // Success: stop presenting the error, if any (for example,
            // after a successful retry).
            flowError = nil
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error, allowMultipleActionExecutions: allowMultipleActionExecutions)
                .onCancel { reason in
                    if reason == .userCancelled {
                        // Only dismiss if user explicitly selects the Cancel button.
                        dismiss()
                    }
                }
                .onRetry(action: pickEmoji)
        }
    }
}

#Preview {
    ErrorPresentationViewWithErrorActionsView(error: URLError.networkConnectionLostError)
}

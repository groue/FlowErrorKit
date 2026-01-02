import Foundation
import SwiftUI
import FlowErrorKit

struct ErrorPresentationViewWithErrorActionsView: View {
    private var sourceLocation: SourceLocation
    private let failureProbability: Double
    private let makeError: () -> Error
    @Environment(\.dismiss) var dismiss
    @State private var emoji: String?
    @State private var flowError: FlowError?
    @State private var errorPresentation: ErrorPresentation?
    
    /// - Parameters:
    ///   - error: The thrown error.
    ///   - failureProbability: The probability that the error is thrown.
    init(
        error: @autoclosure @escaping () -> Error,
        failureProbability: Double = 0.5,
        file: StaticString = #fileID,
        line: Int = #line)
    {
        self.sourceLocation = SourceLocation(file: file, line: line)
        self.makeError = error
        self.failureProbability = failureProbability
    }
    
    var body: some View {
        Group {
            if let errorPresentation {
                ErrorPresentationView(errorPresentation, cancelActionVisible: true)
            } else {
                VStack {
                    EmojiView(emoji: emoji)
                    
                    Button("Pick an Emoji") { pickEmoji() }
                        .buttonStyle(.bordered)
                    
                    Text("Failure probability: \(failureProbability, format: .percent)")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
            }
        }
        
        // Capture and present the flow error
        .presentError($flowError, with: $errorPresentation)
        
        .sourceLocation(sourceLocation: sourceLocation)
    }
    
    func pickEmoji() {
        do {
            emoji = try randomEmoji(
                throwing: makeError(),
                failureProbability: failureProbability)
            
            // Discard the error
            flowError = nil
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
                .withTitle("Could not pick an emoji")
                .onCancel { reason in
                    if reason == .userCancelled {
                        // Only dismiss if user explicitly selects the Cancel button.
                        dismiss()
                    }
                }
                .onRetry(pickEmoji)
        }
    }
}

#Preview {
    ErrorPresentationViewWithErrorActionsView(error: URLError.networkConnectionLostError)
}

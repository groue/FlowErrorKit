import Foundation
import SwiftUI
import FlowErrorKit

struct AlertWithErrorActionsView: View {
    private var sourceLocation: SourceLocation
    private let failureProbability: Double
    private let makeError: () -> Error
    @State private var emoji: String?
    @State private var flowError: FlowError?
    
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
        VStack {
            EmojiView(emoji: emoji)
            
            Button("Pick an Emoji") { pickEmoji() }
                .buttonStyle(.bordered)
            
            Text("Failure probability: \(failureProbability, format: .percent)")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        
        // Capture and present the flow error
        .presentError($flowError, with: .alert)
        
        .sourceLocation(sourceLocation: sourceLocation)
    }
    
    func pickEmoji() {
        do {
            emoji = try randomEmoji(
                throwing: makeError(),
                failureProbability: failureProbability)
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
                .withTitle("Could not pick an emoji")
                .onCancel { _ in emoji = nil }
                .onRetry(pickEmoji)
        }
    }
}

#Preview {
    AlertWithErrorActionsView(error: URLError.networkConnectionLostError)
}

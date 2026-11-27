import Foundation
import SwiftUI
import FlowErrorKit

struct BasicErrorPresentationView: View {
    private var sourceLocation: SourceLocation
    private let failureProbability = 1.0
    @State private var emoji: String?
    @State private var flowError: FlowError?
    
    init(
        file: StaticString = #fileID,
        line: Int = #line)
    {
        sourceLocation = SourceLocation(file: file, line: line)
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
        .presentError($flowError, with: .errorPresentationView)
        
        .sourceLocation(sourceLocation: sourceLocation)
    }
    
    func pickEmoji() {
        do {
            emoji = try randomEmoji(
                throwing: URLError.networkConnectionLostError,
                failureProbability: failureProbability)
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
        }
    }
}

#Preview {
    BasicErrorPresentationView()
}

import Foundation
import SwiftUI
import FlowErrorKit

struct BasicErrorPresentationView: View {
    private var sourceLocation: SourceLocation
    private let failureProbability = 1.0
    @State private var emoji: String?
    @State private var flowError: FlowError?
    @State private var errorPresentation: ErrorPresentation?
    
    init(
        file: StaticString = #fileID,
        line: Int = #line)
    {
        sourceLocation = SourceLocation(file: file, line: line)
    }
    
    var body: some View {
        Group {
            if let errorPresentation {
                ErrorPresentationView(errorPresentation)
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
                throwing: URLError.networkConnectionLostError,
                failureProbability: failureProbability)
            
            // Discard the error
            flowError = nil
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
        }
    }
}

#Preview {
    BasicErrorPresentationView()
}

import FlowErrorKit
import Foundation
import Observation
import SwiftUI

@MainActor @Observable final class BasicErrorPresentationMVVMViewModel {
    let failureProbability = 1.0
    private(set) var emoji: String?
    var flowError: FlowError?
    
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

struct BasicErrorPresentationMVVMView: View {
    private var sourceLocation: SourceLocation
    @State private var viewModel = BasicErrorPresentationMVVMViewModel()
    @State var errorPresentation: ErrorPresentation?
    
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
                    EmojiView(emoji: viewModel.emoji)
                    
                    Button("Pick an Emoji") { viewModel.pickEmoji() }
                        .buttonStyle(.bordered)
                    
                    Text("Failure probability: \(viewModel.failureProbability, format: .percent)")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }
            }
        }
        
        // Capture and present the flow error
        .presentError($viewModel.flowError, with: $errorPresentation)
        
        .sourceLocation(sourceLocation: sourceLocation)
    }
}

#Preview {
    BasicErrorPresentationMVVMView()
}

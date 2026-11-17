import FlowErrorKit
import Foundation
import Observation
import SwiftUI

@MainActor @Observable final class AlertWithErrorActionsMVVMViewModel {
    let failureProbability: Double
    private let makeError: @MainActor () -> Error
    private(set) var emoji: String?
    var flowError: FlowError?
    
    init(
        makeError: @escaping @MainActor () -> Error,
        failureProbability: Double)
    {
        self.makeError = makeError
        self.failureProbability = failureProbability
    }
    
    func pickEmoji() {
        do {
            emoji = try randomEmoji(
                throwing: makeError(),
                failureProbability: failureProbability)
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
                .onCancel { _ in self.emoji = nil }
                .onRetry(pickEmoji)
        }
    }
}

struct AlertWithErrorActionsMVVMView: View {
    private var sourceLocation: SourceLocation
    @State private var viewModel: AlertWithErrorActionsMVVMViewModel
    
    /// - Parameters:
    ///   - error: The thrown error.
    ///   - failureProbability: The probability that the error is thrown.
    init(
        error: @autoclosure @escaping @MainActor () -> Error,
        failureProbability: Double = 0.5,
        file: StaticString = #fileID,
        line: Int = #line)
    {
        sourceLocation = SourceLocation(file: file, line: line)
        _viewModel = State(initialValue: AlertWithErrorActionsMVVMViewModel(
            makeError: error,
            failureProbability: failureProbability))
    }
    
    var body: some View {
        VStack {
            EmojiView(emoji: viewModel.emoji)
            
            Button("Pick an Emoji") { viewModel.pickEmoji() }
                .buttonStyle(.bordered)
            
            Text("Failure probability: \(viewModel.failureProbability, format: .percent)")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        
        // Capture and present the flow error
        .presentError($viewModel.flowError, with: .alert)
        
        .sourceLocation(sourceLocation: sourceLocation)
    }
}

#Preview {
    AlertWithErrorActionsMVVMView(error: URLError.networkConnectionLostError)
}

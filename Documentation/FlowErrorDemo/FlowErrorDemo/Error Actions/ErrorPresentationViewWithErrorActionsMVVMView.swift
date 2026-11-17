import FlowErrorKit
import Foundation
import Observation
import SwiftUI

@MainActor @Observable final class ErrorPresentationViewWithErrorActionsMVVMViewModel {
    let failureProbability: Double
    private let makeError: @MainActor () -> Error
    private(set) var emoji: String?
    var flowError: FlowError?
    private(set) var needsDismiss = false
    
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
            // Success: stop presenting the error, if any (for example,
            // after a successful retry).
            flowError = nil
        } catch {
            // Turn the error into a FlowError
            flowError = FlowError(error: error)
                .onCancel { reason in
                    if reason == .userCancelled {
                        // Only dismiss if user explicitly selects the Cancel button.
                        self.needsDismiss = true
                    }
                }
                .onRetry(pickEmoji)
        }
    }
}

struct ErrorPresentationViewWithErrorActionsMVVMView: View {
    private var sourceLocation: SourceLocation
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: ErrorPresentationViewWithErrorActionsMVVMViewModel
    @State private var errorPresentation: ErrorPresentation?
    
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
        _viewModel = State(initialValue: ErrorPresentationViewWithErrorActionsMVVMViewModel(
            makeError: error,
            failureProbability: failureProbability))
    }
    
    var body: some View {
        Group {
            if let errorPresentation {
                ErrorPresentationView(errorPresentation, cancelActionVisible: true)
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
        .onChange(of: viewModel.needsDismiss) {
            if viewModel.needsDismiss {
                dismiss()
            }
        }
        
        // Capture and present the flow error
        .presentError($viewModel.flowError, with: $errorPresentation)
        
        .sourceLocation(sourceLocation: sourceLocation)
    }
}

#Preview {
    ErrorPresentationViewWithErrorActionsMVVMView(error: URLError.networkConnectionLostError)
}

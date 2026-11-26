import FlowErrorKit
import SwiftUI

// The alert sample of the README, with some document content.
struct DocumentView: View {
    @State private var text = """
        Shopping list

        - Apples
        - Bread
        - Cheese
        - Eggs
        - Milk
        """
    @State private var flowError: FlowError?

    var body: some View {
        TextEditor(text: $text)
            .padding(.horizontal)
            .navigationTitle("Document")
            .toolbar {
                Button("Save") {
                    save()
                }
            }
            .presentError($flowError, with: .alert)
    }

    func save() {
        do {
            try saveDocument()
        } catch {
            flowError = FlowError(error: error)
                .withTitle("Could not save the document")
                .onRetry { save() }
        }
    }
}

private func saveDocument() throws {
    // What URLSession throws when the device is offline.
    throw URLError(.notConnectedToInternet, userInfo: [
        NSLocalizedDescriptionKey: "The Internet connection appears to be offline.",
    ])
}

#Preview {
    NavigationStack {
        DocumentView()
    }
}

import FlowErrorKit
import SwiftUI

// An error that no handler handles, presented with an alert. Run in the
// Debug configuration, so that the alert describes the error.
struct UnhandledErrorView: View {
    @State private var name = "Johnny Appleseed"
    @State private var email = "johnny@example.com"
    @State private var flowError: FlowError?

    var body: some View {
        Form {
            Section("Contact") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            Button("Save") {
                save()
            }
        }
        .presentError($flowError, with: .alert)
    }

    func save() {
        do {
            try saveProfile()
        } catch {
            flowError = FlowError(error: error)
        }
    }
}

private struct ServerError: Error {
    var statusCode: Int
}

private func saveProfile() throws {
    throw ServerError(statusCode: 401)
}

#Preview {
    NavigationStack {
        UnhandledErrorView()
    }
}

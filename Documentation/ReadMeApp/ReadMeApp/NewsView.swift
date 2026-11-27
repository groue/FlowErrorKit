import FlowErrorKit
import SwiftUI

// The ErrorPresentationView sample of the README.
struct NewsView: View {
    @State private var news: [Article] = []
    @State private var flowError: FlowError?

    var body: some View {
        List(news) { article in Text(article.title) }
            .presentError($flowError, with: .errorPresentationView)
            .navigationTitle("News")
            .task { await load() }
    }

    func load() async {
        do {
            news = try await fetchNews()
            flowError = nil // Success: remove the error presentation
        } catch {
            flowError = FlowError(error: error)
                .withTitle("Could not load the news")
                .onRetry { Task { await load() } }
        }
    }
}

struct Article: Identifiable {
    var id: Int
    var title: String
}

private func fetchNews() async throws -> [Article] {
    // What URLSession throws when the device is offline.
    throw URLError(.notConnectedToInternet, userInfo: [
        NSLocalizedDescriptionKey: "The Internet connection appears to be offline.",
    ])
}

#Preview {
    NewsView()
}

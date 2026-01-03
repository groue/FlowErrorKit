import Observation

@Observable final class MainViewModel {
    var emoji: String?
    private(set) var isLoadingEmoji = false
    
    var demoError: Error?
    
    /// When this method returns without error, emoji is set.
    func loadEmoji(session: Session) async throws {
        assert(!isLoadingEmoji, "Already fetching")
        isLoadingEmoji = true
        defer { isLoadingEmoji = false }
        
        try await Task.sleep(for: .seconds(0.5))
        
        if let demoError {
            throw demoError
        }
        
        emoji = [
            "🙂", "😁", "😅", "😜", "🤓",
            "😡", "😨", "😵", "😬", "🤯",
            "🎃", "👻", "😈", "👍", "👎",
            "🤞", "🌼", "🐛", "🍀", "💣",
            "💥", "🌈", "❤️", "⚠️", "🎶",
        ].randomElement()!
    }
}

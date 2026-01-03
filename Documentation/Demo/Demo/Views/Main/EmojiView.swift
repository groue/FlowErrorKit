import SwiftUI

/// A view that displays an emoji and animates its change.
struct EmojiView: View {
    let emoji: String?
    @State private var animatedEmoji: String?
    
    var body: some View {
        emojiView
            .id(animatedEmoji)
            .transition(.scale)
            .onAppear {
                animatedEmoji = emoji
            }
            .onChange(of: emoji) {
                withAnimation {
                    animatedEmoji = emoji
                }
            }
    }
    
    @ViewBuilder
    var emojiView: some View {
        if let emoji = animatedEmoji {
            Text(emoji)
        } else {
            Image(systemName: "circle.dashed")
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Preview

#Preview {
    struct EmojiPreview: View {
        @State var emoji: String?
        
        var body: some View {
            VStack {
                EmojiView(emoji: emoji)
                
                Button("Pick an Emoji") {
                    emoji = [
                        "🙂", "😁", "😅", "😜", "🤓",
                        "😡", "😨", "😵", "😬", "🤯",
                        "🎃", "👻", "😈", "👍", "👎",
                        "🤞", "🌼", "🐛", "🍀", "💣",
                        "💥", "🌈", "❤️", "⚠️", "🎶",
                    ].randomElement()!
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    return EmojiPreview()
}

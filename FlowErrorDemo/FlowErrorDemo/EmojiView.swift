import SwiftUI

/// A view that displays an emoji and animates its change.
struct EmojiView: View {
    let emoji: String?
    @State private var animatedEmoji: String?
    
    var body: some View {
        Text(text)
            .font(.system(size: 60))
            .foregroundStyle(animatedEmoji == nil ? .quaternary : .primary)
            .id(animatedEmoji)
            .transition(.scale)
            .onAppear { animatedEmoji = emoji }
            .onChange(of: emoji) {
                withAnimation {
                    animatedEmoji = emoji
                }
            }
    }
    
    var text: LocalizedStringKey {
        if let animatedEmoji {
            return "\(animatedEmoji)"
        } else {
            return "\(Image(systemName: "circle.dashed"))"
        }
    }
}

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

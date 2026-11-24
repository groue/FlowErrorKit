import SwiftUI

/// A view that displays an emoji and animates its change.
struct EmojiView: View {
    let emoji: String?
    @State private var animatedEmoji: String?
    
    var body: some View {
        content
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
    
    @ViewBuilder
    var content: some View {
        if let animatedEmoji {
            Text(animatedEmoji)
        } else {
            Image(systemName: "circle.dashed")
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
                    emoji = try! randomEmoji(
                        throwing: URLError.networkConnectionLostError,
                        failureProbability: 0)
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    return EmojiPreview()
}

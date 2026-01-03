import FlowErrorKit
import SwiftUI

struct MainView: SignedInView {
    func body(session: Session) -> some View {
        NavigationStack {
            ZStack {
                Color.demoYellow.ignoresSafeArea()
                ContentView(session: session)
            }
        }
    }
}

private struct ContentView: View {
    var session: Session
    var emojiFontSize: CGFloat { 100 }
    var emojiFrameSize: CGFloat { 150 }
    @State var viewModel = MainViewModel()
    @State var flowError: FlowError?
    
    var body: some View {
        VStack(spacing: 40) {
            EmojiView(emoji: viewModel.emoji)
                .frame(width: emojiFrameSize, height: emojiFrameSize)
                .background {
                    Circle().foregroundStyle(.background)
                }
                .font(.system(size: emojiFontSize))
            
            HStack {
                loadEmojiButton
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                
                ErrorPicker(selection: $viewModel.demoError, availableErrors: [
                    .URLError_notConnectedToInternet,
                    .APIError_forbidden,
                    .APIError_unauthorized,
                ])
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(4)
            .background {
                Capsule()
                    .fill(.tint.opacity(0.05))
                    .stroke(.tint.opacity(0.5), lineWidth: 1)
            }
        }
        .padding(.horizontal)
        .toolbar {
            ToolbarItem {
                Menu("Account", systemImage: "person.fill") {
                    SignOutButton()
                }
            }
        }
        .presentError($flowError, with: .alert)
    }
    
    var loadEmojiButton: some View {
        Button {
            Task { await loadEmoji() }
        } label: {
            ZStack {
                ProgressView()
                    .opacity(viewModel.isLoadingEmoji ? 1 : 0)
                Text("Download")
                    .opacity(viewModel.isLoadingEmoji ? 0 : 1)
            }
        }
        .disabled(viewModel.isLoadingEmoji)
    }
    
    func loadEmoji() async {
        do {
            try await viewModel.loadEmoji(session: session)
        } catch {
            flowError = FlowError(error: error)
        }
    }
}

// MARK: - Preview

#Preview {
    MainView().environment(\.session, Session())
}

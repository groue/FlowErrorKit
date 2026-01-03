import SwiftUI

struct MainView: SignedInView {
    func body(session: Session) -> some View {
        NavigationStack {
            ZStack {
                Color.demoYellow.ignoresSafeArea()
                content
            }
            .toolbar {
                ToolbarItem {
                    Menu("Account", systemImage: "person.fill") {
                        SignOutButton()
                    }
                }
            }
        }
    }
    
    var content: some View {
        Text(verbatim: "MainView")
    }
}

// MARK: - Preview

#Preview {
    MainView().environment(\.session, Session())
}

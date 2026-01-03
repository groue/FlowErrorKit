import SwiftUI

struct MainView: SignedInView {
    @Environment(\.signOut) private var signOut
    
    func body(session: Session) -> some View {
        NavigationStack {
            ZStack {
                Color.demoYellow.ignoresSafeArea()
                content
            }
                .toolbar {
                    ToolbarItem {
                        Menu("Account", systemImage: "person.fill") {
                            Button("Sign Out") { signOut() }
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

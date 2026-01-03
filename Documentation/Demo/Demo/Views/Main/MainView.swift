import SwiftUI

struct MainView: SignedInView {
    func body(session: Session) -> some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    MainView().environment(\.session, Session())
}

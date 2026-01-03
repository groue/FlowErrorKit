import SwiftUI

struct MainView: SignedInView {
    func body(session: Session) -> some View {
        Text(verbatim: "MainView")
    }
}

// MARK: - Preview

#Preview {
    MainView().environment(\.session, Session())
}

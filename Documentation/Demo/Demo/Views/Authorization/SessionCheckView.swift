import SwiftUI

/// A SwiftUI view whose content depends on the presence of a session in
/// the SwiftUI environment.
struct SessionCheckView<SignedInContent: View, SignedOutContent: View>: View {
    @Environment(\.session) var session
    let signedInContent: (Session) -> SignedInContent
    let signedOutContent: () -> SignedOutContent
    
    init(
        @ViewBuilder signedInContent: @escaping (Session) -> SignedInContent,
        @ViewBuilder signedOutContent: @escaping () -> SignedOutContent = { DefaultSignedOutContent() }
    ) {
        self.signedInContent = signedInContent
        self.signedOutContent = signedOutContent
    }
    
    var body: some View {
        if let session {
            signedInContent(session)
        } else {
            signedOutContent()
        }
    }
}

/// The default content of `SessionCheckView` when there is no session in
/// the SwiftUI environment.
struct DefaultSignedOutContent: View {
    var body: some View {
        ContentUnavailableView {
            Label {
                Text(verbatim: "Not Connected")
            } icon: {
                Image(systemName: "lock")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TabView {
        Tab {
            SessionCheckView { session in
                Text(verbatim: "Hello world!")
            }.environment(\.session, Session())
        } label: {
            Label {
                Text(verbatim: "Signed In")
            } icon: {
                Image(systemName: "lock.open")
            }
        }

        Tab {
            SessionCheckView { session in
                Text(verbatim: "Hello world!")
            }
        } label: {
            Label {
                Text(verbatim: "Signed Out")
            } icon: {
                Image(systemName: "lock")
            }
        }
    }
}

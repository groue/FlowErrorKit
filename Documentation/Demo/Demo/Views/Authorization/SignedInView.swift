import SwiftUI

/// A type of SwiftUI view whose content depends on the presence of a
/// session in the SwiftUI environment.
protocol SignedInView: View
where Body == SessionCheckView<SignedInBody, SignedOutBody>
{
    /// The type of view representing the body of this view, when a session
    /// is present in the SwiftUI environment.
    associatedtype SignedInBody: View
    
    /// The type of view representing the body of this view, when no session
    /// is present in the SwiftUI environment.
    associatedtype SignedOutBody: View = DefaultSignedOutContent
    
    /// The content of the view, when a session is present in the
    /// SwiftUI environment.
    @ViewBuilder func body(session: Session) -> SignedInBody
    
    /// The content of the view, when no session is present in the
    /// SwiftUI environment.
    @ViewBuilder var signedOutBody: SignedOutBody { get }
}

extension SignedInView {
    var body: Body {
        SessionCheckView { session in
            body(session: session)
        } signedOutContent: {
            signedOutBody
        }
    }
}

extension SignedInView where SignedOutBody == DefaultSignedOutContent {
    var signedOutBody: DefaultSignedOutContent {
        DefaultSignedOutContent()
    }
}

// MARK: - Preview

#Preview {
    struct PreviewView: SignedInView {
        func body(session: Session) -> some View {
            Text(verbatim: "Hello world!")
        }
    }
    
    return TabView {
        Tab {
            PreviewView().environment(\.session, Session())
        } label: {
            Label {
                Text(verbatim: "Signed In")
            } icon: {
                Image(systemName: "lock.open")
            }
        }

        Tab {
            PreviewView()
        } label: {
            Label {
                Text(verbatim: "Signed Out")
            } icon: {
                Image(systemName: "lock")
            }
        }
    }
}

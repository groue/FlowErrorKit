import SwiftUI

struct SignOutAction {
    let action: () -> Void
    
    func callAsFunction() {
        action()
    }
}

/// SwiftUI environment key for the current session
extension EnvironmentValues {
    @Entry var signOut: SignOutAction = SignOutAction { }
}

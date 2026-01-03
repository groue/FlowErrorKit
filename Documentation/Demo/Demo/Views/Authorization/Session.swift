import SwiftUI

/// A user session
struct Session { }

/// SwiftUI environment key for the current session
extension EnvironmentValues {
    @Entry var session: Session? = nil
}

import FlowErrorKit
import SwiftUI
import Testing

@Suite
struct ErrorActionRoleTests {
    @Test
    func conversion() {
        // A test that won't compile if we introduce a breaking change
        let actionRole = ErrorActionRole.destructive
        let buttonRole = ButtonRole(actionRole)
        #expect(buttonRole == .destructive)
    }
}

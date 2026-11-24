import Foundation
@testable import FlowErrorKit
import SwiftUI
import Testing

@Suite
struct TextSourceTests {
    @Test
    func verbatim_equality() {
        #expect(TextSource.verbatim("Foo") == .verbatim("Foo"))
        #expect(TextSource.verbatim("Foo") != .verbatim("Bar"))
    }

    @Test
    func localizedStringKey_equality() {
        #expect(TextSource.localizedStringKey("Foo") == .localizedStringKey("Foo"))
        #expect(TextSource.localizedStringKey("Foo") != .localizedStringKey("Bar"))
    }

    @Test
    func localizedStringResource_equality() {
        #expect(TextSource.localizedStringResource("Foo") == .localizedStringResource("Foo"))
        #expect(TextSource.localizedStringResource("Foo") != .localizedStringResource("Bar"))
        #expect(TextSource.localizedStringResource(.anErrorOccurred) == .localizedStringResource(.anErrorOccurred))
        #expect(TextSource.localizedStringResource(.ok) != .localizedStringResource(.cancel))
    }

    @Test
    func different_kinds_are_not_equal() {
        #expect(TextSource.verbatim("Foo") != .localizedStringKey("Foo"))
        #expect(TextSource.verbatim("Foo") != .localizedStringResource("Foo"))
        #expect(TextSource.localizedStringKey("Foo") != .localizedStringResource("Foo"))
    }
}

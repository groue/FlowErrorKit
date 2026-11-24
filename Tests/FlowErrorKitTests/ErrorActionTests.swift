import Foundation
@testable import FlowErrorKit
import SwiftUI
import Testing

@Suite
@MainActor
struct ErrorActionTests {
    @Test
    func string_literal_title_is_localized() {
        let action = ErrorAction("Title") { }
        #expect(action.title == .localizedStringKey("Title"))
    }

    @Test
    func interpolated_string_literal_title_is_localized() {
        let count = 3
        let action = ErrorAction("Title \(count)") { }
        #expect(action.title.isLocalizedStringKey)
    }

    @Test
    func string_title_is_not_localized() {
        let title = "Title"
        let action = ErrorAction(title) { }
        #expect(action.title == .verbatim("Title"))
    }

    @Test
    func substring_title_is_not_localized() {
        let title = "Title, etc."
        let action = ErrorAction(title.prefix(5)) { }
        #expect(action.title == .verbatim("Title"))
    }

    @Test
    func localized_string_resource_title() {
        let title: LocalizedStringResource = "Title"
        let action = ErrorAction(title) { }
        #expect(action.title == .localizedStringResource("Title"))
    }

    @Test
    func verbatim_title() {
        let action = ErrorAction(verbatim: "Title") { }
        #expect(action.title == .verbatim("Title"))
    }

    @Test
    func role() {
        #expect(ErrorAction("Title") { }.role == nil)
        #expect(ErrorAction("Title", role: .destructive) { }.role == .destructive)
    }

    @Test
    func role_with_all_title_kinds() {
        let string: String = "Title"
        let resource: LocalizedStringResource = "Title"
        #expect(ErrorAction(string, role: .destructive) { }.role == .destructive)
        #expect(ErrorAction(string[...], role: .destructive) { }.role == .destructive)
        #expect(ErrorAction(resource, role: .destructive) { }.role == .destructive)
        #expect(ErrorAction(verbatim: "Title", role: .destructive) { }.role == .destructive)
    }
}

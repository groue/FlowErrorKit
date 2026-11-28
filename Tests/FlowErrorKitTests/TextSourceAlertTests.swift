#if canImport(AppKit)
import AppKit
@testable import FlowErrorKit
import Observation
import SwiftUI
import Testing

@Suite
@MainActor
struct TextSourceAlertTests {
    struct Item: Identifiable {
        var id: Int
    }

    @Observable
    final class Model {
        var title: TextSource? = .localizedStringKey("Localized")
        var item: Item?
        var appearCount = 0
    }

    struct TestView: View {
        @Bindable var model: Model

        var body: some View {
            Color.clear
                .onAppear { model.appearCount += 1 }
                .alert(
                    model.title,
                    item: $model.item,
                    actions: { _ in Button("OK") { } },
                    message: { _ in EmptyView() })
        }
    }

    private func flush(_ view: NSView) {
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        view.layoutSubtreeIfNeeded()
    }

    // GIVEN a view with a TextSource alert,
    // WHEN the kind of the alert title changes,
    // THEN the wrapped view is not recreated.
    @Test
    func changing_title_kind_preserves_wrapped_view_identity() {
        let model = Model()
        let hostingView = NSHostingView(rootView: TestView(model: model))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        defer { window.close() }

        flush(hostingView)
        #expect(model.appearCount == 1)

        model.title = .verbatim("")
        flush(hostingView)
        #expect(model.appearCount == 1)

        model.title = .localizedStringResource("Localized")
        flush(hostingView)
        #expect(model.appearCount == 1)

        model.title = nil
        flush(hostingView)
        #expect(model.appearCount == 1)
    }
}
#endif

#if canImport(AppKit)
import AppKit
import FlowErrorKit
import Observation
import SwiftUI
import Testing

/// Tests for the `alert` presenter.
///
/// The alert is an `NSAlert` sheet attached to the window of the
/// presenting view. The tests wait with `Task.sleep`, not
/// `RunLoop.run(until:)`, so that the main actor can present the alert
/// after the presentation delay.
@Suite(.serialized)
@MainActor
struct AlertPresenterTests {
    struct PresentedError: Error { }
    struct CancelledError: Error { }

    @MainActor @Observable
    final class Model {
        var flowError: FlowError?
        var isShown = true
        /// The ids of the flow errors handled by the error handlers.
        var handledIDs: [FlowError.ID] = []
        var log: [String] = []

        /// Returns a flow error titled "Alert \(name)", which logs its
        /// cancel action. Button titles are verbatim, so that tests do
        /// not depend on the locale.
        func makeFlowError(_ name: String, error: any Error = PresentedError()) -> FlowError {
            FlowError(error: error)
                .withTitle("Alert \(name)" as String)
                .onCancel(verbatim: "Cancel") { self.log.append("\(name) \($0)") }
        }
    }

    struct HostView: View {
        @Bindable var model: Model

        var body: some View {
            Group {
                if model.isShown {
                    Color.clear.presentError($model.flowError, with: .alert)
                }
            }
            .handleError { flowError in
                model.handledIDs.append(flowError.id)
                return .pass(flowError)
            }
            .handleError(ofType: CancelledError.self) { _, _ in .cancel }
        }
    }

    private func host(_ view: some View) -> (NSWindow, NSView) {
        let hostingView = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        return (window, hostingView)
    }

    /// Lets SwiftUI update the view, and lets tasks run on the main actor.
    private func flush(_ view: NSView, for duration: Duration = .milliseconds(50)) async {
        view.layoutSubtreeIfNeeded()
        try? await Task.sleep(for: duration)
        view.layoutSubtreeIfNeeded()
    }

    /// Lets the alert be presented, after the presentation delay.
    private func flushPresentation(_ view: NSView) async {
        await flush(view, for: .milliseconds(300))
    }

    /// Waits until an alert with the given text is presented.
    private func waitForAlert(_ text: String, in window: NSWindow, _ view: NSView) async {
        await flushPresentation(view)
        for _ in 0..<40 where alertTexts(window)?.contains(text) != true {
            await flush(view)
        }
    }

    /// The texts of the alert presented in the window, or nil if there
    /// is no alert.
    private func alertTexts(_ window: NSWindow) -> [String]? {
        guard let root = alertRootView(window) else { return nil }
        return subviews(of: NSTextField.self, in: root).map(\.stringValue)
    }

    /// Taps a button of the alert presented in the window.
    private func tapAlertButton(_ title: String, in window: NSWindow) throws {
        let root = try #require(alertRootView(window))
        let button = try #require(subviews(of: NSButton.self, in: root).first { $0.title == title })
        button.performClick(nil)
    }

    private func alertRootView(_ window: NSWindow) -> NSView? {
        guard let contentView = window.attachedSheet?.contentView else { return nil }
        return contentView.superview ?? contentView
    }

    private func subviews<V: NSView>(of type: V.Type, in view: NSView) -> [V] {
        ((view as? V).map { [$0] } ?? []) + view.subviews.flatMap { subviews(of: type, in: $0) }
    }

    // MARK: - Presentation

    // GIVEN a view that presents flow errors with an alert,
    // WHEN a flow error is set,
    // THEN the error handlers handle it, an alert presents it, and no
    //   action is performed.
    @Test
    func flow_error_is_presented_in_an_alert() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)
        #expect(alertTexts(window) == nil)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await waitForAlert("Alert A", in: window, hostingView)
        #expect(alertTexts(window)?.contains("Alert A") == true)
        #expect(model.handledIDs == [flowErrorA.id])
        #expect(flowErrorA.canPerformAction)
        #expect(model.log.isEmpty)
    }

    // GIVEN a presented flow error,
    // WHEN the binding is set to a flow error with the same identity,
    // THEN the error handlers do not handle it again.
    @Test
    func flow_error_with_same_identity_is_not_handled_again() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await waitForAlert("Alert A", in: window, hostingView)

        model.flowError = flowErrorA.withTitle("Other Title" as String)
        await flushPresentation(hostingView)
        #expect(model.handledIDs == [flowErrorA.id])
        #expect(flowErrorA.canPerformAction)
        #expect(model.log.isEmpty)
    }

    // GIVEN no presented flow error,
    // WHEN a flow error is set, and a handler cancels its presentation,
    // THEN no alert is presented, the cancel action of the flow error is
    //   run, and the binding is set back to nil.
    @Test
    func cancelled_flow_error_without_presented_flow_error() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        model.flowError = model.makeFlowError("C", error: CancelledError())
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(model.flowError == nil)
        #expect(model.log == ["C presentationCancelled"])
    }

    // MARK: - New flow error while another one is presented

    // GIVEN a flow error about to be presented with an alert,
    // WHEN a new flow error is set before the alert is presented,
    // THEN the first flow error is presented, and the new flow error is
    //   handled and discarded.
    @Test
    func new_flow_error_while_alert_is_pending() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await flush(hostingView, for: .milliseconds(10)) // Less than the presentation delay
        let flowErrorB = model.makeFlowError("B")
        model.flowError = flowErrorB
        await waitForAlert("Alert A", in: window, hostingView)
        #expect(alertTexts(window)?.contains("Alert A") == true)
        #expect(model.handledIDs == [flowErrorA.id, flowErrorB.id])
        #expect(flowErrorA.canPerformAction)
        #expect(model.log == ["B presentationCancelled"])
    }

    // GIVEN a presented flow error,
    // WHEN a new flow error is set,
    // THEN the presented flow error remains presented, and the new flow
    //   error is handled and discarded.
    @Test
    func new_flow_error_while_alert_is_presented() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await waitForAlert("Alert A", in: window, hostingView)

        let flowErrorB = model.makeFlowError("B")
        model.flowError = flowErrorB
        await flushPresentation(hostingView)
        #expect(alertTexts(window)?.contains("Alert A") == true)
        #expect(model.handledIDs == [flowErrorA.id, flowErrorB.id])
        #expect(flowErrorA.canPerformAction)
        #expect(model.log == ["B presentationCancelled"])
    }

    // GIVEN a presented flow error,
    // WHEN a new flow error is set, and a handler cancels its
    //   presentation,
    // THEN the presented flow error remains presented, and the cancel
    //   action of the new flow error is run.
    @Test
    func cancelled_flow_error_while_alert_is_presented() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await waitForAlert("Alert A", in: window, hostingView)

        model.flowError = model.makeFlowError("C", error: CancelledError())
        await flushPresentation(hostingView)
        #expect(alertTexts(window)?.contains("Alert A") == true)
        #expect(flowErrorA.canPerformAction)
        #expect(model.log == ["C presentationCancelled"])
    }

    // MARK: - Programmatic dismissal

    // GIVEN a flow error about to be presented with an alert,
    // WHEN the binding is set to nil before the alert is presented,
    // THEN no alert is presented, and no action is performed.
    @Test
    func programmatic_dismissal_of_pending_alert_performs_no_action() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await flush(hostingView, for: .milliseconds(10)) // Less than the presentation delay
        model.flowError = nil
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(flowErrorA.canPerformAction)
        #expect(model.log.isEmpty)
    }

    // GIVEN a presented flow error,
    // WHEN the binding is set to nil,
    // THEN the alert is dismissed, and no action is performed.
    @Test
    func programmatic_dismissal_of_presented_alert_performs_no_action() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await waitForAlert("Alert A", in: window, hostingView)
        model.flowError = nil
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(flowErrorA.canPerformAction)
        #expect(model.log.isEmpty)
    }

    // GIVEN a flow error about to be presented with an alert,
    // WHEN the binding is set to nil, and then to another flow error,
    //   before the first alert is presented,
    // THEN the other flow error is presented.
    @Test
    func new_flow_error_after_programmatic_dismissal_of_pending_alert() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        model.flowError = model.makeFlowError("A")
        await flush(hostingView, for: .milliseconds(10)) // Less than the presentation delay
        model.flowError = nil
        await flush(hostingView, for: .milliseconds(10))
        let flowErrorB = model.makeFlowError("B")
        model.flowError = flowErrorB
        await waitForAlert("Alert B", in: window, hostingView)
        #expect(alertTexts(window)?.contains("Alert B") == true)
        #expect(alertTexts(window)?.contains("Alert A") == false)
        #expect(flowErrorB.canPerformAction)
        #expect(model.log.isEmpty)
    }

    // GIVEN a presented flow error, and a new flow error that was not
    //   presented,
    // WHEN the binding is set to nil, and then to another flow error,
    // THEN the other flow error is presented.
    @Test
    func new_flow_error_after_programmatic_dismissal() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        model.flowError = model.makeFlowError("A")
        await waitForAlert("Alert A", in: window, hostingView)
        model.flowError = model.makeFlowError("B")
        await flushPresentation(hostingView)
        model.flowError = nil
        await flushPresentation(hostingView)

        let flowErrorD = model.makeFlowError("D")
        model.flowError = flowErrorD
        await waitForAlert("Alert D", in: window, hostingView)
        #expect(alertTexts(window)?.contains("Alert D") == true)
        #expect(flowErrorD.canPerformAction)
        #expect(model.log == ["B presentationCancelled"])
    }

    // MARK: - User actions

    // GIVEN a presented flow error without any other action,
    // WHEN the user taps the cancel button,
    // THEN the cancel action is performed, the alert is dismissed, and
    //   the binding is set back to nil.
    @Test
    func user_taps_cancel() async throws {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        model.flowError = model.makeFlowError("A")
        await waitForAlert("Alert A", in: window, hostingView)
        try tapAlertButton("Cancel", in: window)
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(model.flowError == nil)
        #expect(model.log == ["A userCancelled"])
    }

    // GIVEN a presented flow error with a retry action,
    // WHEN the user taps the retry button,
    // THEN the retry action is performed, the alert is dismissed, and the
    //   binding is set back to nil.
    @Test
    func user_taps_retry() async throws {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        model.flowError = model.makeFlowError("A")
            .onRetry(verbatim: "Retry") { model.log.append("A retry") }
        await waitForAlert("Alert A", in: window, hostingView)
        try tapAlertButton("Retry", in: window)
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(model.flowError == nil)
        #expect(model.log == ["A retry"])
    }

    // GIVEN a presented flow error with a supplementary action,
    // WHEN the user taps the supplementary action,
    // THEN the cancel action, and then the supplementary action, are
    //   performed, the alert is dismissed, and the binding is set back
    //   to nil.
    @Test
    func user_taps_supplementary_action() async throws {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        model.flowError = model.makeFlowError("A")
            .appendingAction(verbatim: "Delete") { model.log.append("A delete") }
        await waitForAlert("Alert A", in: window, hostingView)
        try tapAlertButton("Delete", in: window)
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(model.flowError == nil)
        #expect(model.log == ["A supplementaryActionPerformed", "A delete"])
    }

    // GIVEN a presented flow error, and a new flow error that was not
    //   presented,
    // WHEN the user taps the cancel button,
    // THEN the cancel action of the presented flow error is performed,
    //   and the binding is set back to nil.
    @Test
    func user_taps_cancel_after_new_flow_error() async throws {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        model.flowError = model.makeFlowError("A")
        await waitForAlert("Alert A", in: window, hostingView)
        model.flowError = model.makeFlowError("B")
        await flushPresentation(hostingView)
        try tapAlertButton("Cancel", in: window)
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(model.flowError == nil)
        #expect(model.log == ["B presentationCancelled", "A userCancelled"])
    }

    // GIVEN a presented flow error with a retry action that sets a new
    //   flow error,
    // WHEN the user taps the retry button,
    // THEN the new flow error is handled and presented.
    @Test
    func action_sets_new_flow_error() async throws {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorC = model.makeFlowError("C")
        model.flowError = model.makeFlowError("A")
            .onRetry(verbatim: "Retry") { model.flowError = flowErrorC }
        await waitForAlert("Alert A", in: window, hostingView)
        try tapAlertButton("Retry", in: window)
        await waitForAlert("Alert C", in: window, hostingView)
        #expect(alertTexts(window)?.contains("Alert C") == true)
        #expect(model.handledIDs.last == flowErrorC.id)
        #expect(flowErrorC.canPerformAction)
        #expect(model.log.isEmpty)
    }

    // MARK: - Disappearance

    // GIVEN a flow error about to be presented with an alert,
    // WHEN the presenting view disappears,
    // THEN the flow error is discarded.
    @Test
    func disappearance_discards_pending_flow_error() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await flush(hostingView, for: .milliseconds(10)) // Less than the presentation delay
        model.isShown = false
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(!flowErrorA.canPerformAction)
        #expect(model.log == ["A presentationCancelled"])
    }

    // GIVEN a flow error about to be presented with an alert, and a new
    //   flow error that was not presented,
    // WHEN the presenting view disappears,
    // THEN the pending flow error is discarded, and the cancel action of
    //   each flow error is run once.
    @Test
    func disappearance_discards_pending_flow_error_after_new_flow_error() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await flush(hostingView, for: .milliseconds(10)) // Less than the presentation delay
        model.flowError = model.makeFlowError("B")
        await flush(hostingView, for: .milliseconds(10))
        model.isShown = false
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(!flowErrorA.canPerformAction)
        #expect(model.log.sorted() == ["A presentationCancelled", "B presentationCancelled"])
    }

    // GIVEN a presented flow error,
    // WHEN the presenting view disappears,
    // THEN the flow error is discarded.
    @Test
    func disappearance_discards_presented_flow_error() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await waitForAlert("Alert A", in: window, hostingView)
        model.isShown = false
        await flushPresentation(hostingView)
        #expect(alertTexts(window) == nil)
        #expect(!flowErrorA.canPerformAction)
        #expect(model.log == ["A presentationCancelled"])
    }

    // GIVEN a presented flow error, and a new flow error that was not
    //   presented,
    // WHEN the presenting view disappears,
    // THEN the presented flow error is discarded, and the cancel action
    //   of each flow error is run once.
    @Test
    func disappearance_discards_each_flow_error_once() async {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        await flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        await waitForAlert("Alert A", in: window, hostingView)
        model.flowError = model.makeFlowError("B")
        await flushPresentation(hostingView)
        model.isShown = false
        await flushPresentation(hostingView)
        #expect(!flowErrorA.canPerformAction)
        #expect(model.log.sorted() == ["A presentationCancelled", "B presentationCancelled"])
    }
}
#endif

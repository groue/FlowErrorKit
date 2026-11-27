#if canImport(AppKit)
import AppKit
import FlowErrorKit
import Observation
import SwiftUI
import Testing

/// Tests for the `errorPresentationView` presenter.
@Suite
@MainActor
struct ErrorPresentationViewPresenterTests {
    struct PresentedError: Error { }
    struct CancelledError: Error { }

    @MainActor @Observable
    final class Model {
        var flowError: FlowError?
        /// The id of the flow error displayed in the error view, or nil
        /// when the view content is displayed.
        var presentedFlowErrorID: FlowError.ID?
        /// How many times the view content has appeared.
        var contentAppearCount = 0
        var cancelLog: [String] = []

        func makeFlowError(_ name: String, error: any Error = PresentedError()) -> FlowError {
            FlowError(error: error)
                .onCancel { self.cancelLog.append("\(name) \($0)") }
        }
    }

    struct HostView: View {
        var model: Model

        var body: some View {
            Color.clear
                .onAppear {
                    model.presentedFlowErrorID = nil
                    model.contentAppearCount += 1
                }
                .presentError(
                    Binding(get: { model.flowError }, set: { model.flowError = $0 }),
                    with: .errorPresentationView { errorPresentation in
                        Color.clear.onChange(of: errorPresentation.flowError.id, initial: true) {
                            model.presentedFlowErrorID = errorPresentation.flowError.id
                        }
                    })
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

    private func flush(_ view: NSView) {
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        view.layoutSubtreeIfNeeded()
    }

    // GIVEN a view that presents flow errors with an error view,
    // WHEN a flow error is set,
    // THEN the error view replaces the view content, and no action is
    //   performed.
    @Test
    func flow_error_is_presented_in_place_of_content() {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        flush(hostingView)
        #expect(model.presentedFlowErrorID == nil)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        flush(hostingView)
        #expect(model.presentedFlowErrorID == flowErrorA.id)
        #expect(model.flowError?.id == flowErrorA.id)
        #expect(model.cancelLog.isEmpty)
    }

    // GIVEN a presented flow error,
    // WHEN a new flow error is set,
    // THEN the new flow error replaces the previous one, and the cancel
    //   action of the previous one is run.
    @Test
    func new_flow_error_replaces_presented_flow_error() {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        flush(hostingView)

        model.flowError = model.makeFlowError("A")
        flush(hostingView)

        let flowErrorB = model.makeFlowError("B")
        model.flowError = flowErrorB
        flush(hostingView)
        #expect(model.presentedFlowErrorID == flowErrorB.id)
        #expect(model.flowError?.id == flowErrorB.id)
        #expect(model.cancelLog == ["A presentationCancelled"])
    }

    // GIVEN no presented flow error,
    // WHEN a flow error is set, and a handler cancels its presentation,
    // THEN the view content remains displayed, the cancel action of the
    //   flow error is run, and the binding is set back to nil.
    @Test
    func cancelled_flow_error_without_presented_flow_error() {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        flush(hostingView)

        model.flowError = model.makeFlowError("C", error: CancelledError())
        flush(hostingView)
        #expect(model.presentedFlowErrorID == nil)
        #expect(model.flowError == nil)
        #expect(model.contentAppearCount == 1)
        #expect(model.cancelLog == ["C presentationCancelled"])
    }

    // GIVEN a presented flow error,
    // WHEN a new flow error is set, and a handler cancels its
    //   presentation,
    // THEN the previous flow error remains presented, and the cancel
    //   action of the new flow error is run. The binding contains the
    //   new flow error.
    @Test
    func cancelled_flow_error_with_presented_flow_error() {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        flush(hostingView)

        let flowErrorA = model.makeFlowError("A")
        model.flowError = flowErrorA
        flush(hostingView)

        let flowErrorC = model.makeFlowError("C", error: CancelledError())
        model.flowError = flowErrorC
        flush(hostingView)
        #expect(model.presentedFlowErrorID == flowErrorA.id)
        #expect(model.flowError?.id == flowErrorC.id)
        #expect(flowErrorA.canPerformAction)
        #expect(model.cancelLog == ["C presentationCancelled"])
    }

    // GIVEN a presented flow error,
    // WHEN the flow error is set to nil,
    // THEN the view content is created again: its onAppear modifier
    //   runs again.
    @Test
    func content_is_created_again_after_dismissal() {
        let model = Model()
        let (window, hostingView) = host(HostView(model: model))
        defer { window.close() }
        flush(hostingView)
        #expect(model.contentAppearCount == 1)

        model.flowError = model.makeFlowError("A")
        flush(hostingView)
        model.flowError = nil
        flush(hostingView)
        #expect(model.presentedFlowErrorID == nil)
        #expect(model.contentAppearCount == 2)
        #expect(model.cancelLog.isEmpty)
    }
}
#endif

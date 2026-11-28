#if canImport(AppKit)
import AppKit
import FlowErrorKit
import Observation
import SwiftUI
import Testing

@Suite
@MainActor
struct ProgrammaticDismissalTests {
    struct TestError: Error { }

    @MainActor @Observable
    final class Model {
        var flowError: FlowError?
        var presentedFlowErrorID: FlowError.ID?
        var cancelReasons: [ErrorCancelReason] = []

        var cancelLog: [String] = []
        
        func makeFlowError() -> FlowError {
            FlowError(error: TestError())
                .onCancel { self.cancelReasons.append($0) }
        }
        
        func makeFlowError(name: String) -> FlowError {
            FlowError(error: TestError())
                .onCancel { self.cancelLog.append("\(name) \($0)") }
        }
    }

    struct AlertView: View {
        @Bindable var model: Model
        
        var body: some View {
            Color.clear.presentError(
                $model.flowError,
                with: .alert)
        }
    }
    
    struct ErrorPresentationHostView: View {
        @Bindable var model: Model

        var body: some View {
            Color.clear
                .onAppear { model.presentedFlowErrorID = nil }
                .presentError(
                    $model.flowError,
                    with: .errorPresentationView { errorPresentation in
                        Color.clear.onAppear {
                            model.presentedFlowErrorID = errorPresentation.flowError.id
                        }
                    })
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

    private func flush(_ view: NSView, for duration: TimeInterval = 0.05) {
        view.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: duration))
        view.layoutSubtreeIfNeeded()
    }

    // GIVEN a flow error presented with an error presentation view,
    // WHEN the flow error is set to nil,
    // THEN the presenting view is restored, and no action is performed.
    @Test
    func errorPresentation_programmatic_dismissal_performs_no_action() {
        let model = Model()
        let (window, hostingView) = host(ErrorPresentationHostView(model: model))
        defer { window.close() }
        flush(hostingView)

        let flowError = model.makeFlowError()
        model.flowError = flowError
        flush(hostingView)
        #expect(model.presentedFlowErrorID == flowError.id)
        #expect(model.cancelReasons.isEmpty)

        model.flowError = nil
        flush(hostingView)
        #expect(model.presentedFlowErrorID == nil)
        #expect(model.cancelReasons.isEmpty)
    }
    
    // GIVEN a flow error about to be presented with an alert,
    // WHEN another flow error is set before the alert is presented,
    // THEN the new flow error is not presented, and its cancel action
    //   is run, as when the first alert is already presented.
    @Test
    func alert_new_flow_error_while_alert_is_pending() {
        let model = Model()
        let (window, hostingView) = host(AlertView(model: model))
        defer { window.close() }
        flush(hostingView)
        
        model.flowError = model.makeFlowError(name: "A")
        flush(hostingView, for: 0.01) // Less than the presentation delay
        model.flowError = model.makeFlowError(name: "B")
        flush(hostingView, for: 0.3)
        #expect(model.cancelLog == ["B presentationCancelled"])
    }
}
#endif

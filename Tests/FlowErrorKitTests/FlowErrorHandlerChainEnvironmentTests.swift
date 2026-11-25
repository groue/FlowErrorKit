#if canImport(AppKit)
import AppKit
@testable import FlowErrorKit
import Foundation
import SwiftUI
import Testing

@MainActor @Suite
struct FlowErrorHandlerChainEnvironmentTests {
    @MainActor final class Box {
        var errorHandler: FlowErrorHandlerChain?
    }

    /// Captures the chain of handlers in the environment.
    struct CaptureView: View {
        var box: Box
        @Environment(\.errorHandler) private var errorHandler

        var body: some View {
            Color.clear.onAppear { box.errorHandler = errorHandler }
        }
    }

    /// Presents URLError with a recognizable system image.
    struct CustomURLErrorHandler: FlowErrorHandler {
        static let systemImage = "custom.url.error"

        func handle(_ flowError: FlowError) -> FlowErrorHandling {
            guard flowError.error is URLError else {
                return .pass(flowError)
            }
            return .present(ErrorPresentation(
                flowError: flowError,
                systemImage: Self.systemImage))
        }
    }

    /// A handler that does not handle anything.
    struct PassingHandler: FlowErrorHandler {
        func handle(_ flowError: FlowError) -> FlowErrorHandling {
            .pass(flowError)
        }
    }

    /// Returns the chain of handlers in the environment of the
    /// `CaptureView` wrapped by `makeView`.
    private func environmentChain(_ makeView: (CaptureView) -> some View) -> FlowErrorHandlerChain? {
        let box = Box()
        let hostingView = NSHostingView(rootView: makeView(CaptureView(box: box)))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        defer { window.close() }
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        return box.errorHandler
    }

    // GIVEN a chain registered in a view,
    // WHEN an error is not handled by any registered handler,
    // THEN the default handlers handle it.
    @Test
    func environment_ends_with_default_handlers() throws {
        let errorHandler = try #require(environmentChain {
            $0.handleError(with: FlowErrorHandlerChain([PassingHandler()]))
        })
        let handling = errorHandler.handle(FlowError(error: URLError(.cancelled)))
        guard case .cancel = handling else {
            Issue.record("Expected .cancel from the default handlers")
            return
        }
    }

    // GIVEN a chain registered in a view, below a handler that customizes
    //   URLError,
    // WHEN a URLError is handled,
    // THEN the outer handler presents it: the default handlers do not
    //   preempt it.
    @Test
    func registered_chain_does_not_preempt_outer_handlers() throws {
        let errorHandler = try #require(environmentChain {
            $0
                .handleError(with: FlowErrorHandlerChain([PassingHandler()]))
                .handleError(with: FlowErrorHandlerChain([CustomURLErrorHandler()]))
        })
        let handling = errorHandler.handle(FlowError(error: URLError(.notConnectedToInternet)))
        guard case let .present(presentation) = handling else {
            Issue.record("Expected .present")
            return
        }
        #expect(presentation.systemImage == CustomURLErrorHandler.systemImage)
    }
}
#endif

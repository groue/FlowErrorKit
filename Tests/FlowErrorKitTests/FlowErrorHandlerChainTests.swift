@testable import FlowErrorKit
import Foundation
import Testing

@MainActor @Suite
struct FlowErrorHandlerChainTests {
    struct TestError: Error { }
    struct OtherError: Error { }

    @MainActor final class Log {
        var entries: [String] = []
    }

    /// A handler that logs its name and the error it sees, and returns
    /// the provided handling.
    struct LoggingHandler: FlowErrorHandler {
        var name: String
        var log: Log
        var handling: (FlowError) -> FlowErrorHandling

        func handle(_ flowError: FlowError) -> FlowErrorHandling {
            log.entries.append("\(name) \(type(of: flowError.error))")
            return handling(flowError)
        }
    }

    @Test
    func empty_chain_passes() {
        let handling = FlowErrorHandlerChain().handle(FlowError(error: TestError()))
        guard case let .pass(flowError) = handling else {
            Issue.record("Expected .pass")
            return
        }
        #expect(flowError.error is TestError)
    }

    @Test
    func handlers_are_invoked_in_order() {
        let log = Log()
        let chain = FlowErrorHandlerChain([
            LoggingHandler(name: "A", log: log) { .pass($0) },
            LoggingHandler(name: "B", log: log) { .pass($0) },
        ])
        _ = chain.handle(FlowError(error: TestError()))
        #expect(log.entries == ["A TestError", "B TestError"])
    }

    @Test
    func pass_forwards_the_modified_flow_error() {
        let log = Log()
        let chain = FlowErrorHandlerChain([
            LoggingHandler(name: "A", log: log) { .pass($0.withError(OtherError())) },
            LoggingHandler(name: "B", log: log) { .pass($0) },
        ])
        let handling = chain.handle(FlowError(error: TestError()))
        #expect(log.entries == ["A TestError", "B OtherError"])
        guard case let .pass(flowError) = handling else {
            Issue.record("Expected .pass")
            return
        }
        #expect(flowError.error is OtherError)
    }

    @Test
    func present_stops_the_chain() {
        let log = Log()
        let chain = FlowErrorHandlerChain([
            LoggingHandler(name: "A", log: log) { .present(ErrorPresentation(flowError: $0)) },
            LoggingHandler(name: "B", log: log) { .pass($0) },
        ])
        let handling = chain.handle(FlowError(error: TestError()))
        #expect(log.entries == ["A TestError"])
        guard case .present = handling else {
            Issue.record("Expected .present")
            return
        }
    }

    @Test
    func cancel_stops_the_chain() {
        let log = Log()
        let chain = FlowErrorHandlerChain([
            LoggingHandler(name: "A", log: log) { _ in .cancel },
            LoggingHandler(name: "B", log: log) { .pass($0) },
        ])
        let handling = chain.handle(FlowError(error: TestError()))
        #expect(log.entries == ["A TestError"])
        guard case .cancel = handling else {
            Issue.record("Expected .cancel")
            return
        }
    }

    @Test
    func prepending_invokes_new_handlers_first() {
        let log = Log()
        let chain = FlowErrorHandlerChain([
            LoggingHandler(name: "C", log: log) { .pass($0) },
        ])
        .prepending([
            LoggingHandler(name: "A", log: log) { .pass($0) },
            LoggingHandler(name: "B", log: log) { .pass($0) },
        ])
        _ = chain.handle(FlowError(error: TestError()))
        #expect(log.entries == ["A TestError", "B TestError", "C TestError"])
    }
}

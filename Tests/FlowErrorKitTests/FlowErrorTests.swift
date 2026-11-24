@testable import FlowErrorKit
import SwiftUI
import Testing

@MainActor @Suite
struct FlowErrorTests {
    struct TestError: Error { }
    
    @Test
    func initializer() {
        // A test that won't compile if we introduce a breaking change
        _ = FlowError(error: TestError())
        _ = FlowError(error: TestError(), allowMultipleActionExecutions: true)
    }
    
    @Test
    func errorProperty() {
        var flowError = FlowError(error: TestError())
        #expect(flowError.error is TestError)
        
        flowError = flowError.withError(CancellationError())
        #expect(flowError.error is CancellationError)
    }
    
    @Test
    func cancelTitleProperty() {
        var flowError = FlowError(error: TestError())
        #expect(flowError.cancelTitle == nil, "No cancel title by default")
        
        flowError = flowError.onCancel { _ in }
        #expect(flowError.cancelTitle == nil, "An untitled cancel action does not change the cancel title")
        
        flowError = flowError.onCancel(verbatim: "Title 1") { _ in }
        #expect(flowError.cancelTitle == .verbatim("Title 1"), "A titled cancel action changes the cancel title")
        
        flowError = flowError.onCancel { _ in }
        #expect(flowError.cancelTitle == .verbatim("Title 1"), "An untitled cancel action does not change the cancel title")
        
        flowError = flowError.onCancel(verbatim: "Title 2") { _ in }
        #expect(flowError.cancelTitle == .verbatim("Title 2"), "A titled cancel action changes the cancel title")
    }
    
    @Test
    func titleProperty() {
        var flowError = FlowError(error: TestError())
        #expect(flowError.title == nil, "No title by default")

        flowError = flowError.withTitle("Title 1")
        #expect(flowError.title == .localizedStringKey("Title 1"), "A string literal is localized")

        let title: String = "Title 2"
        flowError = flowError.withTitle(title)
        #expect(flowError.title == .verbatim("Title 2"), "A string is not localized")

        flowError = flowError.withTitle(verbatim: "Title 3")
        #expect(flowError.title == .verbatim("Title 3"))

        let resource = LocalizedStringResource("Title 4")
        flowError = flowError.withTitle(resource)
        #expect(flowError.title == .localizedStringResource(resource))

        let substring = "Title 5, etc."
        flowError = flowError.withTitle(substring.prefix(7))
        #expect(flowError.title == .verbatim("Title 5"), "A substring is not localized")

        let count = 6
        flowError = flowError.withTitle("Title \(count)")
        #expect(flowError.title?.isLocalizedStringKey == true, "An interpolated string literal is localized")
    }

    @Test
    func cancelTitle_overloads() {
        let flowError = FlowError(error: TestError())

        #expect(flowError.onCancel("Title") { _ in }.cancelTitle
            == .localizedStringKey("Title"), "A string literal is localized")

        let count = 1
        #expect(flowError.onCancel("Title \(count)") { _ in }.cancelTitle?.isLocalizedStringKey
            == true, "An interpolated string literal is localized")

        let string: String = "Title"
        #expect(flowError.onCancel(string) { _ in }.cancelTitle
            == .verbatim("Title"), "A string is not localized")

        let substring = "Title, etc."
        #expect(flowError.onCancel(substring.prefix(5)) { _ in }.cancelTitle
            == .verbatim("Title"), "A substring is not localized")

        let resource = LocalizedStringResource("Title")
        #expect(flowError.onCancel(resource) { _ in }.cancelTitle
            == .localizedStringResource(resource))

        #expect(flowError.onCancel(verbatim: "Title") { _ in }.cancelTitle
            == .verbatim("Title"))
    }

    @Test
    func cancelTitle_kind_can_be_replaced() {
        let resource = LocalizedStringResource("Title 3")
        var flowError = FlowError(error: TestError())

        flowError = flowError.onCancel("Title 1") { _ in }
        #expect(flowError.cancelTitle == .localizedStringKey("Title 1"))

        flowError = flowError.onCancel(verbatim: "Title 2") { _ in }
        #expect(flowError.cancelTitle == .verbatim("Title 2"))

        flowError = flowError.onCancel(resource) { _ in }
        #expect(flowError.cancelTitle == .localizedStringResource(resource))

        flowError = flowError.onCancel { _ in }
        #expect(flowError.cancelTitle == .localizedStringResource(resource))
    }

    @Test
    func retryActionProperty() {
        var flowError = FlowError(error: TestError())
        #expect(flowError.retryAction == nil, "No retry action by default")
        
        flowError = flowError.onRetry { }
        #expect(flowError.retryAction != nil)
        
        flowError = flowError.onRetry(verbatim: "Title 1") { }
        #expect(flowError.retryAction?.title == .verbatim("Title 1"), "A titled retry action changes the retry title")
        
        flowError = flowError.onRetry { }
        #expect(flowError.retryAction?.title == .verbatim("Title 1"), "An untitled retry action does not change the retry title")
        
        flowError = flowError.onRetry(verbatim: "Title 2") { }
        #expect(flowError.retryAction?.title == .verbatim("Title 2"), "A titled retry action changes the retry title")
    }

    @Test
    func retryAction_default_title() {
        let flowError = FlowError(error: TestError()).onRetry { }
        #expect(flowError.retryAction?.title == .localizedStringResource(.retry))
    }

    @Test
    func retryAction_title_overloads() {
        let flowError = FlowError(error: TestError())

        #expect(flowError.onRetry("Title") { }.retryAction?.title
            == .localizedStringKey("Title"), "A string literal is localized")

        let count = 1
        #expect(flowError.onRetry("Title \(count)") { }.retryAction?.title.isLocalizedStringKey
            == true, "An interpolated string literal is localized")

        let string: String = "Title"
        #expect(flowError.onRetry(string) { }.retryAction?.title
            == .verbatim("Title"), "A string is not localized")

        let substring = "Title, etc."
        #expect(flowError.onRetry(substring.prefix(5)) { }.retryAction?.title
            == .verbatim("Title"), "A substring is not localized")

        let resource = LocalizedStringResource("Title")
        #expect(flowError.onRetry(resource) { }.retryAction?.title
            == .localizedStringResource(resource))

        #expect(flowError.onRetry(verbatim: "Title") { }.retryAction?.title
            == .verbatim("Title"))
    }

    @Test
    func retryAction_title_kind_can_be_replaced() {
        let resource = LocalizedStringResource("Title 3")
        var flowError = FlowError(error: TestError())

        flowError = flowError.onRetry("Title 1") { }
        #expect(flowError.retryAction?.title == .localizedStringKey("Title 1"))

        flowError = flowError.onRetry(verbatim: "Title 2") { }
        #expect(flowError.retryAction?.title == .verbatim("Title 2"))

        flowError = flowError.onRetry(resource) { }
        #expect(flowError.retryAction?.title == .localizedStringResource(resource))

        flowError = flowError.onRetry { }
        #expect(flowError.retryAction?.title == .localizedStringResource(resource))
    }
    
    @Test
    func supplementaryActionsProperty() {
        var flowError = FlowError(error: TestError())
        #expect(flowError.supplementaryActions.isEmpty, "No supplementary action by default")
        
        flowError = flowError.appendingAction(ErrorAction(verbatim: "Title 1", action: { }))
        #expect(flowError.supplementaryActions.count == 1)
        #expect(flowError.supplementaryActions.last?.role == nil)
        #expect(flowError.supplementaryActions.last?.title == .verbatim("Title 1"))
        
        flowError = flowError.appendingAction(verbatim: "Title 2", action: { })
        #expect(flowError.supplementaryActions.count == 2)
        #expect(flowError.supplementaryActions.last?.role == nil)
        #expect(flowError.supplementaryActions.last?.title == .verbatim("Title 2"))
        
        flowError = flowError.appendingAction(verbatim: "Title 3", role: .destructive, action: { })
        #expect(flowError.supplementaryActions.count == 3)
        #expect(flowError.supplementaryActions.last?.role == .destructive)
        #expect(flowError.supplementaryActions.last?.title == .verbatim("Title 3"))
    }

    @Test
    func appendingAction_title_overloads() {
        let flowError = FlowError(error: TestError())

        #expect(flowError.appendingAction("Title") { }.supplementaryActions.last?.title
            == .localizedStringKey("Title"), "A string literal is localized")

        let count = 1
        #expect(flowError.appendingAction("Title \(count)") { }.supplementaryActions.last?.title.isLocalizedStringKey
            == true, "An interpolated string literal is localized")

        let string: String = "Title"
        #expect(flowError.appendingAction(string) { }.supplementaryActions.last?.title
            == .verbatim("Title"), "A string is not localized")

        let substring = "Title, etc."
        #expect(flowError.appendingAction(substring.prefix(5)) { }.supplementaryActions.last?.title
            == .verbatim("Title"), "A substring is not localized")

        let resource = LocalizedStringResource("Title")
        #expect(flowError.appendingAction(resource) { }.supplementaryActions.last?.title
            == .localizedStringResource(resource))

        #expect(flowError.appendingAction(verbatim: "Title") { }.supplementaryActions.last?.title
            == .verbatim("Title"))
    }

    @Test
    func appendingAction_role_overloads() {
        let flowError = FlowError(error: TestError())
        let string: String = "Title"
        let resource = LocalizedStringResource("Title")

        #expect(flowError.appendingAction("Title") { }.supplementaryActions.last?.role == nil)
        #expect(flowError.appendingAction(string) { }.supplementaryActions.last?.role == nil)
        #expect(flowError.appendingAction(resource) { }.supplementaryActions.last?.role == nil)
        #expect(flowError.appendingAction(verbatim: "Title") { }.supplementaryActions.last?.role == nil)

        #expect(flowError.appendingAction("Title", role: .destructive) { }.supplementaryActions.last?.role == .destructive)
        #expect(flowError.appendingAction(string, role: .destructive) { }.supplementaryActions.last?.role == .destructive)
        #expect(flowError.appendingAction(string[...], role: .destructive) { }.supplementaryActions.last?.role == .destructive)
        #expect(flowError.appendingAction(resource, role: .destructive) { }.supplementaryActions.last?.role == .destructive)
        #expect(flowError.appendingAction(verbatim: "Title", role: .destructive) { }.supplementaryActions.last?.role == .destructive)
    }
    
    @Test
    func flowErrorIdentity() {
        let flowError1 = FlowError(error: TestError())
        let flowError2 = flowError1
            .onCancel { _ in }
            .onRetry { }
            .droppingRetryAction()
            .onRetry { }
            .appendingAction(verbatim: "Title") { }
            .finally { }
            .withError(CancellationError())
            .withTitle(verbatim: "Title")
        let flowError3 = FlowError(error: TestError())
        
        #expect(flowError1.id == flowError2.id)
        #expect(flowError1.id != flowError3.id)
    }
    
    @Test
    func droppingRetryAction() throws {
        do {
            let flowError = FlowError(error: TestError())
                .onRetry { }
                .droppingRetryAction()
            #expect(flowError.retryAction == nil)
        }
        do {
            var executions: [String] = []
            let flowError = FlowError(error: TestError())
                .onRetry { executions.append("retry 1") }
                .droppingRetryAction()
                .onRetry { executions.append("retry 2") }
            let retryAction = try #require(flowError.retryAction)
            flowError.performAction(retryAction)
            #expect(executions == [
                "retry 2",
            ])
        }
    }
    
    @Test
    func perform_cancel_action() {
        var executions: [String] = []
        let flowError = FlowError(error: TestError())
            .finally { executions.append("finally 1") }
            .onCancel { executions.append("cancel 1 \($0)") }
            .onCancel { executions.append("cancel 2 \($0)") }
            .finally { executions.append("finally 2") }
            .onRetry { executions.append("retry") }
        flowError.performCancelAction()
        #expect(executions == [
            "cancel 1 userCancelled",
            "cancel 2 userCancelled",
            "finally 1",
            "finally 2",
        ])
    }
    
    @Test
    func discard() {
        var executions: [String] = []
        let flowError = FlowError(error: TestError())
            .finally { executions.append("finally 1") }
            .onCancel { executions.append("cancel 1 \($0)") }
            .onCancel { executions.append("cancel 2 \($0)") }
            .onRetry { executions.append("retry") }
            .finally { executions.append("finally 2") }
        flowError.discard(.presentationCancelled)
        #expect(executions == [
            "cancel 1 presentationCancelled",
            "cancel 2 presentationCancelled",
            "finally 1",
            "finally 2",
        ])
    }
    
    @Test
    func perform_retry_action() throws {
        var executions: [String] = []
        let flowError = FlowError(error: TestError())
            .finally { executions.append("finally 1") }
            .onCancel { executions.append("cancel 1 \($0)") }
            .onRetry { executions.append("retry 1") }
            .finally { executions.append("finally 2") }
            .onRetry { executions.append("retry 2") }
            .onCancel { executions.append("cancel 2 \($0)") }
        let retryAction = try #require(flowError.retryAction)
        flowError.performAction(retryAction)
        #expect(executions == [
            "retry 1",
            "retry 2",
            "finally 1",
            "finally 2",
        ])
    }
    
    @Test
    func perform_supplementary_action() throws {
        var executions: [String] = []
        let action = ErrorAction(verbatim: "Other") { executions.append("other") }
        let flowError = FlowError(error: TestError())
            .finally { executions.append("finally 1") }
            .onCancel { executions.append("cancel 1 \($0)") }
            .onRetry { executions.append("retry 1") }
            .appendingAction(action)
            .finally { executions.append("finally 2") }
            .onRetry { executions.append("retry 2") }
            .onCancel { executions.append("cancel 2 \($0)") }
        flowError.performAction(action)
        #expect(executions == [
            "cancel 1 supplementaryActionPerformed",
            "cancel 2 supplementaryActionPerformed",
            "other",
            "finally 1",
            "finally 2",
        ])
    }
}

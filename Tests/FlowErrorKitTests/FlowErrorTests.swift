import FlowErrorKit
import Foundation
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
    func cancelAction() {
        let en = Locale(identifier: "en")
        let fr = Locale(identifier: "fr")
        
        var flowError = FlowError(error: TestError())
        #expect(flowError.cancelAction == nil)
        
        flowError = flowError.onCancel { _ in }
        #expect(flowError.cancelAction != nil)
        #expect(flowError.cancelAction?.title == nil, "An untitled cancel action does not change the cancel title")
        
        flowError = flowError.onCancel(verbatim: "Title 1") { _ in }
        #expect(flowError.cancelAction?.title?.formatted(.text.locale(en)) == "Title 1", "A titled cancel action changes the cancel title")
        
        flowError = flowError.onCancel { _ in }
        #expect(flowError.cancelAction?.title?.formatted(.text.locale(en)) == "Title 1", "An untitled cancel action does not change the cancel title")
        
        flowError = flowError.onCancel(LocalizedStringResource("Give Up", bundle: .module)) { _ in }
        #expect(flowError.cancelAction?.title?.formatted(.text.locale(en)) == "Give Up", "A titled cancel action changes the cancel title")
        #expect(flowError.cancelAction?.title?.formatted(.text.locale(fr)) == "Laisser tomber", "A titled cancel action changes the cancel title")
    }
    
    @Test
    func failedActionName_property() {
        let en = Locale(identifier: "en")
        let fr = Locale(identifier: "fr")
        
        var flowError = FlowError(error: TestError())
        #expect(flowError.failedActionName == nil)
        
        flowError = flowError.withFailedActionName("Title 1")
        #expect(flowError.failedActionName?.formatted(.text.locale(en)) == "Title 1")
        
        flowError = flowError.withFailedActionName(LocalizedStringResource("Give Up", bundle: .module))
        #expect(flowError.failedActionName?.formatted(.text.locale(en)) == "Give Up")
        #expect(flowError.failedActionName?.formatted(.text.locale(fr)) == "Laisser tomber")
    }
    
    @Test
    func retryActionProperty() {
        let en = Locale(identifier: "en")
        let fr = Locale(identifier: "fr")
        
        var flowError = FlowError(error: TestError())
        #expect(flowError.retryAction == nil, "No retry action by default")
        
        flowError = flowError.onRetry { }
        #expect(flowError.retryAction != nil)
        #expect(flowError.retryAction?.title.formatted(.text.locale(en)) == "Retry", "The default title is Retry")
        #expect(flowError.retryAction?.title.formatted(.text.locale(fr)) == "Réessayer", "The default title is Retry")

        flowError = flowError.onRetry(verbatim: "Title 1") { }
        #expect(flowError.retryAction?.title.formatted(.text.locale(en)) == "Title 1", "A titled retry action changes the retry title")
        
        flowError = flowError.onRetry { }
        #expect(flowError.retryAction?.title.formatted(.text.locale(en)) == "Title 1", "An untitled retry action does not change the retry title")
        
        flowError = flowError.onRetry(LocalizedStringResource("Give Up", bundle: .module)) { }
        #expect(flowError.retryAction?.title.formatted(.text.locale(en)) == "Give Up", "A titled retry action changes the retry title")
        #expect(flowError.retryAction?.title.formatted(.text.locale(fr)) == "Laisser tomber", "A titled retry action changes the retry title")
    }
    
    @Test
    func supplementaryActionsProperty() {
        let en = Locale(identifier: "en")
        let fr = Locale(identifier: "fr")
        
        var flowError = FlowError(error: TestError())
        #expect(flowError.supplementaryActions.isEmpty, "No supplementary action by default")
        
        flowError = flowError.appendingAction(ErrorAction(verbatim: "Title 1", perform: { }))
        #expect(flowError.supplementaryActions.count == 1)
        #expect(flowError.supplementaryActions.last?.role == nil)
        #expect(flowError.supplementaryActions.last?.title.formatted(.text.locale(en)) == "Title 1")
        
        flowError = flowError.appendingAction(verbatim: "Title 2", perform: { })
        #expect(flowError.supplementaryActions.count == 2)
        #expect(flowError.supplementaryActions.last?.role == nil)
        #expect(flowError.supplementaryActions.last?.title.formatted(.text.locale(en)) == "Title 2")
        
        flowError = flowError.appendingAction(LocalizedStringResource("Give Up", bundle: .module), role: .destructive, perform: { })
        #expect(flowError.supplementaryActions.count == 3)
        #expect(flowError.supplementaryActions.last?.role == .destructive)
        #expect(flowError.supplementaryActions.last?.title.formatted(.text.locale(en)) == "Give Up")
        #expect(flowError.supplementaryActions.last?.title.formatted(.text.locale(fr)) == "Laisser tomber")
    }
    
    @Test
    func isSameErrorAs() {
        let flowError1 = FlowError(error: TestError())
        let flowError2 = flowError1
            .onCancel { _ in }
            .onRetry { }
            .droppingRetryAction()
            .onRetry { }
            .appendingAction("Title") { }
            .finally { }
            .withError(CancellationError())
            .withFailedActionName("Title")
        let flowError3 = FlowError(error: TestError())
        
        #expect(flowError1.isSameError(as: flowError1))
        #expect(flowError1.isSameError(as: flowError2))
        #expect(!flowError1.isSameError(as: flowError3))
        
        #expect(flowError2.isSameError(as: flowError1))
        #expect(flowError2.isSameError(as: flowError2))
        #expect(!flowError2.isSameError(as: flowError3))
        
        #expect(!flowError3.isSameError(as: flowError1))
        #expect(!flowError3.isSameError(as: flowError2))
        #expect(flowError3.isSameError(as: flowError3))
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

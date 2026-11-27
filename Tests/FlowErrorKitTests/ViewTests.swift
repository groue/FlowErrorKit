import FlowErrorKit
import Testing
import SwiftUI

@MainActor @Suite
struct ViewTests {
    struct TestError: Error { }
    
    struct TestView: View {
        var body: Never { preconditionFailure() }
    }
    
    @Test
    func handleError_with_handler() {
        // A test that won't compile if we introduce a breaking change
        struct MyErrorHandler: FlowErrorHandler {
            func handle(_ flowError: FlowError) -> FlowErrorHandling {
                preconditionFailure()
            }
        }
        _ = TestView().handleError(with: MyErrorHandler())
    }
    
    @Test
    func handleError_with_FlowError_closure() {
        // A test that won't compile if we introduce a breaking change
        _ = TestView().handleError { (flowError: FlowError) in .cancel }
    }
    
    @Test
    func handleError_ofType() {
        // A test that won't compile if we introduce a breaking change
        _ = TestView().handleError(ofType: TestError.self) { (flowError: FlowError, error: TestError) in .cancel }
    }

    @Test
    func presentError_with_alert() {
        // A test that won't compile if we introduce a breaking change
        let flowError: Binding<FlowError?> = .constant(nil)
        _ = TestView().presentError(flowError, with: .alert)
    }
    
    @Test
    func presentError_with_errorPresentationView() {
        // A test that won't compile if we introduce a breaking change
        let flowError: Binding<FlowError?> = .constant(nil)
        _ = TestView().presentError(flowError, with: .errorPresentationView)
    }
    
    @Test
    func presentError_with_custom_errorPresentationView() {
        // A test that won't compile if we introduce a breaking change
        let flowError: Binding<FlowError?> = .constant(nil)
        _ = TestView().presentError(flowError, with: .errorPresentationView { errorPresentation in
            ErrorPresentationView(errorPresentation, cancelButton: .visible) {
                ProgressView()
            }
            .disabled(true)
        })
    }
}

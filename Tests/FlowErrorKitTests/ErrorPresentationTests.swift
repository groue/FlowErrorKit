import FlowErrorKit
import Testing

@MainActor @Suite
struct ErrorPresentationTests {
    struct TestError: Error { }

    @Test
    func title_and_message() {
        let presentation = ErrorPresentation(
            title: "Title",
            message: "Message",
            flowError: FlowError(error: TestError()))
        #expect(presentation.title == "Title")
        #expect(presentation.message == "Message")
    }

    @Test
    func title_is_trimmed() {
        let presentation = ErrorPresentation(
            title: "  Title\n",
            message: "Message",
            flowError: FlowError(error: TestError()))
        #expect(presentation.title == "Title")
    }

    @Test
    func message_without_title() {
        let presentation = ErrorPresentation(
            message: "Message",
            flowError: FlowError(error: TestError()))
        #expect(presentation.title.isEmpty == false)
        #expect(presentation.message == "Message")
    }

    @Test
    func blank_title_falls_back_to_flow_error_title() {
        let presentation = ErrorPresentation(
            title: " ",
            message: "Message",
            flowError: FlowError(error: TestError()).withTitle("Failure"))
        #expect(presentation.title == "Failure")
        #expect(presentation.message == "Message")
    }

    @Test
    func flow_error_title_without_title() {
        let presentation = ErrorPresentation(
            message: "Message",
            flowError: FlowError(error: TestError()).withTitle("Failure"))
        #expect(presentation.title == "Failure")
        #expect(presentation.message == "Message")
    }

    @Test
    func flow_error_title_moves_title_into_message() {
        let presentation = ErrorPresentation(
            title: "Title",
            message: "Message",
            flowError: FlowError(error: TestError()).withTitle("Failure"))
        #expect(presentation.title == "Failure")
        #expect(presentation.message == "Title\n\nMessage")
    }

    @Test
    func flow_error_title_moves_title_into_message_without_message() {
        let presentation = ErrorPresentation(
            title: "Title",
            flowError: FlowError(error: TestError()).withTitle("Failure"))
        #expect(presentation.title == "Failure")
        #expect(presentation.message == "Title")
    }

    @Test
    func missing_message() {
        let presentation = ErrorPresentation(
            title: "Title",
            flowError: FlowError(error: TestError()))
        #expect(presentation.title == "Title")
#if DEBUG
        #expect(presentation.message?.hasPrefix("DEBUG: ") == true)
#else
        #expect(presentation.message == nil)
#endif
    }
}

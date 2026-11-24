@testable import FlowErrorKit
import SwiftUI
import Testing

@MainActor @Suite
struct ErrorPresentationTests {
    struct TestError: Error { }
    
    @Test
    func title_and_message_verbatim() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError,
            verbatimTitle: "Title",
            message: "Message")
        #expect(presentation.title == .verbatim("Title"))
        #expect(presentation.subtitle == nil)
        #expect(presentation.message == .verbatim("Message"))
    }
    
    @Test
    func title_and_message_literal() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError,
            title: "Title")
            .withMessage("Message")
        #expect(presentation.title == .localizedStringKey("Title"))
        #expect(presentation.subtitle == nil)
        #expect(presentation.message == .localizedStringKey("Message"))
    }
    
    @Test
    func default_title() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(flowError: flowError)
        #expect(presentation.title == .localizedStringResource(.anErrorOccurred))
        #expect(presentation.subtitle == nil)
        #expect(presentation.message == nil)
    }
    
    @Test
    func title_overloads() {
        let flowError = FlowError(error: TestError())
        
        #expect(ErrorPresentation(flowError: flowError, title: "Title")
            .title == .localizedStringKey("Title"), "A string literal is localized")
        
        let count = 1
        #expect(ErrorPresentation(flowError: flowError, title: "Title \(count)")
            .title.isLocalizedStringKey, "An interpolated string literal is localized")
        
        let string: String = "Title"
        #expect(ErrorPresentation(flowError: flowError, title: string)
            .title == .verbatim("Title"), "A string is not localized")
        
        let substring = "Title, etc."
        #expect(ErrorPresentation(flowError: flowError, title: substring.prefix(5))
            .title == .verbatim("Title"), "A substring is not localized")
        
        let resource = LocalizedStringResource("Title")
        #expect(ErrorPresentation(flowError: flowError, title: resource)
            .title == .localizedStringResource(resource))
        
        #expect(ErrorPresentation(flowError: flowError, verbatimTitle: "Title")
            .title == .verbatim("Title"))
    }
    
    @Test
    func nil_title_falls_back_to_default_title() {
        let flowError = FlowError(error: TestError())
        let title: String? = nil
        #expect(ErrorPresentation(flowError: flowError, title: title)
            .title == .localizedStringResource(.anErrorOccurred))
        #expect(ErrorPresentation(flowError: flowError, verbatimTitle: nil)
            .title == .localizedStringResource(.anErrorOccurred))
    }
    
    @Test
    func blank_title_falls_back_to_default_title() {
        let flowError = FlowError(error: TestError())
        for blank: String in ["", " ", "\n"] {
            #expect(ErrorPresentation(flowError: flowError, title: blank)
                .title == .localizedStringResource(.anErrorOccurred))
            #expect(ErrorPresentation(flowError: flowError, title: blank[...])
                .title == .localizedStringResource(.anErrorOccurred))
            #expect(ErrorPresentation(flowError: flowError, verbatimTitle: blank)
                .title == .localizedStringResource(.anErrorOccurred))
        }
    }
    
    @Test
    func string_title_and_message() {
        let flowError = FlowError(error: TestError())
        let title: String = "Title"
        let presentation = ErrorPresentation(
            flowError: flowError,
            title: title,
            message: "Message")
        #expect(presentation.title == .verbatim("Title"))
        #expect(presentation.subtitle == nil)
        #expect(presentation.message == .verbatim("Message"))
    }
    
    @Test
    func localized_titles_move_into_subtitle() {
        let flowError = FlowError(error: TestError()).withTitle(verbatim: "Failure")
        
        #expect(ErrorPresentation(flowError: flowError, title: "Title")
            .subtitle == .localizedStringKey("Title"))
        
        let resource = LocalizedStringResource("Title")
        #expect(ErrorPresentation(flowError: flowError, title: resource)
            .subtitle == .localizedStringResource(resource))
        
        let string: String = "Title"
        #expect(ErrorPresentation(flowError: flowError, title: string)
            .subtitle == .verbatim("Title"))
    }
    
    @Test
    func localized_flow_error_title() {
        let resource = LocalizedStringResource("Failure")
        let flowError = FlowError(error: TestError()).withTitle(resource)
        let presentation = ErrorPresentation(flowError: flowError, title: "Title")
        #expect(presentation.title == .localizedStringResource(resource))
        #expect(presentation.subtitle == .localizedStringKey("Title"))
    }
    
    @Test
    func withMessage_overloads() {
        let presentation = ErrorPresentation(flowError: FlowError(error: TestError()))
        
        #expect(presentation.withMessage("Message")
            .message == .localizedStringKey("Message"), "A string literal is localized")
        
        let count = 1
        #expect(presentation.withMessage("Message \(count)")
            .message?.isLocalizedStringKey == true, "An interpolated string literal is localized")
        
        let string: String = "Message"
        #expect(presentation.withMessage(string)
            .message == .verbatim("Message"), "A string is not localized")
        
        let substring = "Message, etc."
        #expect(presentation.withMessage(substring.prefix(7))
            .message == .verbatim("Message"), "A substring is not localized")
        
        let resource = LocalizedStringResource("Message")
        #expect(presentation.withMessage(resource)
            .message == .localizedStringResource(resource))
        
        #expect(presentation.withMessage(verbatim: "Message")
            .message == .verbatim("Message"))
    }
    
    @Test
    func withMessage_replaces_message_of_any_kind() {
        let resource = LocalizedStringResource("Message 3")
        var presentation = ErrorPresentation(flowError: FlowError(error: TestError()))
        
        presentation = presentation.withMessage("Message 1")
        #expect(presentation.message == .localizedStringKey("Message 1"))
        
        presentation = presentation.withMessage(verbatim: "Message 2")
        #expect(presentation.message == .verbatim("Message 2"))
        
        presentation = presentation.withMessage(resource)
        #expect(presentation.message == .localizedStringResource(resource))
        
        presentation = presentation.withMessage(verbatim: nil)
        #expect(presentation.message == nil)
    }
    
    @Test
    func nil_message_removes_message() {
        let presentation = ErrorPresentation(flowError: FlowError(error: TestError()))
            .withMessage("Message")
        let message: String? = nil
        #expect(presentation.withMessage(message).message == nil)
        #expect(presentation.withMessage(verbatim: nil).message == nil)
        #expect(ErrorPresentation(flowError: presentation.flowError, message: message).message == nil)
    }
    
    @Test
    func withMessage_preserves_title_and_system_image() {
        let flowError = FlowError(error: TestError()).withTitle(verbatim: "Failure")
        let resource = LocalizedStringResource("Message")
        let presentation = ErrorPresentation(
            flowError: flowError,
            title: "Title",
            systemImage: "star")
            .withMessage(resource)
        #expect(presentation.title == .verbatim("Failure"))
        #expect(presentation.subtitle == .localizedStringKey("Title"))
        #expect(presentation.systemImage == "star")
        #expect(presentation.message == .localizedStringResource(resource))
    }
    
    @Test
    func title_is_trimmed() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError,
            verbatimTitle: "  Title\n",
            message: "Message")
        #expect(presentation.title == .verbatim("Title"))
        #expect(presentation.subtitle == nil)
    }
    
    @Test
    func message_without_title() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError,
            message: "Message")
        #expect(presentation.subtitle == nil)
        #expect(presentation.message == .verbatim("Message"))
    }
    
    @Test
    func message_is_trimmed() {
        let flowError = FlowError(error: TestError())
        let message: String = "  Message\n"
        #expect(ErrorPresentation(flowError: flowError, message: message)
            .message == .verbatim("Message"))
        #expect(ErrorPresentation(flowError: flowError)
            .withMessage(message)
            .message == .verbatim("Message"))
        #expect(ErrorPresentation(flowError: flowError)
            .withMessage(verbatim: "  Message\n")
            .message == .verbatim("Message"))
    }
    
    @Test
    func blank_message_is_nil() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(flowError: flowError, message: "Message")
        
        for blank: String in ["", " ", "\n"] {
            #expect(presentation.withMessage(blank).message == nil)
            #expect(presentation.withMessage(blank[...]).message == nil)
            #expect(presentation.withMessage(verbatim: blank).message == nil)
        }
    }
    
    @Test
    func blank_title_falls_back_to_flow_error_title() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError.withTitle(verbatim: "Failure"),
            verbatimTitle: " ",
            message: "Message")
        #expect(presentation.title == .verbatim("Failure"))
        #expect(presentation.subtitle == nil)
        #expect(presentation.message == .verbatim("Message"))
    }
    
    @Test
    func flow_error_title_without_title() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError.withTitle(verbatim: "Failure"),
            message: "Message")
        #expect(presentation.title == .verbatim("Failure"))
        #expect(presentation.subtitle == nil)
        #expect(presentation.message == .verbatim("Message"))
    }
    
    @Test
    func flow_error_title_moves_title_into_subtitle() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError.withTitle(verbatim: "Failure"),
            verbatimTitle: "Title",
            message: "Message")
        #expect(presentation.title == .verbatim("Failure"))
        #expect(presentation.subtitle == .verbatim("Title"))
        #expect(presentation.message == .verbatim("Message"))
    }
    
    @Test
    func flow_error_title_moves_title_into_subtitle_without_message() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError.withTitle(verbatim: "Failure"),
            verbatimTitle: "Title")
        #expect(presentation.title == .verbatim("Failure"))
        #expect(presentation.subtitle == .verbatim("Title"))
        #expect(presentation.message == nil)
    }
    
    @Test
    func equality() {
        let flowError = FlowError(error: TestError())
        let presentation = ErrorPresentation(
            flowError: flowError,
            verbatimTitle: "Title",
            message: "Message")
        
        #expect(presentation == presentation)
        #expect(presentation == ErrorPresentation(
            flowError: flowError,
            verbatimTitle: "Title",
            message: "Message"))
        
        // Default title
        #expect(ErrorPresentation(flowError: flowError) == ErrorPresentation(flowError: flowError))
        
        // Different title
        #expect(presentation != ErrorPresentation(
                flowError: flowError,
                verbatimTitle: "Other",
                message: "Message"))
        
        // Different subtitle (the flow error title wins, and the
        // presentation title becomes the subtitle). Modified flow errors
        // keep their identity.
        #expect(presentation != ErrorPresentation(
            flowError: flowError.withTitle(verbatim: "Title"),
            verbatimTitle: "Subtitle",
            message: "Message"))
        
        // Different message
        #expect(presentation != presentation.withMessage(verbatim: "Other"))
        
        // Different system image
        #expect(presentation != ErrorPresentation(
            flowError: flowError,
            verbatimTitle: "Title",
            message: "Message",
            systemImage: "star"))
        
        // Different flow error
        #expect(presentation != ErrorPresentation(
            flowError: FlowError(error: TestError()),
            verbatimTitle: "Title",
            message: "Message"))
    }
}

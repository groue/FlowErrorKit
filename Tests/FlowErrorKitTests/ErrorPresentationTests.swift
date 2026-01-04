import FlowErrorKit
import Foundation
import Testing

private struct TestError: Error { }

@MainActor @Suite
struct ErrorPresentationTests {
    @Test func texts() {
        let en = Locale(identifier: "en")
        let fr = Locale(identifier: "fr")
        
        let error = TestError()
        do {
            // Without failed action name
            let flowError = FlowError(error: error)
            do {
                // Without presentation title
                do {
                    // Without presentation message
                    let presentation = ErrorPresentation(
                        flowError: flowError
                    )
                    #expect(presentation.title == nil)
                    #expect(presentation.alertTitle.formatted(.text.locale(en)) == "An Error Occurred")
                    #expect(presentation.alertTitle.formatted(.text.locale(fr)) == "Une erreur est survenue")
                    #expect(presentation.alertMessage?.formatted(.text.locale(en)) == "DEBUG: TestError()")
                    #expect(presentation.alertMessage?.formatted(.text.locale(fr)) == "DEBUG: TestError()")
                }
                do {
                    // With presentation message
                    let presentation = ErrorPresentation(
                        message: "Presentation message",
                        flowError: flowError
                    )
                    #expect(presentation.title == nil)
                    #expect(presentation.alertTitle.formatted(.text.locale(en)) == "An Error Occurred")
                    #expect(presentation.alertTitle.formatted(.text.locale(fr)) == "Une erreur est survenue")
                    #expect(presentation.alertMessage?.formatted(.text.locale(en)) == "Presentation message")
                    #expect(presentation.alertMessage?.formatted(.text.locale(fr)) == "Presentation message")
                }
            }
            do {
                // With presentation title
                do {
                    // Without presentation message
                    let presentation = ErrorPresentation(
                        title: "Presentation title",
                        flowError: flowError
                    )
                    #expect(presentation.title?.formatted(.text.locale(en)) == "Presentation title")
                    #expect(presentation.title?.formatted(.text.locale(fr)) == "Presentation title")
                    #expect(presentation.alertTitle.formatted(.text.locale(en)) == "Presentation title")
                    #expect(presentation.alertTitle.formatted(.text.locale(fr)) == "Presentation title")
                    #expect(presentation.alertMessage?.formatted(.text.locale(en)) == "DEBUG: TestError()")
                    #expect(presentation.alertMessage?.formatted(.text.locale(fr)) == "DEBUG: TestError()")
                }
                do {
                    // With presentation message
                    let presentation = ErrorPresentation(
                        title: "Presentation title",
                        message: "Presentation message",
                        flowError: flowError
                    )
                    #expect(presentation.title?.formatted(.text.locale(en)) == "Presentation title")
                    #expect(presentation.title?.formatted(.text.locale(fr)) == "Presentation title")
                    #expect(presentation.alertTitle.formatted(.text.locale(en)) == "Presentation title")
                    #expect(presentation.alertTitle.formatted(.text.locale(fr)) == "Presentation title")
                    #expect(presentation.alertMessage?.formatted(.text.locale(en)) == "Presentation message")
                    #expect(presentation.alertMessage?.formatted(.text.locale(fr)) == "Presentation message")
                }
            }
        }
        do {
            // With failed action name
            let flowError = FlowError(error: error).withFailedActionName("Failed action name")
            do {
                // Without presentation title
                do {
                    // Without presentation message
                    let presentation = ErrorPresentation(
                        flowError: flowError
                    )
                    #expect(presentation.title == nil)
                    #expect(presentation.alertTitle.formatted(.text.locale(en)) == "Failed action name")
                    #expect(presentation.alertTitle.formatted(.text.locale(fr)) == "Failed action name")
                    #expect(presentation.alertMessage?.formatted(.text.locale(en)) == "DEBUG: TestError()")
                    #expect(presentation.alertMessage?.formatted(.text.locale(fr)) == "DEBUG: TestError()")
                }
                do {
                    // With presentation message
                    let presentation = ErrorPresentation(
                        message: "Presentation message",
                        flowError: flowError
                    )
                    #expect(presentation.title == nil)
                    #expect(presentation.alertTitle.formatted(.text.locale(en)) == "Failed action name")
                    #expect(presentation.alertTitle.formatted(.text.locale(fr)) == "Failed action name")
                    #expect(presentation.alertMessage?.formatted(.text.locale(en)) == "Presentation message")
                    #expect(presentation.alertMessage?.formatted(.text.locale(fr)) == "Presentation message")
                }
            }
            do {
                // With presentation title
                do {
                    // Without presentation message
                    let presentation = ErrorPresentation(
                        title: "Presentation title",
                        flowError: flowError
                    )
                    #expect(presentation.title?.formatted(.text.locale(en)) == "Presentation title")
                    #expect(presentation.title?.formatted(.text.locale(fr)) == "Presentation title")
                    #expect(presentation.alertTitle.formatted(.text.locale(en)) == "Failed action name")
                    #expect(presentation.alertTitle.formatted(.text.locale(fr)) == "Failed action name")
                    #expect(presentation.alertMessage?.formatted(.text.locale(en)) == "Presentation title\nDEBUG: TestError()")
                    #expect(presentation.alertMessage?.formatted(.text.locale(fr)) == "Presentation title\nDEBUG: TestError()")
                }
                do {
                    // With presentation message
                    let presentation = ErrorPresentation(
                        title: "Presentation title",
                        message: "Presentation message",
                        flowError: flowError
                    )
                    #expect(presentation.title?.formatted(.text.locale(en)) == "Presentation title")
                    #expect(presentation.title?.formatted(.text.locale(fr)) == "Presentation title")
                    #expect(presentation.alertTitle.formatted(.text.locale(en)) == "Failed action name")
                    #expect(presentation.alertTitle.formatted(.text.locale(fr)) == "Failed action name")
                    #expect(presentation.alertMessage?.formatted(.text.locale(en)) == "Presentation title\nPresentation message")
                    #expect(presentation.alertMessage?.formatted(.text.locale(fr)) == "Presentation title\nPresentation message")
                }
            }
        }
    }
}

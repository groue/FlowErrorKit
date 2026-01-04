import Foundation
import SwiftUI

/// `ErrorPresentation` describes how an error should be presented to the user.
@MainActor public struct ErrorPresentation {
    /// The default system symbol image for errors.
    public static let defaultSystemImage = "exclamationmark.circle"
    
    /// The error title.
    public var title: TextContent?
    
    /// The error message.
    public var message: TextContent?
    
    // A system symbol image.
    public var systemImage: String
    
    /// The presented flow error.
    public var flowError: FlowError
    
    public var alertTitle: TextContent {
        if let failedActionName = flowError.failedActionName {
            return failedActionName
        } else if let title {
            return title
        } else {
            return .resource(.anErrorOccurred)
        }
    }
    
    public var alertMessage: Message? {
        if flowError.failedActionName != nil,
           let title = title
        {
            if let message = message {
                return Message(text1: title, text2: message)
            } else {
#if DEBUG
                return Message(text1: title, text2: .verbatim("DEBUG: \(flowError.error)"))
#else
                return Message(text1: title)
#endif
            }
        } else {
#if DEBUG
            if let message = message {
                return Message(text1: message)
            } else {
                return Message(text1: .verbatim("DEBUG: \(flowError.error)"))
            }
#else
            if let messageContent = messageContent {
                return Message(text1: messageContent)
            } else {
                return nil
            }
#endif
        }
    }
    
    /// Creates an `ErrorPresentation` without localization.
    @_disfavoredOverload
    public init(
        title: String? = nil,
        message: String? = nil,
        systemImage: String = Self.defaultSystemImage,
        flowError: FlowError
    ) {
        self.title = title.map { .verbatim($0) }
        self.message = message.map { .verbatim($0) }
        self.systemImage = systemImage
        self.flowError = flowError
    }
    
    /// Creates an `ErrorPresentation` with localized strings.
    public init(
        title: LocalizedStringResource? = nil,
        message: LocalizedStringResource? = nil,
        systemImage: String = Self.defaultSystemImage,
        flowError: FlowError
    ) {
        self.title = title.map { .resource($0) }
        self.message = message.map { .resource($0) }
        self.systemImage = systemImage
        self.flowError = flowError
    }
    
    /// Returns an error presentation with a title without localization.
    @_disfavoredOverload
    public func withTitle(_ title: String) -> Self {
        withTitle(verbatim: title)
    }
    
    /// Returns an error presentation with a title without localization.
    public func withTitle(verbatim title: String) -> Self {
        var result = self
        result.title = title.presence.map { .verbatim($0) }
        return result
    }
    
    /// Returns an error presentation with a localized title.
    public func withTitle(_ title: LocalizedStringResource?) -> Self {
        var result = self
        result.title = title.map { .resource($0) }
        return result
    }
    
    /// Returns an error presentation with a message without localization.
    @_disfavoredOverload
    public func withMessage(_ message: String) -> Self {
        withMessage(verbatim: message)
    }
    
    /// Returns an error presentation with a message without localization.
    public func withMessage(verbatim message: String) -> Self {
        var result = self
        result.message = message.presence.map { .verbatim($0) }
        return result
    }
    
    /// Returns an error presentation with a localized message.
    public func withMessage(_ message: LocalizedStringResource?) -> Self {
        var result = self
        result.message = message.map { .resource($0) }
        return result
    }
}

extension ErrorPresentation {
    public struct Message: Equatable {
        var text1: TextContent
        var text2: TextContent?
    }
}

extension ErrorPresentation.Message {
    public struct FormatStyle: Foundation.FormatStyle {
        var locale = Locale.current
        
        public init() { }
        
        public func format(_ value: ErrorPresentation.Message) -> String {
            let formatted1 = value.text1.formatted(.text.locale(locale))
            let formatted2 = value.text2?.formatted(.text.locale(locale))
            if let formatted2 {
                return "\(formatted1)\n\(formatted2)"
            } else {
                return formatted1
            }
        }

        public func locale(_ locale: Locale) -> Self {
            var result = self
            result.locale = locale
            return result
        }
    }
}

extension FormatStyle where Self == ErrorPresentation.Message.FormatStyle {
    public static var text: ErrorPresentation.Message.FormatStyle { .init() }
}

extension ErrorPresentation.Message {
    public func formatted<F>(_ format: F) -> F.FormatOutput
    where F: Foundation.FormatStyle, F.FormatInput == Self
    {
        format.format(self)
    }
}

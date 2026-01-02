import Foundation
import SwiftUI

/// `ErrorPresentation` describes how an error should be presented to the user.
@MainActor public struct ErrorPresentation {
    /// The default system symbol image for errors.
    public static let defaultSystemImage = "exclamationmark.circle"
    
    /// The error title.
    fileprivate var title: TextContent?
    
    /// The error message.
    fileprivate var message: TextContent?
    
    // A system symbol image.
    public var systemImage: String
    
    /// The presented flow error.
    public var flowError: FlowError
    
    fileprivate var alertTitle: TextContent {
        if let errorTitle = flowError.title {
            return errorTitle
        } else if let title {
            return title
        } else {
            return .resource(.anErrorOccurred)
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

public struct ErrorPresentationLabel: View {
    var errorPresentation: ErrorPresentation
    
    public init(_ errorPresentation: ErrorPresentation) {
        self.errorPresentation = errorPresentation
    }
    
    public var body: some View {
        Label {
            Text(errorPresentation.alertTitle)
        } icon: {
            Image(systemName: errorPresentation.systemImage)
        }
    }
}

extension Text {
    @MainActor init(
        titleFor errorPresentation: ErrorPresentation
    ) {
        self.init(errorPresentation.alertTitle)
    }
}

extension Text {
    @MainActor init?(
        messageFor errorPresentation: ErrorPresentation
    ) {
        if errorPresentation.flowError.title != nil,
           let customTitle = errorPresentation.title
        {
            if let message = errorPresentation.message {
                self = Text("\(Text(customTitle))\n\(Text(message))")
            } else {
                self = Text(customTitle)
            }
        } else {
#if DEBUG
            if let message = errorPresentation.message {
                self = Text(message)
            } else {
                self = Text(verbatim: "DEBUG: \(errorPresentation.flowError.error)")
            }
#else
            if let message = errorPresentation.message {
                self = Text(message)
            } else {
                return nil
            }
#endif
        }
    }
}

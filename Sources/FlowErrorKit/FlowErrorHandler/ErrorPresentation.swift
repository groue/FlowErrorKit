import Foundation

/// `ErrorPresentation` describes how an error should be presented to the user.
public struct ErrorPresentation {
    /// The default system symbol image for errors.
    public static let defaultSystemImage = "exclamationmark.circle"
    
    /// The error title.
    public var title: String
    
    /// The error message.
    public var message: String?
    
    /// A system symbol image.
    public var systemImage: String
    
    /// The presented flow error.
    public var flowError: FlowError
    
    /// Creates an `ErrorPresentation`.
    ///
    /// - parameter title: The error title. If nil, the title is the
    ///   ``FlowError/redactedTitle`` of the flow error, or
    ///   "An Error Occurred". If both `title` and the redacted title are
    ///   present, the redacted title is used as the title, and `title` is
    ///   moved into the message.
    /// - parameter message: The error message. In the Debug
    ///   configuration, a nil message is replaced with a description of
    ///   the error.
    /// - parameter systemImage: A system symbol image.
    /// - parameter flowError: The presented flow error.
    @MainActor public init(
        title: String? = nil,
        message: String? = nil,
        systemImage: String = Self.defaultSystemImage,
        flowError: FlowError
    ) {
        if let titlePresence = title.presence, let redactedTitle = flowError.redactedTitle.presence {
            // The redacted title wins, and the provided title is moved
            // into the message.
            self.title = redactedTitle
            self.message = [titlePresence, message.presence]
                .compactMap { $0 }
                .joined(separator: "\n\n")
        } else {
            self.title = title.presence
            ?? flowError.redactedTitle.presence
            ?? String(localized: .defaultErrorTitle, bundle: .module)
#if DEBUG
            self.message = message ?? "DEBUG: \(flowError.error)"
#else
            self.message = message
#endif
        }
        
        self.systemImage = systemImage
        self.flowError = flowError
    }
}

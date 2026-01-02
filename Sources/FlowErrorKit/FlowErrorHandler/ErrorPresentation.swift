import Foundation

/// `ErrorPresentation` describes how an error should be presented to the user.
public struct ErrorPresentation: Sendable {
    /// The default system symbol image for errors.
    public static let defaultSystemImage = "exclamationmark.circle"
    
    /// The error title.
    public var title: String
    
    /// The error message.
    public var message: String?
    
    // A system symbol image.
    public var systemImage: String
    
    /// The presented flow error.
    public var flowError: FlowError
    
    /// Creates an `ErrorPresentation`.
    @MainActor public init(
        title: String? = nil,
        message: String? = nil,
        systemImage: String = Self.defaultSystemImage,
        flowError: FlowError
    ) {
        if let customTitle = title.presence {
            if let errorTitle = flowError.title.presence {
                self.title = errorTitle
                self.message = [customTitle, message.presence]
                    .compactMap { $0 }
                    .joined(separator: "\n")
            } else {
                self.title = customTitle
#if DEBUG
                self.message = message ?? "DEBUG: \(flowError.error)"
#else
                self.message = message
#endif
            }
        } else {
            self.title = flowError.title.presence ?? String(localized: .defaultErrorTitle, bundle: .module)
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

import Foundation
import SwiftUI

/// `ErrorPresentation` describes how an error should be presented to the user.
///
/// You create an error presentation from a ``FlowErrorHandler``, or
/// any place where you need to describe how a flow error should be
/// displayed:
///
/// ```swift
/// ErrorPresentation(flowError: flowError)
/// ```
///
/// You can optionally provide a title and a message to the presentation:
///
/// ```swift
/// ErrorPresentation(flowError: flowError, title: "Permission Required")
///     .withMessage("Please grant access to your location in the Settings application.")
/// ```
///
/// Like SwiftUI `Text`, titles and messages are localized when you provide
/// a string literal, and displayed verbatim when you provide a `String`:
///
/// ```swift
/// ErrorPresentation(flowError: flowError, title: "Unknown User")  // localized
/// ErrorPresentation(flowError: flowError, title: serverMessage)   // verbatim
/// ```
///
/// ## Topics
///
/// ### Creating an error presentation
///
/// - ``init(flowError:systemImage:)``
/// - ``init(flowError:title:systemImage:)-(_,LocalizedStringKey,_)``
/// - ``init(flowError:title:systemImage:)-(_,LocalizedStringResource,_)``
/// - ``init(flowError:title:message:systemImage:)``
/// - ``init(flowError:message:systemImage:)``
/// - ``init(flowError:verbatimTitle:message:systemImage:)``
/// - ``defaultSystemImage``
///
/// ### Error presentation information
///
/// - ``title``
/// - ``subtitle``
/// - ``message``
/// - ``systemImage``
/// - ``flowError``
///
/// ### Setting the message
///
/// - ``withMessage(_:)-(LocalizedStringKey)``
/// - ``withMessage(_:)-(LocalizedStringResource)``
/// - ``withMessage(_:)-(StringProtocol?)``
/// - ``withMessage(verbatim:)``
public struct ErrorPresentation: ~Sendable {
    // ErrorPresentation is ~Sendable because of TextSource.
    
    /// The default system symbol image for errors.
    public static let defaultSystemImage = "exclamationmark.circle"
    
    /// The error title.
    public let title: TextSource
    
    /// An optional subtitle.
    public let subtitle: TextSource?
    
    /// The error message.
    ///
    /// To set the message, use ``withMessage(_:)-(LocalizedStringKey)``.
    public private(set) var message: TextSource?
    
    /// A system symbol image.
    public let systemImage: String
    
    /// The presented flow error.
    public let flowError: FlowError
    
    /// Creates an `ErrorPresentation`.
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - titleSource: The error title.
    ///     - systemImage: A system symbol image.
    @MainActor init(
        flowError: FlowError,
        titleSource: TextSource? = nil,
        messageSource: TextSource? = nil,
        systemImage: String = Self.defaultSystemImage,
    ) {
        let titlePresence = titleSource.presence
        let flowErrorTitlePresence = flowError.title.presence
        if let titlePresence, let flowErrorTitlePresence {
            // The FlowError wins
            self.title = flowErrorTitlePresence
            self.subtitle = titlePresence
        } else {
            self.title = titlePresence
            ?? flowErrorTitlePresence
            ?? .localizedStringResource(.anErrorOccurred)
            self.subtitle = nil
        }
        
        self.systemImage = systemImage
        self.flowError = flowError
        self.message = messageSource?.presence
    }
    
    /// Creates an `ErrorPresentation`.
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - systemImage: A system symbol image.
    @MainActor public init(
        flowError: FlowError,
        systemImage: String = Self.defaultSystemImage,
    ) {
        self.systemImage = systemImage
        self.flowError = flowError
        self.title = flowError.title.presence ?? .localizedStringResource(.anErrorOccurred)
        self.subtitle = nil
    }
    
    /// Creates an `ErrorPresentation` with a title that is not localized.
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The error title, displayed without localization.
    ///       Leading and trailing whitespace is trimmed. A nil or blank
    ///       title is ignored.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - systemImage: A system symbol image.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        title: some StringProtocol?,
        message: String? = nil,
        systemImage: String = Self.defaultSystemImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: title.map { .verbatim($0) },
            messageSource: message.map { .verbatim($0) },
            systemImage: systemImage)
    }
    
    /// Creates an `ErrorPresentation` with a localized title.
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The localized error title.
    ///     - systemImage: A system symbol image.
    @MainActor public init(
        flowError: FlowError,
        title: LocalizedStringKey,
        systemImage: String = Self.defaultSystemImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: .localizedStringKey(title),
            systemImage: systemImage)
    }
    
    /// Creates an `ErrorPresentation` with a localized title.
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The localized error title.
    ///     - systemImage: A system symbol image.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        title: LocalizedStringResource,
        systemImage: String = Self.defaultSystemImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: .localizedStringResource(title),
            systemImage: systemImage)
    }
    
    /// Creates an `ErrorPresentation` with a message that is not localized.
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - systemImage: A system symbol image.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        message: some StringProtocol?,
        systemImage: String = Self.defaultSystemImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: nil,
            messageSource: message.map { .verbatim($0) },
            systemImage: systemImage)
    }
    
    /// Creates an `ErrorPresentation` with a title that is not localized.
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The error title, displayed without localization.
    ///       Leading and trailing whitespace is trimmed. A nil or blank
    ///       title is ignored.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - systemImage: A system symbol image.
    @MainActor public init(
        flowError: FlowError,
        verbatimTitle title: String?,
        message: String? = nil,
        systemImage: String = Self.defaultSystemImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: title.map { .verbatim($0) },
            messageSource: message.map { .verbatim($0) },
            systemImage: systemImage)
    }
    
    /// Returns an error presentation with a message that is not localized.
    ///
    /// For example:
    ///
    /// ```swift
    /// ErrorPresentation(flowError: flowError)
    ///     .withMessage(error.localizedDescription)
    /// ```
    ///
    /// - parameter message: The error message, displayed without
    ///   localization. Leading and trailing whitespace is trimmed. A nil
    ///   or blank message removes the message.
    @_disfavoredOverload
    public func withMessage(_ message: some StringProtocol?) -> Self {
        var result = self
        result.message = message.map { .verbatim($0) }.presence
        return result
    }
    
    /// Returns an error presentation with a localized message.
    ///
    /// For example:
    ///
    /// ```swift
    /// ErrorPresentation(flowError: flowError, title: "Permission Required")
    ///     .withMessage("Please grant access to your location in the Settings application.")
    /// ```
    ///
    /// - parameter message: The localized error message.
    public func withMessage(
        _ message: LocalizedStringKey
    ) -> Self {
        var result = self
        result.message = .localizedStringKey(message)
        return result
    }
    
    /// Returns an error presentation with a localized message.
    ///
    /// - parameter message: The localized error message.
    @_disfavoredOverload
    public func withMessage(
        _ message: LocalizedStringResource
    ) -> Self {
        var result = self
        result.message = .localizedStringResource(message)
        return result
    }
    
    /// Returns an error presentation with a message that is not localized.
    ///
    /// - parameter message: The error message, displayed without
    ///   localization. Leading and trailing whitespace is trimmed. A nil
    ///   or blank message removes the message.
    public func withMessage(verbatim message: String?) -> Self {
        withMessage(message)
    }
}

extension ErrorPresentation: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        (lhs.title, lhs.subtitle, lhs.message, lhs.systemImage, lhs.flowError.id)
        == (rhs.title, rhs.subtitle, rhs.message, rhs.systemImage, rhs.flowError.id)
    }
}

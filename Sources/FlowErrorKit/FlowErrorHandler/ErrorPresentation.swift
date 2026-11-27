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
///     .withMessage("""
///         Please grant access to your location in the Settings application.
///         """)
/// ```
///
/// Like SwiftUI `Text`, titles and messages are localized when you provide
/// a string literal, and displayed verbatim when you provide a `String`:
///
/// ```swift
/// // Localized
/// ErrorPresentation(flowError: flowError, title: "Unknown User")
///
/// // Verbatim
/// ErrorPresentation(flowError: flowError, title: serverMessage)
/// ```
///
/// The image is an `Image`, or the name of a system symbol image:
///
/// ```swift
/// ErrorPresentation(
///     flowError: flowError,
///     image: Image(.networkError))
///
/// ErrorPresentation(
///     flowError: flowError,
///     systemImage: "wifi.exclamationmark")
/// ```
///
/// ## Topics
///
/// ### Creating an error presentation
///
/// - ``init(flowError:image:)``
/// - ``init(flowError:systemImage:)``
/// - ``init(flowError:title:image:)-(_,LocalizedStringKey,_)``
/// - ``init(flowError:title:systemImage:)-(_,LocalizedStringKey,_)``
/// - ``init(flowError:title:image:)-(_,LocalizedStringResource,_)``
/// - ``init(flowError:title:systemImage:)-(_,LocalizedStringResource,_)``
/// - ``init(flowError:title:message:image:)``
/// - ``init(flowError:title:message:systemImage:)``
/// - ``init(flowError:message:image:)``
/// - ``init(flowError:message:systemImage:)``
/// - ``init(flowError:verbatimTitle:message:image:)``
/// - ``init(flowError:verbatimTitle:message:systemImage:)``
/// - ``defaultImage``
///
/// ### Error presentation information
///
/// - ``title``
/// - ``subtitle``
/// - ``message``
/// - ``image``
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
    
    /// The default image for errors.
    public static var defaultImage: Image {
        Image(systemName: "exclamationmark.circle")
    }
    
    /// The error title.
    public let title: TextSource
    
    /// An optional subtitle.
    ///
    /// When both the flow error and the creator of the presentation
    /// provide a title, the title of the flow error is the ``title`` of
    /// the presentation, and the other one is the subtitle.
    public let subtitle: TextSource?
    
    /// The error message.
    ///
    /// To set the message, use ``withMessage(_:)-(LocalizedStringKey)``.
    public private(set) var message: TextSource?
    
    /// The image of the error presentation.
    public let image: Image
    
    /// The presented flow error.
    public let flowError: FlowError
    
    /// Creates an `ErrorPresentation`.
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - titleSource: The error title.
    ///     - messageSource: The error message.
    ///     - image: The image of the error presentation.
    @MainActor init(
        flowError: FlowError,
        titleSource: TextSource? = nil,
        messageSource: TextSource? = nil,
        image: Image = Self.defaultImage,
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
        
        self.image = image
        self.flowError = flowError
        self.message = messageSource?.presence
    }
    
    /// Creates an error presentation with an image.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, a generic localized title.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ An Error Occurred         │ │ Could not load the news   │
    /// // ├─────────────┬─────────────┤ ├─────────────┬─────────────┤
    /// // │   Cancel    │    Retry    │ │   Cancel    │    Retry    │
    /// // ╰─────────────┴─────────────╯ ╰─────────────┴─────────────╯
    /// ErrorPresentation(flowError: flowError)
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - image: The image of the error presentation.
    @MainActor public init(
        flowError: FlowError,
        image: Image = Self.defaultImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: nil,
            image: image)
    }
    
    /// Creates an error presentation with a system symbol image.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, a generic localized title.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ An Error Occurred         │ │ Could not load the news   │
    /// // ├─────────────┬─────────────┤ ├─────────────┬─────────────┤
    /// // │   Cancel    │    Retry    │ │   Cancel    │    Retry    │
    /// // ╰─────────────┴─────────────╯ ╰─────────────┴─────────────╯
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     systemImage: "wifi.exclamationmark")
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - name: The name of the system symbol image.
    @MainActor public init(
        flowError: FlowError,
        systemImage name: String,
    ) {
        self.init(
            flowError: flowError,
            titleSource: nil,
            image: Image(systemName: name))
    }
    
    /// Creates an error presentation with an image, and a title and
    /// an optional message generated from strings.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, the provided title. When the flow error
    /// has a title, the provided title becomes the subtitle.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ Not Connected             │ │ Could not load the news   │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ The Internet connection   │ │ Not Connected             │
    /// // │ appears to be offline.    │ │ The Internet connection   │
    /// // ├─────────────┬─────────────┤ │ appears to be offline.    │
    /// // │   Cancel    │    Retry    │ ├─────────────┬─────────────┤
    /// // ╰─────────────┴─────────────╯ │   Cancel    │    Retry    │
    /// //                               ╰─────────────┴─────────────╯
    /// let title = "Not Connected"
    /// let message = "The Internet connection appears to be offline."
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     title: title,
    ///     message: message)
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The error title, displayed without localization.
    ///       Leading and trailing whitespace is trimmed. A nil or blank
    ///       title is ignored.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - image: The image of the error presentation.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        title: some StringProtocol?,
        message: String? = nil,
        image: Image = Self.defaultImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: title.map { .verbatim($0) },
            messageSource: message.map { .verbatim($0) },
            image: image)
    }
    
    /// Creates an error presentation with a system symbol image, and a title and
    /// an optional message generated from strings.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, the provided title. When the flow error
    /// has a title, the provided title becomes the subtitle.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ Not Connected             │ │ Could not load the news   │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ The Internet connection   │ │ Not Connected             │
    /// // │ appears to be offline.    │ │ The Internet connection   │
    /// // ├─────────────┬─────────────┤ │ appears to be offline.    │
    /// // │   Cancel    │    Retry    │ ├─────────────┬─────────────┤
    /// // ╰─────────────┴─────────────╯ │   Cancel    │    Retry    │
    /// //                               ╰─────────────┴─────────────╯
    /// let title = "Not Connected"
    /// let message = "The Internet connection appears to be offline."
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     title: title,
    ///     message: message,
    ///     systemImage: "wifi.exclamationmark")
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The error title, displayed without localization.
    ///       Leading and trailing whitespace is trimmed. A nil or blank
    ///       title is ignored.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - name: The name of the system symbol image.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        title: some StringProtocol?,
        message: String? = nil,
        systemImage name: String,
    ) {
        self.init(
            flowError: flowError,
            titleSource: title.map { .verbatim($0) },
            messageSource: message.map { .verbatim($0) },
            image: Image(systemName: name))
    }
    
    /// Creates an error presentation with an image and a title
    /// generated from a localized string.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, the provided title. When the flow error
    /// has a title, the provided title becomes the subtitle.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ Not Connected             │ │ Could not load the news   │
    /// // ├─────────────┬─────────────┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │   Cancel    │    Retry    │ │ Not Connected             │
    /// // ╰─────────────┴─────────────╯ ├─────────────┬─────────────┤
    /// //                               │   Cancel    │    Retry    │
    /// //                               ╰─────────────┴─────────────╯
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     title: "Not Connected")
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The localized error title.
    ///     - image: The image of the error presentation.
    @MainActor public init(
        flowError: FlowError,
        title: LocalizedStringKey,
        image: Image = Self.defaultImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: .localizedStringKey(title),
            image: image)
    }
    
    /// Creates an error presentation with a system symbol image and a title
    /// generated from a localized string.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, the provided title. When the flow error
    /// has a title, the provided title becomes the subtitle.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ Not Connected             │ │ Could not load the news   │
    /// // ├─────────────┬─────────────┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │   Cancel    │    Retry    │ │ Not Connected             │
    /// // ╰─────────────┴─────────────╯ ├─────────────┬─────────────┤
    /// //                               │   Cancel    │    Retry    │
    /// //                               ╰─────────────┴─────────────╯
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     title: "Not Connected",
    ///     systemImage: "wifi.exclamationmark")
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The localized error title.
    ///     - name: The name of the system symbol image.
    @MainActor public init(
        flowError: FlowError,
        title: LocalizedStringKey,
        systemImage name: String,
    ) {
        self.init(
            flowError: flowError,
            titleSource: .localizedStringKey(title),
            image: Image(systemName: name))
    }
    
    /// Creates an error presentation with an image and a title
    /// generated from a localized string resource.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, the provided title. When the flow error
    /// has a title, the provided title becomes the subtitle.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ Not Connected             │ │ Could not load the news   │
    /// // ├─────────────┬─────────────┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │   Cancel    │    Retry    │ │ Not Connected             │
    /// // ╰─────────────┴─────────────╯ ├─────────────┬─────────────┤
    /// //                               │   Cancel    │    Retry    │
    /// //                               ╰─────────────┴─────────────╯
    /// let title: LocalizedStringResource = "Not Connected"
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     title: title)
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The localized error title.
    ///     - image: The image of the error presentation.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        title: LocalizedStringResource,
        image: Image = Self.defaultImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: .localizedStringResource(title),
            image: image)
    }
    
    /// Creates an error presentation with a system symbol image and a title
    /// generated from a localized string resource.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, the provided title. When the flow error
    /// has a title, the provided title becomes the subtitle.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ Not Connected             │ │ Could not load the news   │
    /// // ├─────────────┬─────────────┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │   Cancel    │    Retry    │ │ Not Connected             │
    /// // ╰─────────────┴─────────────╯ ├─────────────┬─────────────┤
    /// //                               │   Cancel    │    Retry    │
    /// //                               ╰─────────────┴─────────────╯
    /// let title: LocalizedStringResource = "Not Connected"
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     title: title,
    ///     systemImage: "wifi.exclamationmark")
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The localized error title.
    ///     - name: The name of the system symbol image.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        title: LocalizedStringResource,
        systemImage name: String,
    ) {
        self.init(
            flowError: flowError,
            titleSource: .localizedStringResource(title),
            image: Image(systemName: name))
    }
    
    /// Creates an error presentation with an image and a message
    /// generated from a string.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, a generic localized title.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ An Error Occurred         │ │ Could not load the news   │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ The Internet connection   │ │ The Internet connection   │
    /// // │ appears to be offline.    │ │ appears to be offline.    │
    /// // ├─────────────┬─────────────┤ ├─────────────┬─────────────┤
    /// // │   Cancel    │    Retry    │ │   Cancel    │    Retry    │
    /// // ╰─────────────┴─────────────╯ ╰─────────────┴─────────────╯
    /// let message = "The Internet connection appears to be offline."
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     message: message)
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - image: The image of the error presentation.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        message: some StringProtocol?,
        image: Image = Self.defaultImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: nil,
            messageSource: message.map { .verbatim($0) },
            image: image)
    }
    
    /// Creates an error presentation with a system symbol image and a message
    /// generated from a string.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, a generic localized title.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ An Error Occurred         │ │ Could not load the news   │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ The Internet connection   │ │ The Internet connection   │
    /// // │ appears to be offline.    │ │ appears to be offline.    │
    /// // ├─────────────┬─────────────┤ ├─────────────┬─────────────┤
    /// // │   Cancel    │    Retry    │ │   Cancel    │    Retry    │
    /// // ╰─────────────┴─────────────╯ ╰─────────────┴─────────────╯
    /// let message = "The Internet connection appears to be offline."
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     message: message,
    ///     systemImage: "wifi.exclamationmark")
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - name: The name of the system symbol image.
    @_disfavoredOverload
    @MainActor public init(
        flowError: FlowError,
        message: some StringProtocol?,
        systemImage name: String,
    ) {
        self.init(
            flowError: flowError,
            titleSource: nil,
            messageSource: message.map { .verbatim($0) },
            image: Image(systemName: name))
    }
    
    /// Creates an error presentation with an image, a verbatim title,
    /// and an optional verbatim message.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, the provided title. When the flow error
    /// has a title, the provided title becomes the subtitle.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ Not Connected             │ │ Could not load the news   │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ The Internet connection   │ │ Not Connected             │
    /// // │ appears to be offline.    │ │ The Internet connection   │
    /// // ├─────────────┬─────────────┤ │ appears to be offline.    │
    /// // │   Cancel    │    Retry    │ ├─────────────┬─────────────┤
    /// // ╰─────────────┴─────────────╯ │   Cancel    │    Retry    │
    /// //                               ╰─────────────┴─────────────╯
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     verbatimTitle: "Not Connected",
    ///     message: "The Internet connection appears to be offline.")
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The error title, displayed without localization.
    ///       Leading and trailing whitespace is trimmed. A nil or blank
    ///       title is ignored.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - image: The image of the error presentation.
    @MainActor public init(
        flowError: FlowError,
        verbatimTitle title: String?,
        message: String? = nil,
        image: Image = Self.defaultImage,
    ) {
        self.init(
            flowError: flowError,
            titleSource: title.map { .verbatim($0) },
            messageSource: message.map { .verbatim($0) },
            image: image)
    }
    
    /// Creates an error presentation with a system symbol image, a verbatim
    /// title, and an optional verbatim message.
    ///
    /// The returned presentation has a title that is the flow error's
    /// title, or, if missing, the provided title. When the flow error
    /// has a title, the provided title becomes the subtitle.
    ///
    /// For example:
    ///
    /// ``` swift
    /// // ╭───────────────────────────╮ ╭───────────────────────────╮
    /// // │ Not Connected             │ │ Could not load the news   │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤ ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ The Internet connection   │ │ Not Connected             │
    /// // │ appears to be offline.    │ │ The Internet connection   │
    /// // ├─────────────┬─────────────┤ │ appears to be offline.    │
    /// // │   Cancel    │    Retry    │ ├─────────────┬─────────────┤
    /// // ╰─────────────┴─────────────╯ │   Cancel    │    Retry    │
    /// //                               ╰─────────────┴─────────────╯
    /// ErrorPresentation(
    ///     flowError: flowError,
    ///     verbatimTitle: "Not Connected",
    ///     message: "The Internet connection appears to be offline.",
    ///     systemImage: "wifi.exclamationmark")
    /// ```
    ///
    /// - parameters:
    ///     - flowError: The presented flow error.
    ///     - title: The error title, displayed without localization.
    ///       Leading and trailing whitespace is trimmed. A nil or blank
    ///       title is ignored.
    ///     - message: The error message, displayed without
    ///       localization. Leading and trailing whitespace is trimmed. A
    ///       nil or blank message is ignored.
    ///     - name: The name of the system symbol image.
    @MainActor public init(
        flowError: FlowError,
        verbatimTitle title: String?,
        message: String? = nil,
        systemImage name: String,
    ) {
        self.init(
            flowError: flowError,
            titleSource: title.map { .verbatim($0) },
            messageSource: message.map { .verbatim($0) },
            image: Image(systemName: name))
    }
    
    /// Returns an error presentation with a message that is not localized.
    ///
    /// For example:
    ///
    /// ```swift
    /// // ╭───────────────────────────╮
    /// // │ An Error Occurred         │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ The Internet connection   │
    /// // │ appears to be offline.    │
    /// // ├─────────────┬─────────────┤
    /// // │   Cancel    │    Retry    │
    /// // ╰─────────────┴─────────────╯
    /// let message = "The Internet connection appears to be offline."
    /// ErrorPresentation(flowError: flowError)
    ///     .withMessage(message)
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
    /// // ╭───────────────────────────╮
    /// // │ Permission Required       │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ Please grant access to    │
    /// // │ your location in the      │
    /// // │ Settings application.     │
    /// // ├───────────────────────────┤
    /// // │             OK            │
    /// // ╰───────────────────────────╯
    /// ErrorPresentation(flowError: flowError, title: "Permission Required")
    ///     .withMessage("""
    ///         Please grant access to your location in the Settings application.
    ///         """)
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
    /// For example:
    ///
    /// ```swift
    /// // ╭───────────────────────────╮
    /// // │ Permission Required       │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ Please grant access to    │
    /// // │ your location in the      │
    /// // │ Settings application.     │
    /// // ├───────────────────────────┤
    /// // │             OK            │
    /// // ╰───────────────────────────╯
    /// let message: LocalizedStringResource = """
    ///     Please grant access to your location in the Settings application.
    ///     """
    /// ErrorPresentation(flowError: flowError, title: "Permission Required")
    ///     .withMessage(message)
    /// ```
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
    /// For example:
    ///
    /// ```swift
    /// // ╭───────────────────────────╮
    /// // │ An Error Occurred         │
    /// // ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
    /// // │ The Internet connection   │
    /// // │ appears to be offline.    │
    /// // ├─────────────┬─────────────┤
    /// // │   Cancel    │    Retry    │
    /// // ╰─────────────┴─────────────╯
    /// let message = "The Internet connection appears to be offline."
    /// ErrorPresentation(flowError: flowError)
    ///     .withMessage(verbatim: message)
    /// ```
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
        (lhs.title, lhs.subtitle, lhs.message, lhs.image, lhs.flowError.id)
        == (rhs.title, rhs.subtitle, rhs.message, rhs.image, rhs.flowError.id)
    }
}

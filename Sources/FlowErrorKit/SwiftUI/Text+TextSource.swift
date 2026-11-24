import SwiftUI

extension Text {
    /// Creates a text view that displays a text source.
    ///
    /// Localized text sources are localized according to the `locale`
    /// environment value. Verbatim text sources are displayed as is.
    ///
    /// For example:
    ///
    /// ```swift
    /// struct ErrorBanner: View {
    ///     var errorPresentation: ErrorPresentation
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Text(errorPresentation.title).bold()
    ///             if let subtitle = errorPresentation.subtitle {
    ///                 Text(subtitle)
    ///             }
    ///             if let message = errorPresentation.message {
    ///                 Text(message)
    ///             }
    ///             #if DEBUG
    ///             // Help developers see what went wrong.
    ///             Text(verbatim: "DEBUG: \(errorPresentation.flowError.error)")
    ///             #endif
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - parameter source: The text source to display.
    public init(_ source: TextSource) {
        switch source.impl {
        case let .verbatim(string):
            self.init(verbatim: string)
        case let .localizedStringKey(key):
            self.init(key)
        case let .localizedStringResource(resource):
            self.init(resource)
        }
    }
}

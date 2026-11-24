import SwiftUI

/// A localized or verbatim piece of text, such as an error title, an
/// error message, or the title of an error action.
///
/// FlowErrorKit creates text sources from the strings you provide to
/// its APIs. To display a text source, use ``SwiftUICore/Text/init(_:)``.
///
/// ## Topics
///
/// ### Displaying Text Sources
///
/// - ``SwiftUICore/Text/init(_:)``
/// - ``SwiftUICore/View/alert(_:item:actions:message:)``
public struct TextSource: Equatable, ~Sendable {
    // TextSource and Impl are ~Sendable because of LocalizedStringKey.
    
    enum Impl: Equatable, ~Sendable {
        case verbatim(String)
        case localizedStringKey(LocalizedStringKey)
        case localizedStringResource(LocalizedStringResource)
    }
    
    var impl: Impl
    
    static func verbatim(
        _ string: some StringProtocol
    ) -> Self {
        TextSource(impl: .verbatim(String(string)))
    }
    
    static func localizedStringKey(
        _ key: LocalizedStringKey
    ) -> Self {
        TextSource(impl: .localizedStringKey(key))
    }
    
    static func localizedStringResource(
        _ resource: LocalizedStringResource
    ) -> Self {
        TextSource(impl: .localizedStringResource(resource))
    }
}

extension TextSource {
    var isPresent: Bool {
        presence != nil
    }
    
    var presence: TextSource? {
        switch impl {
        case .verbatim(let string):
            if let presence = string.presence {
                return .verbatim(presence)
            } else {
                return nil
            }
        case .localizedStringKey:
            return self
        case .localizedStringResource:
            return self
        }
    }
}

extension TextSource? {
    var isPresent: Bool {
        presence != nil
    }
    
    var presence: TextSource? {
        self?.presence
    }
}

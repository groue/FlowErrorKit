import Foundation
import SwiftUI

/// A value that holds localized or non localized text.
public struct TextContent: Equatable {
    fileprivate enum Kind: Equatable {
        case verbatim(String)
        case resource(LocalizedStringResource)
    }
    
    fileprivate var kind: Kind
    
    static func verbatim(_ text: String) -> Self {
        self.init(kind: .verbatim(text))
    }
    
    static func resource(_ text: LocalizedStringResource) -> Self {
        self.init(kind: .resource(text))
    }
}

// MARK: - Format

extension TextContent {
    public struct FormatStyle: Foundation.FormatStyle {
        var locale = Locale.current
        
        public init() { }
        
        public func format(_ value: TextContent) -> String {
            switch value.kind {
            case .verbatim(let string):
                return string
            case .resource(var resource):
                resource.locale = locale
                return String(localized: resource)
            }
        }
        
        public func locale(_ locale: Locale) -> Self {
            var result = self
            result.locale = locale
            return result
        }
    }
}

extension FormatStyle where Self == TextContent.FormatStyle {
    public static var text: TextContent.FormatStyle { .init() }
}

extension TextContent {
    public func formatted<F>(_ format: F) -> F.FormatOutput
    where F: Foundation.FormatStyle, F.FormatInput == Self
    {
        format.format(self)
    }
}

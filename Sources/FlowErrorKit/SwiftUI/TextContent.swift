import Foundation
import SwiftUI

/// Holds localized or non localized text.
enum TextContent: Equatable {
    case verbatim(String)
    case resource(LocalizedStringResource)
}

extension Text {
    init(_ content: TextContent) {
        switch content {
        case .verbatim(let title):
            self.init(title)
        case .resource(let title):
            self.init(title)
        }
    }
}

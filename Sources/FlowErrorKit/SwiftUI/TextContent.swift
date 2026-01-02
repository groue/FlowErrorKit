import Foundation

enum TextContent: Equatable {
    case verbatim(String)
    case resource(LocalizedStringResource)
}

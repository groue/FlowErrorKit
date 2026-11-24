@testable import FlowErrorKit

extension TextSource {
    /// Whether the text source was created from a `LocalizedStringKey`.
    ///
    /// Use this property instead of an equality check when the key
    /// contains interpolations.
    var isLocalizedStringKey: Bool {
        if case .localizedStringKey = impl { true } else { false }
    }
}

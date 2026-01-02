import SwiftUI

/// A `CancelErrorAction` defines a button in an error alert displayed
/// by `FlowErrorKit`.
public struct CancelErrorAction {
    let title: TextContent?
    
    // MUST NOT BE PUBLIC, because actions MUST be run by `FlowError`.
    /// The function called when the user selects the action.
    let perform: @MainActor (CancelErrorReason) -> Void
    
    /// The customized title for the cancel action, if any, for the given locale.
    public func title(locale: Locale = .current) -> String? {
        switch title {
        case .none:
            return nil
        case .verbatim(let title):
            return title
        case .resource(var title):
            title.locale = locale
            return String(localized: title)
        }
    }
}

extension Text {
    /// Creates a text view that displays the title of the cancel action, if any.
    public init?(_ cancelAction: CancelErrorAction) {
        guard let title = cancelAction.title else {
            return nil
        }
        self.init(title)
    }
}

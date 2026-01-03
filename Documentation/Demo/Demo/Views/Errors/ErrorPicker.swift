import Foundation
import SwiftUI

struct ErrorPicker<Label: View>: View {
    enum ErrorItem {
        case URLError_notConnectedToInternet
        case APIError_unauthorized
        case APIError_forbidden
    }
    
    @Binding private var selection: Error?
    @State private var errorItem: ErrorItem?
    private var availableErrors: [ErrorItem]
    private var label: Label
    
    init(
        selection: Binding<Error?>,
        availableErrors: [ErrorItem],
        @ViewBuilder label: () -> Label = { Text("Error") }
    ) {
        self._selection = selection
        self.availableErrors = availableErrors
        self.label = label()
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        availableErrors: [ErrorItem],
        selection: Binding<Error?>
    ) where Label == Text {
        self.init(selection: selection, availableErrors: availableErrors) {
            Text(titleKey)
        }
    }
    
    var body: some View {
        Picker(selection: $errorItem) {
            Text("No Error").tag(Optional<ErrorItem>.none)
            
            ForEach(availableErrors, id: \.self) { errorItem in
                Text(errorItem.localizedDescription).tag(Optional<ErrorItem>.some(errorItem))
            }
        } label: {
            label
        }
        .onChange(of: errorItem, initial: true) {
            selection = errorItem?.error
        }
        .onChange(of: (selection == nil), initial: true) {
            if selection == nil {
                selection = nil
            }
        }
    }
}

extension ErrorPicker.ErrorItem {
    var localizedDescription: LocalizedStringKey {
        switch self {
        case .URLError_notConnectedToInternet:
            return "Airplane Mode"
        case .APIError_unauthorized:
            return "HTTP 401 (Unauthorized)"
        case .APIError_forbidden:
            return "HTTP 403 (Forbidden)"
        }
    }
    
    var error: Error {
        switch self {
        case .URLError_notConnectedToInternet:
            return URLError(.notConnectedToInternet, userInfo: [
                NSLocalizedDescriptionKey: String(localized: "The Internet connection appears to be offline."),
            ])
        case .APIError_unauthorized:
            return APIError.unauthorized
        case .APIError_forbidden:
            return APIError.forbidden
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var error: Error?
    
    List {
        ErrorPicker(selection: $error, availableErrors: [
            .URLError_notConnectedToInternet,
            .APIError_unauthorized,
            .APIError_forbidden,
        ])
    }
}

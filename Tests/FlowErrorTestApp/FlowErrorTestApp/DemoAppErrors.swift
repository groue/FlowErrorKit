import Foundation

/// An error that is ignored
struct IgnoredError: Error { }

/// An error that can only be fixed in the Settings app.
struct PermissionError: LocalizedError {
    var errorDescription: String {
        "Please allow this demo app to access your deepest thoughts."
    }
}

/// An error that can be repaired with a specific action.
struct CodeSigningError: LocalizedError {
    var errorDescription: String {
        "Code Signing requires a development team."
    }
}

/// An error that has consequences on the app state.
struct ExpiredSessionError: Error { }

/// An error that displays its localized message.
struct VerbatimError: LocalizedError {
    var errorDescription: String
}

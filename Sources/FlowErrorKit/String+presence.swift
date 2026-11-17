import Foundation

extension StringProtocol {
    /// Returns true if the string contains some non-whitespace character.
    ///
    /// For example:
    ///
    /// ```swift
    /// "".isPresent      // false
    /// " ".isPresent     // false
    /// "foo".isPresent   // true
    /// " foo ".isPresent // true
    /// ```
    var isPresent: Bool {
        presence != nil
    }
    
    /// Returns a trimmed string that contains some non-whitespace character,
    /// or nil.
    ///
    /// For example:
    ///
    /// ```swift
    /// "".presence      // nil
    /// " ".presence     // nil
    /// "foo".presence   // "foo"
    /// " foo ".presence // "foo"
    /// ```
    var presence: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return nil
        }
        return trimmed
    }
}

extension Optional where Wrapped: StringProtocol {
    /// Returns true if the optional string is not nil and contains some
    /// non-whitespace character.
    ///
    /// For example:
    ///
    /// ```swift
    /// nil.isPresent     // false
    /// "".isPresent      // false
    /// " ".isPresent     // false
    /// "foo".isPresent   // true
    /// " foo ".isPresent // true
    /// ```
    var isPresent: Bool {
        presence != nil
    }
    
    /// Returns a trimmed string that contains some non-whitespace character,
    /// or nil.
    ///
    /// For example:
    ///
    /// ```swift
    /// nil.presence     // nil
    /// "".presence      // nil
    /// " ".presence     // nil
    /// "foo".presence   // "foo"
    /// " foo ".presence // "foo"
    /// ```
    var presence: String? {
        self?.presence
    }
}

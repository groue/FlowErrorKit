import Foundation

// Use `String.LocalizationValue` instead of `LocalizedStringResource`, because:
//
// > [...] `LocalizedStringResource` appears to [...] use the current locale
// > as a substitute for language.
//
// See <https://levelup.gitconnected.com/ios-localization-localizedstringresource-vs-localizedstringkey-vs-string-56cb519cf098>
extension String.LocalizationValue {
    /// The title of a "Cancel" button.
    static let cancel: Self = "Cancel"
    
    /// The title of an "OK" button.
    static let ok: Self = "OK"
    
    /// The title of a "Retry" button.
    static let retry: Self = "Retry"
    
    /// The default generic error title.
    static let defaultErrorTitle: Self = "An Error Occurred"
}

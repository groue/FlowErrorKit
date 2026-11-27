# Release Notes

All notable changes to this project will be documented in this file.

## 0.2.0

Released November 27, 2026

- **Breaking change**: `presentError(_:with:)` no longer accepts a binding to an `ErrorPresentation`. Use the new `errorPresentationView` presenter instead, which replaces the modified view with an `ErrorPresentationView`: `.presentError($flowError, with: .errorPresentationView)`. To customize the error view, use `.presentError($flowError, with: .errorPresentationView { errorPresentation in ... })`.

## 0.1.0

Released November 26, 2026

Initial release of FlowErrorKit, an error handling library for SwiftUI apps.

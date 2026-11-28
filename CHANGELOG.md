# Release Notes

All notable changes to this project will be documented in this file.

## 0.3.2

Released November 28, 2026

- **Fix**: The `alert` presenter discards the presented flow error when the presenting view disappears while the alert is on screen. Its `onCancel` closure runs with the `.presentationCancelled` reason, and its `finally` closure runs. Before, neither closure ran.
- Documentation: flow error handlers must not add code with `onCancel` or `finally`, because this code is not guaranteed to run.

## 0.3.1

Released November 28, 2026

- `FlowError.discard(_:)` defaults its reason to `.presentationCancelled`: `flowError.discard()`.
- Documentation improvements.

## 0.3.0

Released November 27, 2026

- **Breaking change**: `ErrorPresentation` replaces its `systemImage: String` property with `image: Image`, and `defaultSystemImage` with `defaultImage`. Initializers keep their `systemImage:` parameter, and accept an `Image` as well: `ErrorPresentation(flowError: flowError, image: Image(.networkError))`.
- New `ErrorPresentationLabel`, `ErrorPresentationDescription`, and `ErrorPresentationActions` views, which make it possible to further refine the presentation of errors.

## 0.2.0

Released November 27, 2026

- **Breaking change**: `presentError(_:with:)` no longer accepts a binding to an `ErrorPresentation`. Use the new `errorPresentationView` presenter instead, which replaces the modified view with an `ErrorPresentationView`: `.presentError($flowError, with: .errorPresentationView)`. To customize the error view, use `.presentError($flowError, with: .errorPresentationView { errorPresentation in ... })`.

## 0.1.0

Released November 26, 2026

Initial release of FlowErrorKit, an error handling library for SwiftUI apps.

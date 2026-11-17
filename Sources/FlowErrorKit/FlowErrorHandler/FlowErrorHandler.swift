// See documentation in FlowErrorHandler.md.
@MainActor public protocol FlowErrorHandler {
    /// Returns how a flow error should be handled.
    ///
    /// See ``FlowErrorHandling`` for the available options.
    /// Generally speaking:
    ///
    /// - Return ``FlowErrorHandling/pass(_:)`` for unknown errors.
    /// - Return ``FlowErrorHandling/cancel`` when an error must not be
    ///   presented to the application user.
    /// - Otherwise, return ``FlowErrorHandling/present(_:)``.
    ///
    /// When presenting an unrecoverable error, remove the retry action
    /// with the ``FlowError/droppingRetryAction()`` `FlowError` modifier.
    /// See the `CocoaErrorHandler` sample code below.
    ///
    /// When presenting an error that needs a specific recovery action, use
    /// the ``FlowError/appendingAction(_:)`` `FlowError`
    /// modifier. See the `CLErrorHandler` sample code below.
    ///
    /// Pass underlying errors to the next error handler with the
    /// ``FlowError/withError(_:)`` `FlowError` modifier. See the
    /// `AFErrorHandler` sample code below for an example.
    ///
    /// The `CocoaErrorHandler` sample code:
    ///
    /// ```swift
    /// import FlowErrorKit
    /// import Foundation
    ///
    /// // Handles CocoaError.
    /// struct CocoaErrorHandler: FlowErrorHandler {
    ///     func handle(_ flowError: FlowError) -> FlowErrorHandling {
    ///         guard let error = flowError.error as? CocoaError else {
    ///             // Not a CocoaError: pass to the next error handler.
    ///             return .pass(flowError)
    ///         }
    ///
    ///         switch error.code {
    ///         case .userCancelled:
    ///             // <https://developer.apple.com/documentation/foundation/nsusercancellederror-swift.var>
    ///             // > This code is for errors that do not require a dialog
    ///             // > displayed and might be candidates for special-casing.
    ///             //
    ///             // Don't present the error.
    ///             return .cancel
    ///
    ///         case CocoaError.Code(rawValue: 3010):
    ///             // "remote notifications are not supported in the simulator"
    ///             // The localized message must be shown so that the developer
    ///             // understands what's wrong.
    ///             return .present(ErrorPresentation(
    ///                 title: error.localizedDescription,
    ///                 flowError: flowError.droppingRetryAction()))
    ///
    ///         default:
    ///             // Present a generic redacted error, because most CocoaErrors
    ///             // have an English or technical message that is not suitable for
    ///             // user display.
    ///             return .present(ErrorPresentation(flowError: flowError))
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// The `CLErrorHandler` sample code:
    ///
    /// ```swift
    /// import CoreLocation
    /// import FlowErrorKit
    /// import UIKit
    ///
    /// // Handles CoreLocation errors.
    /// struct CLErrorHandler: FlowErrorHandler {
    ///     func handle(_ flowError: FlowError) -> FlowErrorHandling {
    ///         guard let error = flowError.error as? CLError else {
    ///             // Not a CLError: pass to the next error handler.
    ///             return .pass(flowError)
    ///         }
    ///
    ///         switch error {
    ///         case CLError.denied:
    ///             // Denied error is not recoverable: drop the retry action, and
    ///             // let the user grant the required permissions.
    ///             let presentedFlowError = flowError
    ///                 .droppingRetryAction()
    ///                 .appendingAction(String(localized: "Open Settings")) {
    ///                     if let url = URL(string: UIApplication.openSettingsURLString) {
    ///                         UIApplication.shared.open(url)
    ///                     }
    ///                 }
    ///
    ///             return .present(ErrorPresentation(
    ///                 title: String(localized: "Permission Required"),
    ///                 message: String(localized: "Please grant access to your location in the Settings application."),
    ///                 flowError: presentedFlowError))
    ///
    ///         case CLError.geocodeCanceled:
    ///             // Don't present this error
    ///             return .cancel
    ///
    ///         default:
    ///             return .present(ErrorPresentation(
    ///                 message: error.localizedDescription,
    ///                 flowError: flowError))
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// The `AFErrorHandler` sample code:
    ///
    /// ```swift
    /// import Alamofire
    /// import FlowErrorKit
    ///
    /// // Handles Alamofire errors.
    /// struct AFErrorHandler: FlowErrorHandler {
    ///     func handle(_ flowError: FlowError) -> FlowErrorHandling {
    ///         guard let error = flowError.error as? AFError else {
    ///             // Not an AFError: pass to the next error handler.
    ///             return .pass(flowError)
    ///         }
    ///
    ///         switch error {
    ///         case .explicitlyCancelled:
    ///             // Don't present the error
    ///             return .cancel
    ///
    ///         default:
    ///             if let underlyingError = error.underlyingError {
    ///                 // Pass the underlying error to the next error handler.
    ///                 return .pass(flowError.withError(underlyingError))
    ///             } else {
    ///                 // Present a generic redacted error.
    ///                 return .present(ErrorPresentation(flowError: flowError))
    ///             }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: Don't invoke any action of the flow error from this method.
    /// The cancel action is automatically performed when you return
    /// ``FlowErrorHandling/cancel``, and the user will select their desired
    /// action when you return ``FlowErrorHandling/present(_:)``.
    func handle(_ flowError: FlowError) -> FlowErrorHandling
}

/// `FlowErrorHandling` specifies how a flow error should be handled.
///
/// You return a `FlowErrorHandling` from ``FlowErrorHandler/handle(_:)``.
public enum FlowErrorHandling {
    /// Pass the flow error to the next error handler in the chain of flow
    /// error handlers (see ``FlowErrorHandler``).
    ///
    /// A flow error can be transformed before it is passed to the next
    /// handler: see ``FlowErrorHandler/handle(_:)`` for
    /// some examples.
    case pass(FlowError)
    
    /// Don't present the error, and stop error handling. Remaining error
    /// handlers in the chain are ignored. The `onCancel` callback of the
    /// flow error is performed, with the
    /// ``ErrorCancelReason/presentationCancelled`` reason.
    case cancel
    
    /// Present the error to the user, with the specified presentation.
    ///
    /// A flow error can be transformed before it is presented:
    /// see ``FlowErrorHandler/handle(_:)`` for some examples.
    case present(ErrorPresentation)
}

import Foundation
import IssueReporting
import Synchronization

// See documentation in FlowError.md.
@MainActor public struct FlowError: Identifiable {
    /// An execution token helps a `FlowError` make sure that at most one error
    /// action is run.
    @MainActor private class ExecutionToken: CustomStringConvertible {
        // Mutex is only used for nonisolated CustomStringConvertible conformance.
        private let isExecutedMutex = Mutex(false)
        private let allowMultipleActionExecutions: Bool
        
        nonisolated var description: String {
            isExecutedMutex.withLock { isExecuted in
                "<\(ObjectIdentifier(self)) executed: \(isExecuted)>"
            }
        }
        
        init(allowMultipleActionExecutions: Bool) {
            self.allowMultipleActionExecutions = allowMultipleActionExecutions
        }
        
        /// Executes the provided closure.
        func execute(_ action: () -> Void) {
            isExecutedMutex.withLock { isExecuted in
                if isExecuted && allowMultipleActionExecutions == false {
                    reportIssue("""
                        Multiple FlowError actions executed.
                        
                        This might be unexpected by the code that created the \
                        FlowError in the first place.
                        
                        To fix this, either update the user interface so that \
                        a single action is executed, or set the \
                        allowMultipleActionExecutions flag when the FlowError \
                        is created.
                        
                        For example, present the flow error with an alert:
                        
                          // Presenting the error with an alert guarantees
                          // single action execution
                          ContentView().presentError($flowError, with: .alert)
                        
                        Alternatively:
                        
                          // Declare that action closures can be executed
                          // multiple times
                          flowError = FlowError(
                            error: error,
                            allowMultipleActionExecutions: true)
                          .onCancel { _ in /* may be executed multiple times */ }
                          .onRetry { /* may be executed multiple times */ }
                          .finally { /* may be executed multiple times */ }
                        """)
                }
                
                isExecuted = true
            }
            
            action()
        }
        
        /// Executes the provided closure unless an action was already
        /// performed.
        ///
        /// - Returns: Whether the closure was executed.
        @discardableResult
        func executeUnlessExecuted(_ action: () -> Void) -> Bool {
            let shouldRun = isExecutedMutex.withLock { isExecuted in
                if isExecuted {
                    return false
                } else {
                    isExecuted = true
                    return true
                }
            }
            
            if shouldRun {
                action()
                return true
            } else {
                return false
            }
        }
    }
    
    private struct CancelAction {
        var title: String?
        var perform: @MainActor (ErrorCancelReason) -> Void
    }
    
    /// The identifier of the `FlowError` identifies the creation of the
    /// `FlowError` instance from a particular error.
    ///
    /// When two `FlowError` instances share the same id, they originate
    /// from the same error.
    ///
    /// For example:
    ///
    /// ```swift
    /// let flowError = FlowError(error: error)
    /// let other = FlowError(error: otherError)
    /// let derived = flowError.onRetry { ... }
    /// flowError.id = other.id   // false
    /// flowError.id = derived.id // true
    /// ```
    nonisolated public var id: ObjectIdentifier {
        ObjectIdentifier(executionToken)
    }
    
    /// The caught error.
    public private(set) var error: any Error
    
    /// A customized generic error title.
    ///
    /// When set, it replaces the default "An Error Occurred" title. If an
    /// ``ErrorPresentation`` is created with an explicit title, this
    /// redacted title has priority, and the presentation title is displayed
    /// as a plain message.
    ///
    /// See ``withRedactedTitle(_:)``.
    public private(set) var redactedTitle: String?
    
    /// The optional cancel action.
    ///
    /// To execute the cancel action, see ``performCancelAction()``
    /// and ``discard(_:)``.
    private var cancelAction: CancelAction?
    
    /// The customized title for buttons that perform the cancel action.
    public var cancelTitle: String? {
        cancelAction?.title
    }
    
    /// The optional retry action, for recoverable errors.
    ///
    /// To execute the retry action, use ``performAction(_:)``.
    ///
    /// For more information about recoverable errors,
    /// see ``FlowErrorHandler/handle(_:)``.
    public private(set) var retryAction: ErrorAction?
    
    /// The supplementary actions.
    ///
    /// To execute those actions, use ``performAction(_:)``.
    public private(set) var supplementaryActions: [ErrorAction]
    
    /// A closure to run at the end of all error actions.
    private(set) var finally: (@MainActor () -> Void)?
    
    /// `executionToken` makes sure at most one error action is run.
    ///
    /// The same token is shared between one `FlowError` instance and all
    /// instances derived from it (with methods such as
    /// ``droppingRetryAction()`` or ``withError(_:)``). This allows error
    /// handlers to build new, altered `FlowError` instances, while preserving
    /// the guarantee that only one action will ever be executed:
    ///
    /// 1. The view model creates a FlowError (FlowError #1)
    /// 2. The FlowError is sent to the SwiftUI view
    /// 3. Error handlers can alter the FlowError, and build FlowError #2,
    ///    FlowError #3, etc.
    /// 4. FlowError #4 is presented.
    /// 5. Meanwhile, the view model still holds an instance of FlowError #1.
    ///
    /// Because FlowError #1, #2, #3 and #4 all share the same execution token,
    /// executing an action from FlowError #4 prevents FlowError #1 from
    /// executing another. And the reverse is true as well.
    ///
    /// The token is checked, and set, in the `execute(_:)` and
    /// `executeUnlessExecuted(_:)` methods.
    private let executionToken: ExecutionToken
    
    /// Creates a `FlowError` from an error.
    ///
    /// For example:
    ///
    /// ```swift
    /// // MyViewModel.swift
    /// import FlowErrorKit
    ///
    /// final class MyViewModel: ObservableObject {
    ///     @Published var flowError: FlowError?
    ///
    ///     func performSomeAction() {
    ///         do {
    ///             try failableMethod()
    ///         } catch {
    ///             // Turn the error into a FlowError
    ///             flowError = FlowError(error: error)
    ///                 .onCancel { ... }
    ///                 .onRetry(performSomeAction)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - parameters:
    ///     - error: The caught error.
    ///     - allowMultipleActionExecutions: The default is false. When
    ///       true, several error actions can be executed, and the `finally`
    ///       closure can run several times. You might need to set this
    ///       flag in some scenarios, otherwise the user might not be able
    ///       to select an action multiple times from an
    ///       `ErrorPresentationView` (such as an "Open Settings"
    ///       supplementary action).
    public init(
        error: any Error,
        allowMultipleActionExecutions: Bool = false)
    {
        self.error = error
        self.supplementaryActions = []
        self.executionToken = ExecutionToken(allowMultipleActionExecutions: allowMultipleActionExecutions)
    }
}

extension FlowError: CustomStringConvertible {
    nonisolated public var description: String {
        "<FlowError id: \(executionToken) error: \(error)>"
    }
}

// MARK: - Performing Actions

extension FlowError {
    /// Performs the specified action, followed by the `finally` closure.
    ///
    /// When the action is a supplementary action, the cancel action is
    /// run first, with the ``ErrorCancelReason/supplementaryActionPerformed``
    /// reason.
    ///
    /// Unless the flow error was created with the
    /// `allowMultipleActionExecutions` flag, a test failure is reported if
    /// an action was already performed.
    ///
    /// - precondition: The action argument must be available in the
    ///   flow error, as the retry action, or a supplementary action.
    public func performAction(_ action: ErrorAction) {
        precondition({
            var knownIds = Set(supplementaryActions.map(\.id))
            if let retryAction {
                knownIds.insert(retryAction.id)
            }
            return knownIds.contains(action.id)
        }(), "Action must be available in the FlowError")
        
        executionToken.execute {
            if action.id != retryAction?.id {
                // We're executing a supplementary action.
                cancelAction?.perform(.supplementaryActionPerformed)
            }
            action.perform()
            finally?()
        }
    }
    
    /// Unconditionally performs the cancel action, with the
    /// ``ErrorCancelReason/userCancelled`` reason, followed by the
    /// `finally` closure.
    ///
    /// Unless the flow error was created with the
    /// `allowMultipleActionExecutions` flag, a test failure is reported if
    /// an action was already performed.
    ///
    /// When a flow error is programmatically discarded, prefer the
    /// ``discard(_:)`` method.
    public func performCancelAction() {
        executionToken.execute {
            cancelAction?.perform(.userCancelled)
            finally?()
        }
    }
    
    /// Performs the cancel action, followed by the `finally` closure,
    /// unless an action was previously executed.
    ///
    /// When executing the action from an explicit "Cancel" button, prefer
    /// the ``performCancelAction()`` method.
    ///
    /// - parameter reason: The reason why the cancel action is run.
    ///
    /// - Returns: Whether the cancel action was executed.
    @discardableResult
    public func discard(_ reason: ErrorCancelReason) -> Bool {
        executionToken.executeUnlessExecuted {
            cancelAction?.perform(reason)
            finally?()
        }
    }
}

// MARK: - Operators

extension FlowError {
    // Design note: some view models register IMPORTANT clean up code in their
    // cancellation handler. No `FlowError` method should remove it:
    //
    // - Do not define a `droppingCancelAction()` method.
    // - Don't turn the `cancelAction` property into a mutable one.
    // - Keep `FlowError` immutable. It is a class, but it has value semantics.
    // - Etc.
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled.
    ///
    /// If the flow error already has a cancel action, both closures are
    /// run, the existing one first.
    ///
    /// - parameter title: The title of the button that dismisses the
    ///   error. If nil, the existing title is preserved. By default, the
    ///   button is titled "OK", "Close", or "Cancel", depending on the
    ///   presentation and the available actions.
    /// - parameter perform: A closure called when the user dismisses the
    ///   error alert with the "Cancel" button, and, generally, for whatever
    ///   reason given as an argument (see ``ErrorCancelReason``).
    public func onCancel(
        _ title: String? = nil,
        _ perform: @escaping @MainActor (_ cancelReason: ErrorCancelReason) -> Void
    ) -> FlowError {
        let oldCancelAction = self.cancelAction
        var result = self
        result.cancelAction = CancelAction(
            title: title ?? oldCancelAction?.title,
            perform: { cancelReason in
                oldCancelAction?.perform(cancelReason)
                perform(cancelReason)
            })
        return result
    }
    
    // This overload is necessary because a default argument for title is
    // not enough for `FlowError(...).onRetry(function)` to compile.
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried.
    ///
    /// If the flow error already has a retry action, both closures are
    /// run, the existing one first, and the existing title is preserved.
    /// Otherwise, the button is titled "Retry".
    ///
    /// - parameter perform: A closure called when the user hits the
    ///   "Retry" button.
    public func onRetry(
        _ perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(
            retryAction?.title ?? String(localized: .retry, bundle: .module),
            perform)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried.
    ///
    /// If the flow error already has a retry action, both closures are
    /// run, the existing one first.
    ///
    /// - parameter title: The title of the "Retry" button.
    /// - parameter perform: A closure called when the user hits the
    ///   "Retry" button.
    public func onRetry(
        _ title: String,
        _ perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        let oldRetryAction = self.retryAction
        var result = self
        result.retryAction = ErrorAction(title: title) {
            oldRetryAction?.perform()
            perform()
        }
        return result
    }
    
    /// Returns a flow error without any retry action (useful for
    /// unrecoverable errors).
    ///
    /// Use this method for unrecoverable errors, in order to prevent the
    /// user from retrying the failed action.
    public func droppingRetryAction() -> FlowError {
        var result = self
        result.retryAction = nil
        return result
    }
    
    /// Returns a flow error with an extra supplementary action.
    ///
    /// This method is useful for permission denied errors: add an
    /// "Open Settings" action.
    ///
    /// If the user selects this action, the cancel action is run first,
    /// with the ``ErrorCancelReason/supplementaryActionPerformed`` reason.
    public func appendingAction(
        _ title: String,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(ErrorAction(
            title: title,
            role: role,
            perform: perform))
    }
    
    /// Returns a flow error with an extra supplementary action.
    ///
    /// This method is useful for permission denied errors: add an
    /// "Open Settings" action.
    ///
    /// If the user selects this action, the cancel action is run first,
    /// with the ``ErrorCancelReason/supplementaryActionPerformed`` reason.
    public func appendingAction(_ action: ErrorAction) -> FlowError {
        var result = self
        result.supplementaryActions = supplementaryActions + [action]
        return result
    }
    
    /// Returns a flow error that executes the provided closure after any
    /// error action has been performed.
    ///
    /// If the flow error already has a `finally` closure, both closures
    /// are run, the existing one first.
    ///
    /// - parameter perform: A closure to run at the end of all error
    ///   actions (cancel, retry, supplementary actions).
    public func finally(_ perform: @escaping @MainActor () -> Void) -> FlowError {
        let oldFinally = self.finally
        var result = self
        result.finally = {
            oldFinally?()
            perform()
        }
        return result
    }
    
    /// Returns a flow error with a customized generic error title.
    ///
    /// See ``redactedTitle`` for more information.
    public func withRedactedTitle(_ title: String) -> FlowError {
        var result = self
        result.redactedTitle = title
        return result
    }
    
    /// Returns a flow error with a different error (useful when unwrapping
    /// underlying errors).
    public func withError(_ error: any Error) -> FlowError {
        var result = self
        result.error = error
        return result
    }
}

// MARK: - ErrorCancelReason

/// The reason why the ``FlowError`` `onCancel` handler is invoked.
public enum ErrorCancelReason {
    /// The user has dismissed the error with the cancel button, or
    /// ``FlowError/performCancelAction()`` was called.
    case userCancelled
    
    /// The error was not presented to the user (for example, an error
    /// handler returned ``FlowErrorHandling/cancel``), or it was discarded
    /// due to a conflict with another error.
    case presentationCancelled
    
    /// The user has selected a supplementary action that was appended,
    /// before the error was presented, with
    /// ``FlowError/appendingAction(_:)``.
    ///
    /// Such a supplementary action can be an "Open Settings" action added
    /// by a ``FlowErrorHandler``, for example.
    case supplementaryActionPerformed
}

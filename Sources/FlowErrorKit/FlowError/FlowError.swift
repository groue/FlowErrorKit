import Foundation
import IssueReporting
import SwiftUI

// `FlowError` is a class, not a struct, for multiple reasons:
//
// - One instance of `FlowError` is considered as an "error event", with an
//   identity. Instances are created at specific points in time: when a view
//   model catches an error.
//
// - The identity of a `FlowError` helps integration with SwiftUI: instances can
//   be compared with `===`, and only trigger side effects when they change.
//   Comparison based on `Equatable` would be impossible because flow errors is
//   made of non-Equatable properties (error, closures, etc.)
//
// - `FlowError` has one shared mutable state, that makes sure at most one error
//   action is ever run (its `executionToken`).
//
// See documentation in FlowError.md.
@MainActor public final class FlowError {
    /// An execution token helps a `FlowError` makes sure that at most one error
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
                          .onCancel { /* may be executed multiple times */ },
                          .onRetry { /* may be executed multiple times */ },
                          .finally { /* may be executed multiple times */ })
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
    
    /// The caught error.
    public let error: any Error
    
    /// The name identifying the failed action.
    public var failedActionName: TextContent?
    
    /// The eventual cancel action.
    ///
    /// To execute the cancel action, see ``performCancelAction()``
    /// and ``discard(_:)``.
    public let cancelAction: CancelErrorAction?
    
    /// The eventual retry action, for recoverable errors.
    ///
    /// To execute the retry action, use ``performAction(_:)``.
    ///
    /// For more information about recoverable errors,
    /// see ``FlowErrorHandler/handle(_:)``.
    public let retryAction: ErrorAction?
    
    /// The supplementary actions.
    ///
    /// To execute those actions, use ``performAction(_:)``.
    public let supplementaryActions: [ErrorAction]
    
    /// A closure to run at the end of all error actions.
    private let finally: (@MainActor () -> Void)?
    
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
    /// 4. The FlowError #4 is presented.
    /// 5. Meanwhile, the view model still holds an instance of FlowError #1.
    ///
    /// Because FlowError #1, #2, #3 and #4 all share the same execution token,
    /// executing an action from FlowError #4 prevents FlowError #1 from
    /// executing another. And the reverse is true as well.
    ///
    /// The token is checked, and set, in  the `execute(_:)` method.
    private let executionToken: ExecutionToken
    
    private init(
        error: any Error,
        failedActionName: TextContent?,
        cancelAction: CancelErrorAction?,
        retryAction: ErrorAction?,
        supplementaryActions: [ErrorAction],
        finally: (@MainActor () -> Void)?,
        executionToken: ExecutionToken)
    {
        self.error = error
        self.failedActionName = failedActionName
        self.cancelAction = cancelAction
        self.retryAction = retryAction
        self.supplementaryActions = supplementaryActions
        self.finally = finally
        self.executionToken = executionToken
    }
    
    /// Creates a `FlowError` from an error.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    ///
    /// struct MyView: View {
    ///     @State var flowError: FlowError?
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
    public convenience init(
        error: any Error,
        allowMultipleActionExecutions: Bool = false)
    {
        let executionToken = ExecutionToken(allowMultipleActionExecutions: allowMultipleActionExecutions)
        
        self.init(
            error: error,
            failedActionName: nil,
            cancelAction: nil,
            retryAction: nil,
            supplementaryActions: [],
            finally: nil,
            executionToken: executionToken)
    }
    
    /// Returns whether both flow errors have caught the same error.
    public func isSameError(as flowError: FlowError) -> Bool {
        executionToken === flowError.executionToken
    }
}

extension FlowError: CustomStringConvertible {
    nonisolated public var description: String {
        "<FlowError identity: \(executionToken) error: \(error)>"
    }
}

// MARK: - Performing Actions

extension FlowError {
    /// Performs the specified action.
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
    
    /// Unconditionally performs the cancel action.
    ///
    /// When a flow error is programmatically discarded, prefer the
    /// ``discard(_:)`` method.
    public func performCancelAction() {
        executionToken.execute {
            cancelAction?.perform(.userCancelled)
            finally?()
        }
    }
    
    /// Performs the cancel action unless an action was previously executed.
    ///
    /// When executing the action from an explicit "Cancel" button, prefer
    /// the ``performCancelAction()`` method.
    ///
    /// - parameter reason: The reason why the cancel action is run.
    ///
    /// - Returns: Whether the cancel action was executed.
    @discardableResult
    public func discard(_ reason: CancelErrorReason) -> Bool {
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
    /// - parameter title: The title of the "Cancel" button.
    /// - parameter perform: A closure called when the user dismisses the
    ///   error alert with the "Cancel" button, and, generally, for whatever
    ///   reason given as an argument (see ``CancelErrorReason``).
    func onCancel(
        _ title: TextContent?,
        _ perform: @escaping @MainActor (_ cancelReason: CancelErrorReason) -> Void
    ) -> FlowError {
        let oldCancelAction = self.cancelAction
        return FlowError(
            error: self.error,
            failedActionName: self.failedActionName,
            cancelAction: CancelErrorAction(
                title: title ?? oldCancelAction?.title,
                perform: { cancelReason in
                    oldCancelAction?.perform(cancelReason)
                    perform(cancelReason)
                }),
            retryAction: self.retryAction,
            supplementaryActions: self.supplementaryActions,
            finally: self.finally,
            executionToken: self.executionToken)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled, with a title without localization.
    ///
    /// - parameter title: The title of the "Cancel" button.
    /// - parameter perform: A closure called when the user dismisses the
    ///   error alert with the "Cancel" button, and, generally, for whatever
    ///   reason given as an argument (see ``CancelErrorReason``).
    @_disfavoredOverload
    public func onCancel(
        _ title: String,
        _ perform: @escaping @MainActor (_ cancelReason: CancelErrorReason) -> Void
    ) -> FlowError {
        onCancel(.verbatim(title), perform)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled, with a title without localization.
    ///
    /// - parameter title: The title of the "Cancel" button.
    /// - parameter perform: A closure called when the user dismisses the
    ///   error alert with the "Cancel" button, and, generally, for whatever
    ///   reason given as an argument (see ``CancelErrorReason``).
    public func onCancel(
        verbatim title: String,
        _ perform: @escaping @MainActor (_ cancelReason: CancelErrorReason) -> Void
    ) -> FlowError {
        onCancel(.verbatim(title), perform)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled, with a localized title.
    ///
    /// - parameter title: The title of the "Cancel" button.
    /// - parameter perform: A closure called when the user dismisses the
    ///   error alert with the "Cancel" button, and, generally, for whatever
    ///   reason given as an argument (see ``CancelErrorReason``).
    public func onCancel(
        _ title: LocalizedStringResource? = nil,
        _ perform: @escaping @MainActor (_ cancelReason: CancelErrorReason) -> Void
    ) -> FlowError {
        onCancel(title.map { .resource($0) }, perform)
    }
    
    // This overload is necessary because a default argument for title is
    // not enough for `FlowError(...).onRetry(function)` to compile.
    /// Returns a flow error that executes the provided closure when the
    /// error is retried.
    ///
    /// - parameter perform: A closure called when the user hits the
    /// "Retry" button.
    public func onRetry(
        _ perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(
            retryAction?.title ?? .resource(.retry),
            perform)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried.
    ///
    /// - parameter title: The title of the "Retry" button.
    /// - parameter perform: A closure called when the user hits the
    /// "Retry" button.
    func onRetry(
        _ title: TextContent,
        _ perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        let oldRetryAction = self.retryAction
        return FlowError(
            error: self.error,
            failedActionName: self.failedActionName,
            cancelAction: self.cancelAction,
            retryAction: ErrorAction(title: title) {
                oldRetryAction?.perform()
                perform()
            },
            supplementaryActions: self.supplementaryActions,
            finally: self.finally,
            executionToken: self.executionToken) // share the execution token
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried, with a title without localization.
    ///
    /// - parameter title: The title of the "Retry" button.
    /// - parameter perform: A closure called when the user hits the
    /// "Retry" button.
    @_disfavoredOverload
    public func onRetry(
        _ title: String,
        _ perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(.verbatim(title), perform)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried, with a title without localization.
    ///
    /// - parameter title: The title of the "Retry" button.
    /// - parameter perform: A closure called when the user hits the
    /// "Retry" button.
    public func onRetry(
        verbatim title: String,
        _ perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(.verbatim(title), perform)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried, with a localized title.
    ///
    /// - parameter title: The title of the "Retry" button.
    /// - parameter perform: A closure called when the user hits the
    /// "Retry" button.
    public func onRetry(
        _ title: LocalizedStringResource,
        _ perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(TextContent.resource(title), perform)
    }
    
    /// Returns a flow error without any retry action (useful for
    /// unrecoverable errors).
    ///
    /// Use this method for unrecoverable errors, in order to prevent the
    /// user from retrying the failed action.
    public func droppingRetryAction() -> FlowError {
        FlowError(
            error: self.error,
            failedActionName: self.failedActionName,
            cancelAction: self.cancelAction,
            retryAction: nil,
            supplementaryActions: self.supplementaryActions,
            finally: self.finally,
            executionToken: self.executionToken) // share the execution token
    }
    
    /// Returns a flow error with an extra supplementary action, and a title
    /// without localization.
    ///
    /// This method is useful for permission denied errors: add an
    /// "Open Settings" action.
    ///
    /// If the user selects this action, the cancel action is run with reason
    /// ``CancelErrorReason/supplementaryActionPerformed``.
    @_disfavoredOverload
    public func appendingAction(
        _ title: String,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(ErrorAction(title, role: role, perform: perform))
    }
    
    /// Returns a flow error with an extra supplementary action, and a title
    /// without localization.
    ///
    /// This method is useful for permission denied errors: add an
    /// "Open Settings" action.
    ///
    /// If the user selects this action, the cancel action is run with reason
    /// ``CancelErrorReason/supplementaryActionPerformed``.
    public func appendingAction(
        verbatim title: String,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(ErrorAction(title, role: role, perform: perform))
    }
    
    /// Returns a flow error with an extra supplementary action, and a
    /// localized title.
    ///
    /// This method is useful for permission denied errors: add an
    /// "Open Settings" action.
    ///
    /// If the user selects this action, the cancel action is run with reason
    /// ``CancelErrorReason/supplementaryActionPerformed``.
    public func appendingAction(
        _ title: LocalizedStringResource,
        role: ErrorActionRole? = nil,
        perform: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(ErrorAction(title, role: role, perform: perform))
    }
    
    /// Returns a flow error with an extra supplementary action.
    ///
    /// This method is useful for permission denied errors: add an
    /// "Open Settings" action.
    ///
    /// If the user selects this action, the cancel action is run with reason
    /// ``CancelErrorReason/supplementaryActionPerformed``.
    public func appendingAction(_ action: ErrorAction) -> FlowError {
        return FlowError(
            error: self.error,
            failedActionName: self.failedActionName,
            cancelAction: self.cancelAction,
            retryAction: self.retryAction,
            supplementaryActions: self.supplementaryActions + [action],
            finally: self.finally,
            executionToken: self.executionToken) // share the execution token
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried.
    ///
    /// - parameter perform: A closure to run at the end of all error
    ///   actions (cancel, retry, other).
    public func finally(_ perform: @escaping @MainActor () -> Void) -> FlowError {
        let oldFinally = self.finally
        return FlowError(
            error: self.error,
            failedActionName: self.failedActionName,
            cancelAction: self.cancelAction,
            retryAction: self.retryAction,
            supplementaryActions: self.supplementaryActions,
            finally: {
                oldFinally?()
                perform()
            },
            executionToken: self.executionToken) // share the execution token
    }
    
    /// Sets the title of the flow error to a string without localization.
    @_disfavoredOverload
    public func withFailedActionName(_ title: String) -> FlowError {
        withFailedActionName(verbatim: title)
    }
    
    /// Sets the title of the flow error to a string without localization.
    public func withFailedActionName(verbatim title: String) -> FlowError {
        FlowError(
            error: self.error,
            failedActionName: .verbatim(title),
            cancelAction: self.cancelAction,
            retryAction: self.retryAction,
            supplementaryActions: self.supplementaryActions,
            finally: self.finally,
            executionToken: self.executionToken) // share the execution token
    }
    
    /// Sets the title of the flow error to a localized string.
    public func withFailedActionName(_ title: LocalizedStringResource) -> FlowError {
        FlowError(
            error: self.error,
            failedActionName: .resource(title),
            cancelAction: self.cancelAction,
            retryAction: self.retryAction,
            supplementaryActions: self.supplementaryActions,
            finally: self.finally,
            executionToken: self.executionToken) // share the execution token
    }

    /// Replaces the error (useful when unwrapping underlying errors).
    public func withError(_ error: any Error) -> FlowError {
        FlowError(
            error: error,
            failedActionName: self.failedActionName,
            cancelAction: self.cancelAction,
            retryAction: self.retryAction,
            supplementaryActions: self.supplementaryActions,
            finally: self.finally,
            executionToken: self.executionToken) // share the execution token
    }
}

// MARK: - CancelErrorReason

/// The reason why the ``FlowError`` `onCancel` handler is invoked.
public enum CancelErrorReason {
    /// The user has selected the Cancel button.
    case userCancelled
    
    /// The error was not presented to the user, or it was discarded due to
    /// a conflict with another error.
    case presentationCancelled
    
    /// The user has selected a supplementary action that was appended,
    /// before the error was presented, with
    /// ``FlowError/appendingAction(_:)``.
    ///
    /// Such a supplementary action can be an "Open Settings" action added
    /// by a ``FlowErrorHandler``, for example.
    case supplementaryActionPerformed
}

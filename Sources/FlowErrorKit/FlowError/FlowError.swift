import Foundation
import IssueReporting
import Observation
import SwiftUI

// See documentation in FlowError.md.
@MainActor public struct FlowError: Identifiable {
    @MainActor private struct CancelAction {
        var title: TextSource?
        private var action: @MainActor (ErrorCancelReason) -> Void
        
        init(
            title: TextSource?,
            action: @escaping @MainActor (ErrorCancelReason) -> Void
        ) {
            self.title = title
            self.action = action
        }
        
        func callAsFunction(_ reason: ErrorCancelReason) {
            action(reason)
        }
    }
    
    /// The identifier of the flow error.
    ///
    /// Each call to ``init(error:allowMultipleActionExecutions:)``
    /// creates a new identifier. The flow errors derived from a flow
    /// error, with methods such as ``onRetry(action:)`` or
    /// ``withError(_:)``, share its identifier.
    ///
    /// For example:
    ///
    /// ```swift
    /// let flowError = FlowError(error: error)
    /// let other = FlowError(error: error)
    /// let derived = flowError.withError(otherError)
    /// flowError.id == other.id   // false
    /// flowError.id == derived.id // true
    /// ```
    nonisolated public var id: ObjectIdentifier {
        ObjectIdentifier(executionToken)
    }
    
    /// The caught error.
    public private(set) var error: any Error
    
    /// An error title that describes the failed operation.
    ///
    /// To set the title, use ``withTitle(_:)-(LocalizedStringKey)``.
    public private(set) var title: TextSource?
    
    /// The optional cancel action.
    ///
    /// To set the cancel action, use ``onCancel(action:)``.
    ///
    /// To execute the cancel action, see ``performCancelAction()``
    /// and ``discard(_:)``.
    private var cancelAction: CancelAction?
    
    /// The customized title for buttons that perform the cancel action.
    ///
    /// To set the cancel title, use
    /// ``onCancel(_:action:)-(LocalizedStringKey,_)``.
    public var cancelTitle: TextSource? {
        cancelAction?.title
    }
    
    /// The optional retry action, for recoverable errors.
    ///
    /// To set the retry action, use ``onRetry(action:)``.
    ///
    /// To execute the retry action, use ``performAction(_:)``.
    ///
    /// Error handlers can remove the retry action of errors that
    /// retrying cannot fix (see <doc:FlowError#Error-Actions>).
    public private(set) var retryAction: ErrorAction?
    
    /// The supplementary actions.
    ///
    /// To add supplementary actions, use ``appendingAction(_:role:action:)-(LocalizedStringKey,_,_)``.
    ///
    /// To execute those actions, use ``performAction(_:)``.
    public private(set) var supplementaryActions: [ErrorAction]
    
    /// A closure to run at the end of all error actions.
    private(set) var finally: (@MainActor () -> Void)?
    
    /// An observable value indicating whether an error action can be
    /// performed.
    ///
    /// Check this property when you implement custom error presentation
    /// (see <doc:FlowErrorPresenter#Implementing-a-custom-presenter>),
    /// before letting the application user perform an action with
    /// ``performAction(_:)`` or ``performCancelAction()``. It becomes false
    /// once an action is performed, unless the flow error was created with
    /// the `allowMultipleActionExecutions` flag.
    ///
    /// If ``performAction(_:)`` or ``performCancelAction()`` is called
    /// when this property is false, the action is executed, but an issue is
    /// reported: a runtime warning when the app runs in the debugger, or a
    /// test failure in tests. This issue reveals a bug in the error
    /// presentation logic that needs to be addressed: at most one action
    /// should be executed for flow errors created without the
    /// `allowMultipleActionExecutions` flag.
    public var canPerformAction: Bool {
        executionToken.canExecute
    }
    
    /// `executionToken` makes sure at most one error action is run.
    ///
    /// The same token is shared between one `FlowError` instance and all
    /// instances derived from it (with methods such as
    /// ``droppingRetryAction()`` or ``withError(_:)``). This allows error
    /// handlers to build new, altered `FlowError` instances, while preserving
    /// the guarantee that only one action will ever be executed:
    ///
    /// 1. A SwiftUI view creates a FlowError (FlowError #1)
    /// 2. The FlowError is sent to the error presentation
    /// 3. Error handlers can alter the FlowError, and build FlowError #2,
    ///    FlowError #3, etc.
    /// 4. FlowError #4 is presented.
    /// 5. Meanwhile, the view still holds an instance of FlowError #1.
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
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// struct MyView: View {
    ///     @State private var flowError: FlowError?
    ///
    ///     var body: some View {
    ///         Button("Try Me", action: performSomeAction)
    ///             .presentError($flowError, with: .alert)
    ///     }
    ///
    ///     func performSomeAction() {
    ///         do {
    ///             try failableMethod()
    ///         } catch {
    ///             // Turn the error into a FlowError
    ///             flowError = FlowError(error: error)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - parameters:
    ///     - error: The caught error.
    ///     - allowMultipleActionExecutions: The default is false. When
    ///       true, several error actions can be executed, and the `finally`
    ///       closure can run several times. This is useful when the error
    ///       is displayed in an ``ErrorPresentationView``, and the user may
    ///       need to select an action again (see
    ///       ``FlowErrorPresenter/errorPresentationView``).
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
        "<FlowError id: \(id) error: \(error)>"
    }
}

/// An execution token helps a `FlowError` make sure that at most one error
/// action is run.
@MainActor @Observable private class ExecutionToken {
    // Observable
    private(set) var isExecuted = false
    
    var canExecute: Bool {
        !isExecuted || allowMultipleActionExecutions
    }
    
    private let allowMultipleActionExecutions: Bool
    
    init(allowMultipleActionExecutions: Bool) {
        self.allowMultipleActionExecutions = allowMultipleActionExecutions
    }
    
    /// Executes the provided closure.
    func execute(_ action: () -> Void) {
        if isExecuted && allowMultipleActionExecutions == false {
            reportIssue("""
                Multiple FlowError actions executed.
                
                This might be unexpected by the code that created the \
                FlowError in the first place.
                
                To fix this, either update the user interface so that \
                a single action can be executed, or set the \
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
        
        if !isExecuted { isExecuted = true }
        action()
    }
    
    /// Executes the provided closure unless an action was already
    /// performed.
    ///
    /// - Returns: Whether the closure was executed.
    @discardableResult
    func executeUnlessExecuted(_ action: () -> Void) -> Bool {
        if isExecuted {
            return false
        } else {
            isExecuted = true
            action()
            return true
        }
    }
}

// MARK: - Performing Actions

extension FlowError {
    /// Performs the specified action.
    ///
    /// Call this method when you implement custom error presentation
    /// (see <doc:FlowErrorPresenter#Implementing-a-custom-presenter>), in
    /// order to execute the retry action, or a supplementary action:
    ///
    /// ```swift
    /// if let retryAction = flowError.retryAction {
    ///     Button("Retry") {
    ///         flowError.performAction(retryAction)
    ///     }
    /// }
    /// ```
    ///
    /// It performs the specified action, followed by the `finally` closure.
    /// When the action is a supplementary action, the cancel action is
    /// run first, with the ``ErrorCancelReason/supplementaryActionPerformed``
    /// reason.
    ///
    /// If the ``canPerformAction`` property is false when this method is
    /// called, the action is executed, but an issue is reported: a runtime
    /// warning when the app runs in the debugger, or a test failure in
    /// tests. This issue reveals a bug in the error presentation logic that
    /// needs to be addressed: at most one action should be executed for
    /// flow errors created without the
    /// `allowMultipleActionExecutions` flag.
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
                cancelAction?(.supplementaryActionPerformed)
            }
            action()
            finally?()
        }
    }
    
    /// Performs the cancel action.
    ///
    /// Call this method when you implement custom error presentation
    /// (see <doc:FlowErrorPresenter#Implementing-a-custom-presenter>), in
    /// order to execute the cancel action when the application user taps
    /// a Cancel button:
    ///
    /// ```swift
    /// Button(role: .cancel) {
    ///     flowError.performCancelAction()
    /// }
    /// ```
    ///
    /// It performs the cancel action, with the
    /// ``ErrorCancelReason/userCancelled`` reason, followed by the
    /// `finally` closure.
    ///
    /// If the ``canPerformAction`` property is false when this method is
    /// called, the cancel action is executed, but an issue is reported: a
    /// runtime warning when the app runs in the debugger, or a test failure
    /// in tests. This issue reveals a bug in the error presentation logic that
    /// needs to be addressed: at most one action should be executed for
    /// flow errors created without the
    /// `allowMultipleActionExecutions` flag.
    ///
    /// When a flow error is programmatically discarded, prefer the
    /// ``discard(_:)`` method.
    public func performCancelAction() {
        executionToken.execute {
            cancelAction?(.userCancelled)
            finally?()
        }
    }
    
    /// Performs the cancel action, unless an action was
    /// previously executed.
    ///
    /// Call this method when you implement custom error presentation
    /// (see <doc:FlowErrorPresenter#Implementing-a-custom-presenter>), in
    /// order to complete the handling of a flow error without letting the
    /// application user choose an action:
    ///
    /// ```swift
    /// guard let errorPresentation else {
    ///     // Error can't be presented.
    ///     flowError.discard()
    ///     return
    /// }
    /// ```
    ///
    /// If an error action was already executed with
    /// ``performCancelAction()``, ``performAction(_:)``, or this `discard`
    /// method, nothing is done and the result is false. Otherwise, the
    /// cancel action is executed, followed by the `finally` closure, and
    /// the result is true.
    ///
    /// When executing the action from an explicit "Cancel" button, prefer
    /// the ``performCancelAction()`` method.
    ///
    /// - parameter reason: The reason why the cancel action is run.
    /// - Returns: Whether the cancel action was executed.
    @discardableResult
    public func discard(_ reason: ErrorCancelReason = .presentationCancelled) -> Bool {
        executionToken.executeUnlessExecuted {
            cancelAction?(reason)
            finally?()
        }
    }
}

// MARK: - Operators

extension FlowError {
    // Design note: some apps register IMPORTANT clean up code in their
    // cancellation handler. No `FlowError` method should remove it:
    //
    // - Do not define a `droppingCancelAction()` method.
    // - Don't make the `cancelAction` property publicly settable.
    // - Etc.
    
    func onCancel(
        titleSource: TextSource? = nil,
        action: @escaping @MainActor (_ cancelReason: ErrorCancelReason) -> Void
    ) -> FlowError {
        let oldCancelAction = self.cancelAction
        var result = self
        let title = titleSource ?? oldCancelAction?.title
        result.cancelAction = CancelAction(title: title) { cancelReason in
            oldCancelAction?(cancelReason)
            action(cancelReason)
        }
        return result
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled.
    ///
    /// If the flow error already has a cancel action, both closures are
    /// run, the existing one first, and the existing title is preserved.
    ///
    /// - parameter action: A closure called when the user dismisses
    ///   the error, and in the other situations described by
    ///   ``ErrorCancelReason``.
    public func onCancel(
        action: @escaping @MainActor (_ cancelReason: ErrorCancelReason) -> Void
    ) -> FlowError {
        onCancel(titleSource: nil, action: action)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled, with a customized title for the Cancel button
    /// that is not localized.
    ///
    /// If the flow error already has a cancel action, both closures are
    /// run, the existing one first, and the provided title replaces the
    /// existing one.
    ///
    /// - parameter title: The title of the "Cancel" button, displayed
    ///   without localization.
    /// - parameter action: A closure called when the user dismisses
    ///   the error, and in the other situations described by
    ///   ``ErrorCancelReason``.
    @_disfavoredOverload
    public func onCancel(
        _ title: some StringProtocol,
        action: @escaping @MainActor (_ cancelReason: ErrorCancelReason) -> Void
    ) -> FlowError {
        onCancel(titleSource: .verbatim(title), action: action)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled, with a customized title for the Cancel button.
    ///
    /// If the flow error already has a cancel action, both closures are
    /// run, the existing one first, and the provided title replaces the
    /// existing one.
    ///
    /// - parameter title: The localized title of the "Cancel" button.
    /// - parameter action: A closure called when the user dismisses
    ///   the error, and in the other situations described by
    ///   ``ErrorCancelReason``.
    public func onCancel(
        _ title: LocalizedStringKey,
        action: @escaping @MainActor (_ cancelReason: ErrorCancelReason) -> Void
    ) -> FlowError {
        onCancel(titleSource: .localizedStringKey(title), action: action)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled, with a customized title for the Cancel button.
    ///
    /// If the flow error already has a cancel action, both closures are
    /// run, the existing one first, and the provided title replaces the
    /// existing one.
    ///
    /// - parameter title: The localized title of the "Cancel" button.
    /// - parameter action: A closure called when the user dismisses
    ///   the error, and in the other situations described by
    ///   ``ErrorCancelReason``.
    @_disfavoredOverload
    public func onCancel(
        _ title: LocalizedStringResource,
        action: @escaping @MainActor (_ cancelReason: ErrorCancelReason) -> Void
    ) -> FlowError {
        onCancel(titleSource: .localizedStringResource(title), action: action)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is cancelled, with a customized title for the Cancel button
    /// that is not localized.
    ///
    /// If the flow error already has a cancel action, both closures are
    /// run, the existing one first, and the provided title replaces the
    /// existing one.
    ///
    /// - parameter title: The title of the "Cancel" button, displayed
    ///   without localization.
    /// - parameter action: A closure called when the user dismisses
    ///   the error, and in the other situations described by
    ///   ``ErrorCancelReason``.
    public func onCancel(
        verbatim title: String,
        action: @escaping @MainActor (_ cancelReason: ErrorCancelReason) -> Void
    ) -> FlowError {
        onCancel(title, action: action)
    }
    
    func onRetry(
        titleSource: TextSource?,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        let oldRetryAction = self.retryAction
        var result = self
        let title = titleSource ?? oldRetryAction?.title ?? .localizedStringResource(.retry)
        result.retryAction = ErrorAction(titleSource: title) {
            oldRetryAction?()
            action()
        }
        return result
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried.
    ///
    /// If the flow error already has a retry action, both closures are
    /// run, the existing one first, and the existing title is preserved.
    /// Otherwise, the button is titled "Retry".
    ///
    /// - parameter action: A closure called when the user hits the
    ///   "Retry" button.
    public func onRetry(
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(titleSource: nil, action: action)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried, with a customized title for the Retry button
    /// that is not localized.
    ///
    /// If the flow error already has a retry action, both closures are
    /// run, the existing one first, and the provided title replaces the
    /// existing one.
    ///
    /// - parameter title: The title of the "Retry" button, displayed
    ///   without localization.
    /// - parameter action: A closure called when the user hits the
    ///   "Retry" button.
    @_disfavoredOverload
    public func onRetry(
        _ title: some StringProtocol,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(titleSource: .verbatim(title), action: action)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried, with a customized title for the Retry button.
    ///
    /// If the flow error already has a retry action, both closures are
    /// run, the existing one first, and the provided title replaces the
    /// existing one.
    ///
    /// - parameter title: The localized title of the "Retry" button.
    /// - parameter action: A closure called when the user hits the
    ///   "Retry" button.
    public func onRetry(
        _ title: LocalizedStringKey,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(titleSource: .localizedStringKey(title), action: action)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried, with a customized title for the Retry button.
    ///
    /// If the flow error already has a retry action, both closures are
    /// run, the existing one first, and the provided title replaces the
    /// existing one.
    ///
    /// - parameter title: The localized title of the "Retry" button.
    /// - parameter action: A closure called when the user hits the
    ///   "Retry" button.
    @_disfavoredOverload
    public func onRetry(
        _ title: LocalizedStringResource,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(titleSource: .localizedStringResource(title), action: action)
    }
    
    /// Returns a flow error that executes the provided closure when the
    /// error is retried, with a customized title for the Retry button
    /// that is not localized.
    ///
    /// If the flow error already has a retry action, both closures are
    /// run, the existing one first, and the provided title replaces the
    /// existing one.
    ///
    /// - parameter title: The title of the "Retry" button, displayed
    ///   without localization.
    /// - parameter action: A closure called when the user hits the
    ///   "Retry" button.
    public func onRetry(
        verbatim title: String,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        onRetry(title, action: action)
    }
    
    /// Returns a flow error without any retry action.
    ///
    /// Use this method for unrecoverable errors, in order to prevent the
    /// user from retrying the failed action.
    public func droppingRetryAction() -> FlowError {
        var result = self
        result.retryAction = nil
        return result
    }
    
    private func appendingAction(
        _ title: TextSource,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(ErrorAction(titleSource: title, role: role, action: action))
    }
    
    /// Returns a flow error with an extra supplementary action, with a
    /// title that is not localized.
    ///
    /// See ``appendingAction(_:role:action:)-(LocalizedStringKey,_,_)``.
    ///
    /// - parameter title: The action title, displayed without localization.
    /// - parameter role: The action role.
    /// - parameter action: A closure called when the user selects the action.
    @_disfavoredOverload
    public func appendingAction(
        _ title: some StringProtocol,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(.verbatim(title), role: role, action: action)
    }
    
    /// Returns a flow error with an extra supplementary action.
    ///
    /// If the user selects this action, the cancel action is run first,
    /// with the ``ErrorCancelReason/supplementaryActionPerformed`` reason.
    ///
    /// - parameter title: The localized action title.
    /// - parameter role: The action role.
    /// - parameter action: A closure called when the user selects the action.
    public func appendingAction(
        _ title: LocalizedStringKey,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(.localizedStringKey(title), role: role, action: action)
    }
    
    /// Returns a flow error with an extra supplementary action.
    ///
    /// See ``appendingAction(_:role:action:)-(LocalizedStringKey,_,_)``.
    ///
    /// - parameter title: The localized action title.
    /// - parameter role: The action role.
    /// - parameter action: A closure called when the user selects the action.
    @_disfavoredOverload
    public func appendingAction(
        _ title: LocalizedStringResource,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(.localizedStringResource(title), role: role, action: action)
    }
    
    /// Returns a flow error with an extra supplementary action, with a
    /// title that is not localized.
    ///
    /// See ``appendingAction(_:role:action:)-(LocalizedStringKey,_,_)``.
    ///
    /// - parameter title: The action title, displayed without localization.
    /// - parameter role: The action role.
    /// - parameter action: A closure called when the user selects the action.
    public func appendingAction(
        verbatim title: String,
        role: ErrorActionRole? = nil,
        action: @escaping @MainActor () -> Void
    ) -> FlowError {
        appendingAction(title, role: role, action: action)
    }
    
    /// Returns a flow error with an extra supplementary action.
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
    /// - parameter action: A closure to run at the end of all error
    ///   actions (cancel, retry, supplementary actions).
    public func finally(action: @escaping @MainActor () -> Void) -> FlowError {
        let oldFinally = self.finally
        var result = self
        result.finally = {
            oldFinally?()
            action()
        }
        return result
    }
    
    /// Returns a flow error with a customized title that is not localized.
    ///
    /// See ``withTitle(_:)-(LocalizedStringKey)``.
    ///
    /// - parameter title: The error title, displayed without localization.
    @_disfavoredOverload
    public func withTitle(_ title: some StringProtocol) -> FlowError {
        var result = self
        result.title = .verbatim(title)
        return result
    }
    
    /// Returns a flow error with a customized title.
    ///
    /// The provided title is displayed prominently, and has priority over
    /// the title provided by flow error handlers, which is then displayed
    /// as a subtitle (see ``ErrorPresentation``). For example, compare the
    /// alerts presented in the sample code below:
    ///
    /// ```swift
    /// // First version
    /// func updateMessages() async {
    ///     do {
    ///         messages = try await fetchMessages()
    ///     } catch {
    ///         // The title is provided by the handling of URLError:
    ///         // ┌──────────────────────────┐
    ///         // │ The Internet connection  │
    ///         // │ appears to be offline.   │
    ///         // │                          │
    ///         // │          [ OK ]          │
    ///         // └──────────────────────────┘
    ///         flowError = FlowError(error: error)
    ///     }
    /// }
    ///
    /// // Second version
    /// func updateMessages() async {
    ///     do {
    ///         messages = try await fetchMessages()
    ///     } catch {
    ///         // The title is provided by the FlowError itself,
    ///         // and the title provided by the handling of
    ///         // URLError becomes a subtitle:
    ///         // ┌──────────────────────────────┐
    ///         // │ Could not fetch new messages │
    ///         // │                              │
    ///         // │ The Internet connection      │
    ///         // │ appears to be offline.       │
    ///         // │                              │
    ///         // │            [ OK ]            │
    ///         // └──────────────────────────────┘
    ///         flowError = FlowError(error: error)
    ///             .withTitle("Could not fetch new messages")
    ///     }
    /// }
    /// ```
    ///
    /// - parameter title: The localized error title.
    public func withTitle(
        _ title: LocalizedStringKey
    ) -> FlowError {
        var result = self
        result.title = .localizedStringKey(title)
        return result
    }
    
    /// Returns a flow error with a customized title.
    ///
    /// See ``withTitle(_:)-(LocalizedStringKey)``.
    ///
    /// - parameter title: The localized error title.
    @_disfavoredOverload
    public func withTitle(_ title: LocalizedStringResource) -> FlowError {
        var result = self
        result.title = .localizedStringResource(title)
        return result
    }
    
    /// Returns a flow error with a customized title that is not localized.
    ///
    /// See ``withTitle(_:)-(LocalizedStringKey)``.
    ///
    /// - parameter title: The error title, displayed without localization.
    public func withTitle(verbatim title: String) -> FlowError {
        withTitle(title)
    }
    
    /// Returns a flow error with a different error.
    ///
    /// An error handler can use this method in order to pass an
    /// underlying error to the next handlers (see
    /// ``FlowErrorHandlerChain/init(_:)``).
    ///
    /// - parameter error: The new error.
    public func withError(_ error: any Error) -> FlowError {
        var result = self
        result.error = error
        return result
    }
}

// MARK: - ErrorCancelReason

/// The reason why the cancel action of a ``FlowError`` is run.
public enum ErrorCancelReason: Sendable {
    /// The user has dismissed the error with the cancel button, or
    /// ``FlowError/performCancelAction()`` was called.
    case userCancelled
    
    /// The flow error was discarded without the user selecting any of its
    /// actions.
    ///
    /// For example, an error handler returned
    /// ``FlowErrorHandling/cancel``, the flow error conflicted with
    /// another presented flow error, the view that presented it in an
    /// alert has disappeared, or the application called
    /// ``FlowError/discard(_:)`` with this reason.
    case presentationCancelled
    
    /// The user has selected a supplementary action (see
    /// ``FlowError/supplementaryActions``).
    ///
    /// The cancel action runs first, with this reason, and then the
    /// supplementary action. This lets the code that created the flow error
    /// clean up, even when the supplementary action was added by
    /// someone else, such as an "Open Settings" action added by a
    /// ``FlowErrorHandler``.
    case supplementaryActionPerformed
}

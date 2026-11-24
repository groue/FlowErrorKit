import FlowErrorKit
import SwiftUI

struct ErrorListView: View {
    @State private var flowError: FlowError?
    @State private var errorIsCancelled = false
    @State private var validationErrorBackground = false
    
    var body: some View {
        NavigationView {
            List {
                Text("""
                    The **FlowErrorKit** library provides tools for \
                    handling and presenting errors.
                    
                    Applications catch errors and turn them into \
                    `FlowError` values that FlowErrorKit presents in the \
                    user interface, so \
                    that the application user can choose how to proceed. \
                    The available actions can be configured: users can \
                    *cancel*, *retry*, or perform any other action deemed \
                    useful, such as a repair action.
                    
                    The framework also defines the `FlowErrorHandler` \
                    protocol. Error handlers fine-tune error presentation, \
                    add actions, or prevent an error from being presented. \
                    Flow error handlers live in the SwiftUI environment, \
                    so that they can handle errors thrown anywhere in a \
                    view hierarchy.
                    
                    Below is an exploration of the use cases \
                    made possible by FlowErrorKit.
                    
                    ⬇️
                    """).padding(.vertical)
                
                Group {
                    Section {
                        Button("Default Error") {
                            throwDefaultError()
                        }
                        Button("Default Error With Cancel Handler") {
                            throwDefaultErrorWithCancel()
                        }
                        Button("Default Error With Retry Handler") {
                            throwDefaultErrorWithRetry()
                        }
                    } header: {
                        header(
                            title: "Default Error",
                            message:
                                """
                                The default error presentation, when no \
                                customization is applied.
                                """,
                                """
                                Since most errors have an English or technical \
                                localized message that is not suitable for user \
                                display, the error message is hidden by default.
                                """,
                                """
                                Views can specify, if they want, a **Cancel \
                                handler**, and a **Retry handler**. The error \
                                alert then displays relevant buttons.
                                """,
                                """
                                Tap the error buttons, and see how the "Cancelled" \
                                message flashes, at the bottom of the screen, \
                                depending on the error and your choice of action.
                                """)
                    }
                    
                    Section {
                        Button("Customized Error") {
                            throwVerbatimError()
                        }
                        Button("Customized Error With Cancel Handler") {
                            throwVerbatimErrorWithCancel()
                        }
                        Button("Customized Error With Retry Handler") {
                            throwVerbatimErrorWithRetry()
                        }
                    } header: {
                        header(
                            title: "Custom Error Message",
                            message:
                                """
                                It is possible to register an error handler that \
                                exposes error details.
                                """)
                    }
                    
                    Section {
                        Button("Ignored Error") {
                            throwIgnoredError()
                        }
                        Button("Ignored Error With Cancel Handler") {
                            throwIgnoredErrorWithCancel()
                        }
                    } header: {
                        // swiftlint:disable vertical_parameter_alignment_on_call
                        header(
                            title: "Ignored Error",
                            message:
                                "Ignored errors do not show any alert.",
                                "They can trigger side effects with the Cancel handler.",
                                """
                                Typically, when a library throws an error in order \
                                to notify explicit user cancellation, this error \
                                should be ignored.
                                """)
                        // swiftlint:enable vertical_parameter_alignment_on_call
                    }
                    
                    Section {
                        Button("Permission Error") {
                            throwPermissionError()
                        }
                        Button("Permission Error With Cancel Handler") {
                            throwPermissionErrorWithCancel()
                        }
                        Button("Permission Error With Retry Handler") {
                            throwPermissionErrorWithRetry()
                        }
                    } header: {
                        header(
                            title: "Permission Error",
                            message:
                                """
                                Permission errors are handled in a custom way, in \
                                the whole app (not only in this view).
                                """,
                                """
                                The Retry button is removed, an \
                                "Open Settings" button is added, and \
                                the alert title is customized.
                                """)
                    }
                    
                    Section {
                        Button("Expired Session Error") {
                            throwExpiredSessionError()
                        }
                    } header: {
                        header(
                            title: "Expired Session Error",
                            message:
                                """
                                Expired Session Error is handled in a custom way \
                                in the whole app (not only in this view).
                                """,
                                """
                                It completely transforms the view hierarchy.
                                """)
                    }
                    
                    Section {
                        Button("Code Signing Error") {
                            throwCodeSigningError()
                        }
                        Button("Code Signing Error With Cancel Handler") {
                            throwCodeSigningErrorWithCancel()
                        }
                        Button("Code Signing Error With Retry Handler") {
                            throwCodeSigningErrorWithRetry()
                        }
                    } header: {
                        header(
                            title: "Code Signing Error",
                            message:
                                """
                                Code Signing Error is handled in a custom way \
                                in the whole app (not only in this view).
                                """,
                                """
                                An extra repair button is added. When selected, \
                                the Cancel handler is run before the extra action \
                                is executed.
                                """)
                    }
                    
                    Section {
                        Button("Validation Error") {
                            throwValidationError()
                        }
                        Button("Validation Error With Cancel Handler") {
                            throwValidationErrorWithCancel()
                        }
                    } header: {
                        header(
                            title: "Validation Error",
                            message:
                                """
                                Validation errors are handled in a custom way by a \
                                specific view: this view.
                                """,
                                """
                                Here the view replaces the error alert with \
                                a color change.
                                """,
                                """
                                Since validation errors are not presented, like \
                                Ignored errors, they trigger side effects with the \
                                Cancel handler.
                                """)
                    }
                    .listRowBackground(errorBackgroundColor)
                    
                    Section {
                        Button("Random Error With Retry Handler") {
                            throwRandomErrorWithRetry()
                        }
                    } header: {
                        header(title: "Random Error", message: """
                            Can you guess which error is thrown?
                            """)
                    }
                }
                
                Group {
                    Section {
                        Button("Error With Cancel Handler After Initial Error") {
                            throwTwoErrorsInARow()
                        }
                        Button("Ignored Error With Cancel Handler After Initial Error") {
                            throwIgnoredErrorAfterInitialError()
                        }
                    } header: {
                        header(title: "Error Conflict", message: """
                            When a second error is raised before a first one \
                            is dismissed by the user, the error alert is not \
                            replaced, not dismissed, and the Cancel handler of the \
                            second error is run.
                            
                            Tap a button, wait 3 seconds, and observe the \
                            "Cancelled" message at the bottom of the screen.
                            """)
                    }
                    
                    Section {
                        Button("Dismissed Error With Cancel Handler") {
                            throwDismissedErrorWithCancel()
                        }
                    } header: {
                        header(title: "Programmatic Error Dismissal", message: """
                        When the app decides to dismiss the error before \
                        the user does, the Cancel handler is **NOT** \
                        run. Wait 3 seconds for the error to be dismissed.
                        """)
                    }
                }
            }
            .navigationTitle("💥 Flow Errors")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                statusBar
            }
        }
        .presentError($flowError, with: .alert)
        // After error is presented, so that validation errors are handled
        .handleError(ofType: ValidationError.self) { _, _ in
            validationErrorBackground = true
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                validationErrorBackground = false
            }
            return .cancel
        }
    }
    
    /// A bar at the bottom of the screen that shows whether an alert is
    /// visible, and flashes when an error is cancelled.
    var statusBar: some View {
        HStack {
            Text("Alert visible")
                .opacity(flowError == nil ? 0.1 : 1)
            Spacer()
            Text("Cancelled")
                .foregroundStyle(errorIsCancelled
                                 ? Color.primary
                                 : Color(uiColor: .quaternaryLabel))
        }
        .padding()
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    func header(title: String, message: LocalizedStringKey...) -> some View {
        struct Message: Identifiable {
            let id: Int
            let text: LocalizedStringKey
        }
        
        return VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.body).bold()
            ForEach(message.enumerated().map { Message(id: $0, text: $1) }) { message in
                Text(message.text)
            }.font(.callout).textCase(.none)
        }
    }
    
    var errorBackgroundColor: Color {
        if validationErrorBackground {
            return .red
        } else {
            return Color(uiColor: .secondarySystemGroupedBackground)
        }
    }
}

// MARK: - Actions

extension ErrorListView {
    // MARK: - Default Error
    
    func throwDefaultError() {
        errorIsCancelled = false
        do {
            throw makeDefaultError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwDefaultErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw makeDefaultError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
        }
    }
    
    func throwDefaultErrorWithRetry() {
        errorIsCancelled = false
        do {
            throw makeDefaultError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
                .onRetry(action: throwDefaultErrorWithRetry)
        }
    }
    
    // MARK: - VerbatimError
    
    func throwVerbatimError() {
        errorIsCancelled = false
        do {
            throw VerbatimError(errorDescription: "Custom Error Message")
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwVerbatimErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw VerbatimError(errorDescription: "Custom Error Message")
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
        }
    }
    
    func throwVerbatimErrorWithRetry() {
        errorIsCancelled = false
        do {
            throw VerbatimError(errorDescription: "Custom Error Message")
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
                .onRetry(action: throwVerbatimErrorWithRetry)
        }
    }
    
    // MARK: - IgnoredError
    
    func throwIgnoredError() {
        errorIsCancelled = false
        do {
            throw IgnoredError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwIgnoredErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw IgnoredError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
        }
    }
    
    // MARK: - ValidationError
    
    func throwValidationError() {
        errorIsCancelled = false
        do {
            throw ValidationError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwValidationErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw ValidationError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
        }
    }
    
    // MARK: - PermissionError
    
    func throwPermissionError() {
        errorIsCancelled = false
        do {
            throw PermissionError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwPermissionErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw PermissionError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
        }
    }
    
    func throwPermissionErrorWithRetry() {
        errorIsCancelled = false
        do {
            throw PermissionError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
                .onRetry(action: throwPermissionErrorWithRetry)
        }
    }
    
    // MARK: - ExpiredSessionError
    
    func throwExpiredSessionError() {
        errorIsCancelled = false
        do {
            throw ExpiredSessionError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
        }
    }
    
    // MARK: - CodeSigningError
    
    func throwCodeSigningError() {
        errorIsCancelled = false
        do {
            throw CodeSigningError()
        } catch {
            flowError = FlowError(error: error)
        }
    }
    
    func throwCodeSigningErrorWithCancel() {
        errorIsCancelled = false
        do {
            throw CodeSigningError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
        }
    }
    
    func throwCodeSigningErrorWithRetry() {
        errorIsCancelled = false
        do {
            throw CodeSigningError()
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
                .onRetry(action: throwCodeSigningErrorWithRetry)
        }
    }
    
    // MARK: - Random Error
    
    func throwRandomErrorWithRetry() {
        do {
            let errors: [Error] = [
                makeDefaultError(),
                IgnoredError(),
                ValidationError(),
                PermissionError(),
                ExpiredSessionError(),
                CodeSigningError(),
                VerbatimError(errorDescription: "Not Implemented Yet"),
            ]
            throw errors.randomElement()!
        } catch {
            flowError = FlowError(error: error)
                .onCancel { _ in flashCancelled() }
                .onRetry(action: throwRandomErrorWithRetry)
        }
    }
    
    // MARK: - Error Conflicts
    
    func throwTwoErrorsInARow() {
        errorIsCancelled = false
        flowError = FlowError(error: VerbatimError(errorDescription: "First Error"))
        Task {
            try? await Task.sleep(for: .seconds(3))
            flowError = FlowError(error: VerbatimError(errorDescription: "Second Error"))
                .onCancel { _ in flashCancelled() }
        }
    }
    
    func throwIgnoredErrorAfterInitialError() {
        errorIsCancelled = false
        flowError = FlowError(error: VerbatimError(errorDescription: "First Error"))
        Task {
            try? await Task.sleep(for: .seconds(3))
            flowError = FlowError(error: IgnoredError())
                .onCancel { _ in flashCancelled() }
        }
    }
    
    func throwDismissedErrorWithCancel() {
        errorIsCancelled = false
        flowError = FlowError(error: makeDefaultError())
            .onCancel { _ in flashCancelled() }
        Task {
            try? await Task.sleep(for: .seconds(3))
            flowError = nil
        }
    }
    
    private func makeDefaultError() -> Error {
        // An error that is not handled by any error handler.
        ServerError(statusCode: 500)
    }
    
    private func flashCancelled() {
        errorIsCancelled = true
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            errorIsCancelled = false
        }
    }
}

struct ValidationError: Error { }

struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorListView()
    }
}

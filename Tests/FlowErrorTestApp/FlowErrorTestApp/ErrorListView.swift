import FlowErrorKit
import SwiftUI

struct ErrorListView: View {
    @State var viewModel = ErrorListViewModel()
    
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
                            viewModel.throwDefaultError()
                        }
                        Button("Default Error With Cancel Handler") {
                            viewModel.throwDefaultErrorWithCancel()
                        }
                        Button("Default Error With Retry Handler") {
                            viewModel.throwDefaultErrorWithRetry()
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
                                View models can specify, if they want, a **Cancel \
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
                            viewModel.throwVerbatimError()
                        }
                        Button("Customized Error With Cancel Handler") {
                            viewModel.throwVerbatimErrorWithCancel()
                        }
                        Button("Customized Error With Retry Handler") {
                            viewModel.throwVerbatimErrorWithRetry()
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
                            viewModel.throwIgnoredError()
                        }
                        Button("Ignored Error With Cancel Handler") {
                            viewModel.throwIgnoredErrorWithCancel()
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
                            viewModel.throwPermissionError()
                        }
                        Button("Permission Error With Cancel Handler") {
                            viewModel.throwPermissionErrorWithCancel()
                        }
                        Button("Permission Error With Retry Handler") {
                            viewModel.throwPermissionErrorWithRetry()
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
                            viewModel.throwExpiredSessionError()
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
                            viewModel.throwCodeSigningError()
                        }
                        Button("Code Signing Error With Cancel Handler") {
                            viewModel.throwCodeSigningErrorWithCancel()
                        }
                        Button("Code Signing Error With Retry Handler") {
                            viewModel.throwCodeSigningErrorWithRetry()
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
                            viewModel.throwValidationError()
                        }
                        Button("Validation Error With Cancel Handler") {
                            viewModel.throwValidationErrorWithCancel()
                        }
                    } header: {
                        header(
                            title: "Validation Error",
                            message:
                                """
                                Validation errors are handled in a custom way by a \
                                specific view model: the view model of this view.
                                """,
                                """
                                Here the view model replaces the error alert with \
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
                            viewModel.throwRandomErrorWithRetry()
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
                            viewModel.throwTwoErrorsInARow()
                        }
                        Button("Ignored Error With Cancel Handler After Initial Error") {
                            viewModel.throwIgnoredErrorAfterInitialError()
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
                            viewModel.throwDismissedErrorWithCancel()
                        }
                    } header: {
                        header(title: "Programmatic Error Dismissal", message: """
                        When the view model decides to dismiss the error before \
                        the user does, the Cancel handler is **NOT** \
                        run. Wait 3 seconds for the error to be dismissed.
                        """)
                    }
                }
            }
            .navigationTitle("💥 Flow Errors")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if viewModel.flowError == nil {
                        Text("Alert visible").opacity(0.1)
                    } else {
                        Text("Alert visible")
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if viewModel.errorIsCancelled {
                        Text("Cancelled")
                    } else {
                        Text("Cancelled")
                            .foregroundColor(Color(uiColor: .quaternaryLabel))
                    }
                }
            }
        }
        .presentError($viewModel.flowError, with: .alert)
        .handleError(with: viewModel) // After error is presented, so that viewModel can handle errors
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
        if viewModel.validationErrorBackground {
            return .red
        } else {
            return Color(uiColor: .secondarySystemGroupedBackground)
        }
    }
}

struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorListView()
    }
}

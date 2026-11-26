import CoreLocation
import FlowErrorKit
import SwiftUI

/// The root navigation view of the FlowErrorDemo app.
struct DemosNavigationView: View {
    var body: some View {
        NavigationStack {
            List {
                intro
                errorPresentationBasics
                errorActions
                customPresentation
                ignoredErrors
                supplementaryActions
                unauthorizedError
                randomError
                multipleExecutionError
            }
            .listStyle(.grouped)
            .headerProminence(.increased)
            .navigationTitle("FlowError Demo")
        }
        .handleError(with: CLErrorHandler())
        .handleError(with: FrobnicateErrorHandler())
    }
    
    @ViewBuilder
    var errorPresentationBasics: some View {
        Section {
            Group {
                NavigationLink("Alert") {
                    BasicAlertView()
                        .navigationTitle("Error Basics")
                }
                NavigationLink {
                    BasicErrorPresentationView()
                        .navigationTitle("Error Basics")
                } label: {
                    Text(verbatim: "ErrorPresentationView")
                }
            }
        } header: {
            sectionHeader(
                title: "Error Presentation Basics",
                description: """
                    No setup required: just catch and present errors with \
                    an alert or an ErrorPresentationView.
                    """
            )
        }
    }
    
    @ViewBuilder
    var intro: some View {
        Section { EmptyView() } header: {
            sectionHeader(description: """
                This demo application reviews frequent use cases of error handling.
                """)
        }
    }
    @ViewBuilder
    var errorActions: some View {
        Section {
            Group {
                NavigationLink("Alert") {
                    AlertWithErrorActionsView(error: URLError.networkConnectionLostError)
                        .navigationTitle("Error Actions")
                }
                NavigationLink {
                    ErrorPresentationViewWithErrorActionsView(error: URLError.networkConnectionLostError)
                        .navigationTitle("Error Actions")
                } label: {
                    Text(verbatim: "ErrorPresentationView")
                }
            }
        } header: {
            sectionHeader(
                title: "Error Actions",
                description: "Add a Retry button if desired, and execute custom code when the user cancels the error."
            )
        }
    }
    
    @ViewBuilder
    var customPresentation: some View {
        Section {
            Group {
                NavigationLink("Alert") {
                    AlertWithErrorActionsView(error: FrobnicateError.random())
                        .navigationTitle("Custom Presentation")
                }
                NavigationLink {
                    ErrorPresentationViewWithErrorActionsView(error: FrobnicateError.random())
                        .navigationTitle("Custom Presentation")
                } label: {
                    Text(verbatim: "ErrorPresentationView")
                }
            }
        } header: {
            sectionHeader(
                title: "Custom Presentation",
                description: """
                    Some errors require a custom presentation. \
                    `FrobnicateError`, handled by \
                    `FrobnicateErrorHandler`, has a custom title and \
                    message, and no Retry button when the error \
                    is unrecoverable.
                    """
            )
        }
    }
    
    @ViewBuilder
    var ignoredErrors: some View {
        Section {
            Group {
                NavigationLink("Alert") {
                    AlertWithErrorActionsView(
                        error: CocoaError(.userCancelled),
                        failureProbability: 1)
                    .navigationTitle("Ignored Error")
                }
                NavigationLink {
                    ErrorPresentationViewWithErrorActionsView(
                        error: CocoaError(.userCancelled),
                        failureProbability: 1)
                    .navigationTitle("Ignored Error")
                } label: {
                    Text(verbatim: "ErrorPresentationView")
                }
            }
        } header: {
            sectionHeader(
                title: "Ignored Errors",
                description: """
                    Some errors represent user cancellation, and \
                    must not be presented. This is the case for \
                    `CocoaError(.userCancelled)`, handled by \
                    FlowErrorKit.
                    """
            )
        }
    }
    
    @ViewBuilder
    var supplementaryActions: some View {
        Section {
            Group {
                NavigationLink("Supplementary Action") {
                    AlertWithErrorActionsView(error: CLError(.denied))
                        .navigationTitle("Supplementary Action")
                }
            }
        } header: {
            sectionHeader(
                title: "Supplementary Actions",
                description: """
                    Some errors need specific recovery actions. \
                    `CLError(.denied)`, handled by `CLErrorHandler`, has \
                    an extra "Open Settings" action.
                    """
            )
        }
    }
    
    @ViewBuilder
    var unauthorizedError: some View {
        Section {
            Group {
                NavigationLink("Unauthorized Error") {
                    AuthorizedView {
                        AlertWithErrorActionsView(error: UnauthorizedError())
                    }
                    .navigationTitle("Unauthorized Error")
                }
            }
        } header: {
            sectionHeader(
                title: "Unauthorized Errors",
                description: """
                    The `UnauthorizedError` is handled by destroying \
                    the whole view when it happens.
                    """
            )
        }
    }
    
    @ViewBuilder
    var randomError: some View {
        Section {
            Group {
                NavigationLink("Random Error") {
                    AuthorizedView {
                        AlertWithErrorActionsView(error: [
                            URLError.networkConnectionLostError,
                            CLError(.denied),
                            CocoaError(.userCancelled),
                            UnauthorizedError(),
                            FrobnicateError.random(),
                        ].randomElement()!)
                    }
                    .navigationTitle("Random Error")
                }
            }
        } header: {
            sectionHeader(
                title: "Random Errors",
                description: """
                    Can you guess which error is thrown?
                    """
            )
        }
    }
    
    @ViewBuilder
    var multipleExecutionError: some View {
        Section {
            Group {
                NavigationLink("Multiple Actions Disabled") {
                    ErrorPresentationViewWithErrorActionsView(
                        error: CLError(.denied),
                        allowMultipleActionExecutions: false,
                        failureProbability: 1)
                        .navigationTitle("Multiple Actions Disabled")
                }
                NavigationLink("Multiple Actions Enabled") {
                    ErrorPresentationViewWithErrorActionsView(
                        error: CLError(.denied),
                        allowMultipleActionExecutions: true,
                        failureProbability: 1)
                        .navigationTitle("Multiple Actions Enabled")
                }
            }
        } header: {
            sectionHeader(
                title: "Multiple Actions",
                description: """
                    `ErrorPresentationView` remains on screen after the \
                    user selects an action. Hit "Open Settings", and come \
                    back: the buttons are disabled, unless the \
                    `FlowError` is created with the \
                    `allowMultipleActionExecutions` flag.
                    """
            )
        }
    }
    
    @ViewBuilder
    private func sectionHeader(
        title: LocalizedStringKey,
        description: LocalizedStringKey)
    -> some View
    {
        VStack(alignment: .leading) {
            Text(title)
            Text(description).font(.callout).foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func sectionHeader(
        description: LocalizedStringKey)
    -> some View
    {
        VStack(alignment: .leading) {
            Text(description).font(.callout).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    DemosNavigationView()
}

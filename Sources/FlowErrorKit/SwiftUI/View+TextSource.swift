import SwiftUI

extension View {
    /// Presents an alert with a text source as its title, using the given
    /// data to produce the alert's content.
    ///
    /// The alert is presented when `data` is not nil.
    ///
    /// For example:
    ///
    /// ```swift
    /// import FlowErrorKit
    /// import SwiftUI
    ///
    /// struct MyView: View {
    ///     @State private var errorPresentation: ErrorPresentation?
    ///
    ///     var body: some View {
    ///         ContentView().alert(
    ///             errorPresentation?.title,
    ///             item: $errorPresentation,
    ///             actions: { presentation in
    ///                 Button("OK") {
    ///                     presentation.flowError.performCancelAction()
    ///                 }
    ///             },
    ///             message: { presentation in
    ///                 if let message = presentation.message {
    ///                     Text(message)
    ///                 }
    ///             })
    ///     }
    /// }
    /// ```
    ///
    /// - parameters:
    ///     - title: The title of the alert. A nil title is displayed
    ///       as an empty title.
    ///     - data: A binding to an optional source of truth for the alert.
    ///       When the user dismisses the alert, the binding is set to nil.
    ///     - actions: A view builder returning the alert's actions,
    ///       given the current non-nil value of `data`.
    ///     - message: A view builder returning the message for the alert,
    ///       given the current non-nil value of `data`.
    public func alert<A, M, T>(
        _ title: TextSource?,
        item data: Binding<T?>,
        @ContentBuilder actions: (T) -> A,
        @ContentBuilder message: (T) -> M
    ) -> some View
    where A : View, M : View
    {
        alert(
            Text(title ?? .verbatim("")),
            isPresented: Binding(
                get: { data.wrappedValue != nil },
                set: { isPresented, transaction in
                    if !isPresented {
                        data.transaction(transaction).wrappedValue = nil
                    }
                }),
            presenting: data.wrappedValue,
            actions: actions,
            message: message)
    }
}

import SwiftUI

@available(iOS 17.0, *)
extension ContentUnavailableView {
    /// Creates a `ContentUnavailableView` instance that conveys an
    /// error state.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter cancelActionVisible: Whether the cancel action should
    ///   be visible.
    @MainActor public static func error(
        _ errorPresentation: ErrorPresentation,
        cancelActionVisible: Bool = false
    ) -> ContentUnavailableView<Label, Description, Actions>
    where Label == ErrorPresentationContent<EmptyView>.Label,
          Description == ErrorPresentationContent<EmptyView>.Description,
          Actions == ErrorPresentationContent<EmptyView>.Actions
    {
        let content = ErrorPresentationContent<EmptyView>(
            errorPresentation: errorPresentation,
            cancelActionVisible: cancelActionVisible,
            footer: EmptyView())
        
        return ContentUnavailableView(
            label: content.label,
            description: content.description,
            actions: content.actions)
    }
    
    /// Creates a `ContentUnavailableView` instance that conveys an
    /// error state.
    ///
    /// - parameter errorPresentation: An error presentation.
    /// - parameter cancelActionVisible: Whether the cancel action should
    ///   be visible.
    /// - parameter footer: A view to display below error actions.
    @MainActor public static func error<Footer: View>(
        _ errorPresentation: ErrorPresentation,
        cancelActionVisible: Bool = false,
        @ViewBuilder footer: () -> Footer
    ) -> ContentUnavailableView<Label, Description, Actions>
    where Label == ErrorPresentationContent<Footer>.Label,
          Description == ErrorPresentationContent<Footer>.Description,
          Actions == ErrorPresentationContent<Footer>.Actions
    {
        let content = ErrorPresentationContent<Footer>(
            errorPresentation: errorPresentation,
            cancelActionVisible: cancelActionVisible,
            footer: footer())
        
        return ContentUnavailableView(
            label: content.label,
            description: content.description,
            actions: content.actions)
    }
}

# Custom error presentation

The built-in presenters cover nearly every need (see "Presenting flow
errors" in SKILL.md):

- `.presentError($flowError, with: .alert)`, by default.
- `.presentError($flowError, with: .errorPresentationView)`, when the
  content of the screen could not be loaded, or
  `.errorPresentationView { errorPresentation in ... }` for any other
  view displayed in place of the content.

Custom presentation is needed when the app needs a presentation style
that is neither an alert nor a view displayed in place of the content
(a banner, a toast…).

Choosing not to present an error, and passing it to
`errorHandler.handle(_:)` so that handlers run their side effects, is
not custom presentation: see "Errors that are not presented" in
SKILL.md.

Custom presentation can be achieved with a custom `FlowErrorPresenter`
that can be used with `presentError(_:with:)`, or with custom code when
the requested feature would not profit from the `presentError(_:with:)`
API.

In all cases, you must follow the contract documented by the
`FlowErrorPresenter` protocol, which generally describes how a
`Binding<FlowError?>` must be handled. In summary:

- The role of error presentation is to let the user perform the actions
  of a flow error, and, whenever possible, to never leave a flow error
  unattended.
- Read the chain of handlers with `@Environment(\.errorHandler)`, and
  call `errorHandler.handle(flowError)` for every distinct `id` of the
  bound flow error, including when the view appears
  (`.onChange(of: flowError?.id, initial: true)`). All flow error
  instances must be handled, once, as soon as possible.
- When the result of `errorHandler.handle(flowError)` has a nil
  `errorPresentation` property, it means that a handler cancelled the
  presentation: you must call `flowError.discard(.presentationCancelled)`,
  and adjust the view according to the desired behavior of the custom
  presentation.
- When the custom presentation has no error to present, make sure the
  flow error binding is set to nil, so that the caller knows that no
  error is presented.
- When an error is presented, and the custom presentation allows the
  user to perform actions, call `flowError.performAction(action)` or
  `flowError.performCancelAction()` in response to user interactions.
  Check the observable `flowError.canPerformAction` property to hide or
  disable interactive elements, according to the desired behavior of
  the custom presentation.
- When a new flow error is set while another one is presented, either
  replace the presented one, or ignore the new one. In both cases, call
  `discard(.presentationCancelled)` on the flow error that is not
  presented.
- When the binding is set to nil from the parent view, stop presenting
  the error, but do not perform any action. It is the code that
  programmatically cancels the error presentation that is responsible
  for performing actions, if it needs to: this is not the concern of the
  custom presentation.
- When the view reaches a state where it is no longer possible for the
  app user to select any action of a presented flow error, call
  `discard(.presentationCancelled)` on it, and set the binding to nil if
  the desired behavior of the custom presentation is to stop presenting
  the error in such a case. Do so only when you can tell it for sure:
  never from `.onDisappear`, nor from a `deinit`.

  Why: when the user switches to another tab and back, a presentation
  that was displayed in the view comes back on screen, and the user can
  still select an action. Your code does not control when a `deinit`
  runs.

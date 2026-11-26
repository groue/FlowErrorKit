# Custom error presentation

The built-in presentations cover nearly every need (see "Presenting flow
errors" in SKILL.md):

- `.presentError($flowError, with: .alert)`, by default.
- `.presentError($flowError, with: $errorPresentation)`, when the content
  of the screen could not be loaded. When a handler cancels the
  presentation, the view displays its regular content, even empty or
  blank, or a placeholder (a `ProgressView`, `Color.clear`).

Custom presentation is a rare exception. Take this path only in one of
these cases, after checking that no built-in presentation fits:

- The app needs a presentation style that neither an alert nor an
  `ErrorPresentationView` provides (a banner, a toast…). Write a
  `FlowErrorPresenter`, and use it with `presentError(_:with:)`.
- The user explicitly asks to present errors without
  `presentError(_:with:)`.

"The view has nothing to display when a handler cancels the
presentation" is not one of these cases: display a placeholder.

Choosing not to present an error, and passing it to
`errorHandler.handle(_:)` so that handlers run their side effects, is
not custom presentation either: see "Errors that are not presented" in
SKILL.md.

## Presenter contract

Implement a `FlowErrorPresenter` that follows the contract documented
in the protocol, or a view that follows the same contract. In summary:

- Perform the actions of a flow error with
  `flowError.performAction(action)` or `flowError.performCancelAction()`,
  and only once, unless the flow error was created with
  `allowMultipleActionExecutions: true`. `flowError.canPerformAction`
  tells whether an action can still be performed.
- Discard the flow errors whose presentation is cancelled by a handler,
  with `flowError.discard(.presentationCancelled)`.
- Discard a pending flow error, with
  `flowError.discard(.presentationCancelled)`, when the user can no
  longer select any of its actions, but only when the presenter can
  tell it deterministically. Never discard it from `.onDisappear`, nor
  from a `deinit`.

  Why: when the user switches to another tab and back, an in-place
  presentation comes back on screen, and the user can still select an
  action. Your code does not control when a `deinit` runs.
- Expect a new flow error while another one is presented, and decide
  what to do in a way that follows the rules of SKILL.md.

Why: a presenter lets the user perform the actions of a flow error,
and, whenever possible, never leaves a flow error unattended.

## Presenting an error in place without `presentError(_:with:)`

The rules about actions in "In-place presentation" (SKILL.md) still
apply, and the view follows the presenter contract above:

- In the catch clause, call `errorHandler.handle(flowError)`, and
  display the returned `errorPresentation` in an
  `ErrorPresentationView`.
- When the result has no `errorPresentation` (a handler cancelled the
  presentation), call `flowError.discard(.presentationCancelled)`, then
  display `ErrorPresentation(flowError: flowError)`.
- Before replacing or removing a displayed error presentation, call
  `errorPresentation.flowError.discard(.presentationCancelled)`.

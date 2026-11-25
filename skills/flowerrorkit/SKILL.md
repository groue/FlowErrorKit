---
name: flowerrorkit
description: Rules and pitfalls for SwiftUI code that uses FlowErrorKit (FlowError, ErrorPresentation, ErrorPresentationView, FlowErrorHandler, presentError, handleError, errorHandler, onCancel, onRetry, finally, appendingAction). Load before catching or presenting errors in SwiftUI views, writing or registering flow error handlers (including in the App and in #Preview), writing error actions, or writing error titles and messages.
---

# FlowErrorKit

Learn the library from its DocC documentation, in
`Sources/FlowErrorKit/Documentation.docc`: `Usage.md` for the overall
workflow, `FlowError.md` for error actions, `FlowErrorHandler.md` for
error handlers, and the doc comments of public declarations for the
details. Rely on the public API only: never read the implementation,
even to check a behavior.

## Each Swift error must be handled exactly once

Handling a flow error with `presentError(_:with:)` or
`EnvironmentValues.errorHandler.handle(_:)` runs the side effects of the
environment error handlers (sign out, etc.), and `FlowError.id` is the
identity of the error. Every `FlowError(error:)` call creates a new
identity, so:

- Never create a `FlowError` in a view `body`. Bodies are re-evaluated,
  and views are recreated: the same Swift error would be handled again.
- Never store an `Error` (such as `Result<Value, Error>`) for views to
  read and turn into a `FlowError`. Models expose throwing methods, or
  deliver errors once through callbacks.
- Create the `FlowError` where the error is delivered: a `catch` clause,
  or a one-off callback (`onError:`, `.onReceive`, `fileImporter`…).
- An error passed to `_ = errorHandler.handle(error)` is handled: do not
  present it as well with `presentError(_:with:)`.

## In-place presentation

Unlike an alert, which floats above the screen, an in-place presentation
displays the error in the view itself, as an `ErrorPresentationView`
(for example in place of content that could not be loaded).

With `presentError($flowError, with: $errorPresentation)`:

- When a handler cancels the presentation, `errorPresentation` stays
  nil, and `onCancel` has already run, with `.presentationCancelled`. If an error state must
  still be displayed, keep the `FlowError` you created and display
  `ErrorPresentationView(ErrorPresentation(flowError: kept), actions: .hidden)`.
  Its actions are spent, hence `.hidden`.
- After the user selects an action, the `ErrorPresentationView` remains
  on screen, with its buttons, until your code dismisses the screen, or
  clears or replaces the flow error. When an action may not do any of
  this (for example "Open Settings", appended by a handler), create the
  flow error with `allowMultipleActionExecutions: true`, so that the
  user can select an action again. With this flag, the closures of `onRetry`, `onCancel`,
  `finally`, and `appendingAction` may run several times: do not write
  them as if they ran once.

  Only consider the actions that can actually be presented: those added
  by the catch site, and those that the error handlers in scope append
  to the errors that the failed operation can actually throw. For
  example, a handler that appends "Open Settings" to `CLError.denied`
  does not matter when the failed operation is a load from a local
  database: this load never throws `CLError`.

  ```swift
  // GOOD: back from Settings, the user can select "Open Settings"
  // (appended by a handler) again.
  flowError = FlowError(error: error, allowMultipleActionExecutions: true)
      .onRetry { Task { await load() } }

  // BAD: back from Settings, selecting "Open Settings" again reports
  // an issue.
  flowError = FlowError(error: error)
      .onRetry { Task { await load() } }

  // GOOD: every outcome removes the error from the screen.
  flowError = FlowError(error: error)
      .finally { dismiss() }
  ```

- To load a value that may fail, load from `.onAppear` with a guard so
  that it runs once, and catch there. Give the view some content before
  loading (`Color.clear`): `onAppear` does not run on an empty view.

## Actions

- `FlowError(error: error).onCancel { reason in ... }` does not only run
  when the user taps a Cancel button. Its closure runs with one of
  these reasons:
  - `.userCancelled`: the user tapped Cancel. In-place presentations
    hide this button by default.
  - `.presentationCancelled`: a handler returned `.cancel`, or the
    error was replaced or discarded.
  - `.supplementaryActionPerformed`: the user selected an action added
    with `appendingAction`, including actions appended by handlers.
    `onCancel` runs first, then the action.
- `finally { ... }` runs after all of the above, and after `onRetry`.
- Choose between `finally`, `onCancel`, `onRetry`, and the closure of an
  action according to the outcomes that must run your code. Switch on the
  reason when outcomes need different behaviors.

  ```swift
  // Intent: dismiss whatever happens to the error.
  // GOOD
  FlowError(error: error)
      .appendingAction("Delete Document", role: .destructive) { deleteDocument() }
      .finally { dismiss() }

  // BAD: the screen stays when a handler cancels the presentation,
  // or when the user selects an action appended by a handler.
  FlowError(error: error)
      .appendingAction("Delete Document", role: .destructive) {
          deleteDocument()
          dismiss()
      }
  ```

  ```swift
  // Intent: dismiss after deletion only, and keep the screen visible
  // otherwise, so that the user can fix the error.
  // GOOD
  FlowError(error: error)
      .appendingAction("Delete Document", role: .destructive) {
          deleteDocument()
          dismiss()
      }

  // BAD: also dismisses when the user selects "Open Settings" (appended
  // by a handler), because `onCancel` runs before every action added
  // with `appendingAction`.
  FlowError(error: error)
      .onCancel { _ in dismiss() }
      .appendingAction("Delete Document", role: .destructive) { deleteDocument() }
  ```

  ```swift
  // Intent: dismiss on cancel and on deletion, but not on "Open Settings".
  // GOOD
  FlowError(error: error)
      .onCancel { reason in
          switch reason {
          case .userCancelled, .presentationCancelled:
              dismiss()
          case .supplementaryActionPerformed:
              break
          }
      }
      .appendingAction("Delete Document", role: .destructive) {
          deleteDocument()
          dismiss()
      }
  ```

- Add an `onRetry` action at the catch site when:
  - The user can't retry otherwise: the screen offers no way to run
    the failed operation again.
  - Retrying by hand is not trivial: for example, the failed operation
    was an action on an item of a list, and the user may struggle to
    find that item again.
  - Trivial transient errors are expected (no network in Airplane
    Mode), and a Retry button helps the user recover quickly.

  ```swift
  func send(_ message: Message) async {
      do {
          try await messageService.send(message)
      } catch {
          flowError = FlowError(error: error)
              .withTitle("The message could not be sent")
              .onRetry { Task { await send(message) } }
      }
  }
  ```

  Add `onRetry` whatever the error: error handlers remove it when
  retrying can't help (see Handlers).

## Handlers

- A handler only sees the error; the catch site knows the operation.
  Put each action where its decision is made:
  - Error handlers add or remove actions that depend on the kind of
    error: append "Open Settings" for `CLError.denied`, drop the retry
    action for errors that retrying can't fix.
  - Catch sites add actions that depend on the failed operation:
    `onRetry`, or "Delete Document" after loading that document failed.

  ```swift
  // GOOD: "Open Settings" fixes CLError.denied, whatever the operation
  // that failed. A handler appends it.
  struct CLErrorDeniedHandler: FlowErrorHandler {
      func handle(_ flowError: FlowError) -> FlowErrorHandling {
          guard case CLError.denied = flowError.error else {
              return .pass(flowError)
          }
          return .present(ErrorPresentation(flowError: flowError
              // CLError.denied can't be retried until the user grants
              // permission.
              .droppingRetryAction()
              .appendingAction("Open Settings") { openSettings() }))
      }
  }

  // GOOD: "Delete Document" only makes sense because loading this
  // document failed, whatever the error. The catch site appends it.
  struct DocumentView: View {
      var url: URL
      @State private var document: Document?
      @State private var flowError: FlowError?
      
      var body: some View {
          DocumentContent(document: document)
              .presentError($flowError, with: .alert)
              .onAppear(perform: load)
      }
      
      func load() {
          do {
              document = try Document(url: url)
          } catch {
              flowError = FlowError(error: error)
                  .appendingAction("Delete Document", role: .destructive) {
                      deleteDocument(at: url)
                  }
          }
      }
  }

  // BAD: a handler that tries to recognize the failed operation.
  ContentView()
      .handleError { flowError in
          .pass(flowError.appendingAction("Delete Document", role: .destructive) {
              deleteDocument(at: url)
          })
      }
  ```

  The bad handler offers "Delete Document" for every error presented
  by `ContentView` and its subviews, such as a failed save. Attempts
  to filter (comparing flow error ids, inspecting view state) are
  fragile workarounds.

- When a handler appends an action, or starts handling more errors,
  review the in-place presentations that may now display the action,
  and set `allowMultipleActionExecutions` where needed (see In-place
  presentation).

## Sharing handlers between the app and its previews

Previews do not run the `App` body: handlers registered on the scene
are missing from previews, which then present the errors that these
handlers would have customized with the generic, redacted presentation
of FlowErrorKit. Gather the application-wide handlers in a single
chain, and register this same chain in the app and in every preview.

- Declare the chain once, as a static member, so that call sites read
  `.handleError(with: .defaultErrorHandlers)`:

  ```swift
  // FlowErrorHandler+defaultErrorHandlers.swift
  import FlowErrorKit

  extension FlowErrorHandler where Self == FlowErrorHandlerChain {
      /// The application-wide chain of flow error handlers, for the app
      /// and its previews.
      ///
      /// ```swift
      /// ContentView().handleError(with: .defaultErrorHandlers)
      /// ```
      static var defaultErrorHandlers: Self {
          FlowErrorHandlerChain([
              APIErrorHandler(),
              CoreLocationErrorHandler(),
              NotImplementedErrorHandler(),
          ])
      }
  }
  ```

- Register it on the scene, so that it covers all windows, sheets, and
  full screen covers:

  ```swift
  @main
  struct RecipesApp: App {
      var body: some Scene {
          WindowGroup {
              RootView()
          }
          .handleError(with: .defaultErrorHandlers)
      }
  }
  ```

- Register it in previews:

  ```swift
  #Preview("Network error") {
      NavigationStack {
          RecipeListView()
      }
      .recipeClient(.mock { throw URLError(.notConnectedToInternet) })
      .handleError(with: .defaultErrorHandlers)
  }
  ```

## Error texts

- At the catch site, give the flow error a title that names the failed
  operation (`.withTitle("The message could not be sent")`), unless the
  end user can't miss which operation has failed on this screen.

  The reason is that the end user should know which operation has
  failed, and why. Error handlers see the error, so they can explain
  why, with the title and message of the error presentation they
  return. But they do not know the failed operation: only the catch
  site does. When both provide a title, the title of the flow error is
  displayed first, and the title of the handler below it.
- Built-in presentations display the raw error in DEBUG builds: do not
  append debug details to titles or messages.
- String literals are localized and extracted to the string catalog: no
  `String(localized:)` nor `NSLocalizedString`.
- Literals resolve to SwiftUI's `LocalizedStringKey`: with the
  `MemberImportVisibility` upcoming feature, the file must
  `import SwiftUI`.
- `String` variables are displayed verbatim (like `Text`), such as
  server messages, which may already be localized.
- Never write `message ?? "Unknown user"`: the literal becomes a
  `String`, and is not localized. Branch instead, so that each value
  goes to the matching overload, and comment both branches so that
  nobody refactors them into `??`:

  ```swift
  if let message {
      return .present(ErrorPresentation(flowError: flowError, title: message)) // non localized
  } else {
      return .present(ErrorPresentation(flowError: flowError, title: "Unknown user")) // localized
  }
  ```

  Only comment this contrast. A `String` variable passed on its own
  needs no comment.

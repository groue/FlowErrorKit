---
name: flowerrorkit
description: Rules and pitfalls for SwiftUI code that uses FlowErrorKit (FlowError, ErrorPresentation, ErrorPresentationView, ErrorPresentationLabel, ErrorPresentationDescription, ErrorPresentationActions, FlowErrorHandler, FlowErrorHandlerChain, FlowErrorPresenter, presentError, handleError, errorHandler, onCancel, onRetry, finally, appendingAction, withError, allowMultipleActionExecutions, canPerformAction). Load before catching or presenting errors in SwiftUI views, writing or registering flow error handlers (including in the App and in #Preview), unwrapping errors that wrap other errors, writing error actions, or writing error titles and messages.
---

# FlowErrorKit

The sections follow the life of an error: it is caught and turned into
a flow error ([Creating and handling flow
errors](#creating-and-handling-flow-errors)), presented to the user
([Presenting flow errors](#presenting-flow-errors), [In-place
presentation](#in-place-presentation)), who selects one of its actions
([Actions](#actions)). Between the catch site and the presentation,
error handlers adapt the flow error to the kind of error
([Handlers](#handlers), [Wrapper errors](#wrapper-errors)). [Error
texts](#error-texts) applies to the catch sites and to the handlers.

Sections list rules. A "Why:" paragraph explains a rule only when the
rule alone does not settle a case it does not mention.

## Documentation and comments

- Learn the library from its DocC documentation, in the
  `Sources/FlowErrorKit/Documentation.docc` folder of the FlowErrorKit
  package checkout that the project builds with (for Xcode projects:
  `DerivedData/<Project>-<hash>/SourcePackages/checkouts/FlowErrorKit`;
  for Swift packages: `.build/checkouts/FlowErrorKit`; for a local
  package dependency: its path). Read `Usage.md` for the overall
  workflow, `FlowError.md` for error actions, `FlowErrorHandler.md` for
  error handlers, and the doc comments of public declarations for the
  details.
- Rely on the public API only. Never read the implementation (the
  bodies of declarations, and non-public declarations), even to check a
  behavior, to find a working example, or when a doc comment points to
  the source code.
- When the documentation does not answer a question that your code
  depends on (a behavior is undocumented, or the documentation
  contradicts what you observe at runtime), stop and ask the user for
  permission to read the implementation, and name the files and the
  question. Read them only after the user approves, and only for that
  question.
- Comment only what a reader could not learn from the code itself.
  Never write comments that justify following the rules of this skill
  (why an alert, why a retry action, why a title, why an unwrapping).

## Creating and handling flow errors

A `FlowError` is an event: an error was caught, the error handlers must
handle it once (and run their side effects, such as signing out), and
the user must select one of its actions once. The identity of the flow
error (`FlowError.id`) tracks both:

- Flow errors derived with `onRetry`, `withTitle`, `appendingAction`,
  `withError`, etc., including in error handlers, share this identity.
- Every `FlowError(error:)` call creates a new identity, with fresh
  actions.
- Once the user has selected an action, or the flow error was discarded
  (`flowError.discard(_:)`), `flowError.canPerformAction` is false, and
  presentations disable or hide the action buttons.

The rules below follow from this identity:

- Create the `FlowError` where the error is delivered: a `catch` clause,
  or a one-off callback (`onError:`, `.onReceive`, `fileImporter`…).
  When the caught error wraps another error, see [Wrapper
  errors](#wrapper-errors) before writing the `catch` clause.
- Never create a `FlowError` in a view `body`, and never store an
  `Error` (such as `Result<Value, Error>`) for views to read and turn
  into a `FlowError`. Models expose throwing methods, or deliver errors
  once through callbacks.

  Why: bodies are re-evaluated, and views are recreated. A flow error
  created there, or from a stored `Error`, would be handled again, and
  would offer again actions whose closures have already run.
- To display a flow error again, keep the `FlowError` instance (for
  example, in a SwiftUI-managed storage like `@State`). Never wrap its
  `error` in a new `FlowError(error:)`.
- Handle each flow error once: either present it with
  `presentError(_:with:)` (see [Presenting flow
  errors](#presenting-flow-errors)), or, when the view does not present
  it, pass it to `errorHandler.handle(_:)` (see [Errors that are not
  presented](#errors-that-are-not-presented)). Never both.
- Never handle a flow error during a view update: in a view `body` or
  initializer, or in the `update()` method of a `DynamicProperty`.
  Handle it in a button action, `.onAppear`, `.task`, etc.

  Why: the side effects of error handlers may modify SwiftUI state,
  which SwiftUI forbids during a view update.

## Presenting flow errors

Present the flow errors that the user must see with
`presentError(_:with:)`, and pick one of the two built-in
presentations, unless the application defines and prefers a custom
`FlowErrorPresenter`:

- By default, present an alert: `.presentError($flowError, with: .alert)`.
  This fits errors of actions (save, send, delete…), and errors of
  content that the view displays anyway (a web page, a list…).
- When the content of the screen could not be loaded, and the view has
  nothing better to show than the error, present the error in place:
  `.presentError($flowError, with: .errorPresentationView)` (see
  [In-place presentation](#in-place-presentation)).

Never display the result of `errorHandler.handle(_:)` yourself, unless
the rare cases described in
[references/custom-presentation.md](references/custom-presentation.md)
apply, and no ready-made presenter usable with `.presentError(_:with:)`
fits. Read that file before taking this path.

### Errors that are not presented

A view may choose not to present an error, so that it does not bother
the user: the error of an automatic refresh when the view displays
cached data, the error of a background task, etc. Never ignore such an
error: pass it to `errorHandler.handle(_:)`, so that the error handlers
of the environment run their side effects (such as signing out the user
after a 401 Unauthorized HTTP error). Ignore the returned value.

In the example below, the view displays cached news. The error of the
automatic refresh is not presented, because the user still sees the
cached news. The error of the refresh that the user asked for is
presented.

```swift
struct NewsView: View {
    @Environment(\.errorHandler) private var errorHandler
    @Environment(NewsStore.self) private var store
    @State private var flowError: FlowError?

    var body: some View {
        NewsList(news: store.news)
            .toolbar {
                Button("Refresh") {
                    Task { await refresh() }
                }
            }
            .presentError($flowError, with: .alert)
            .task { await automaticRefresh() }
    }

    func automaticRefresh() async {
        do {
            try await store.refresh()
        } catch {
            _ = errorHandler.handle(FlowError(error: error))
        }
    }

    func refresh() async {
        do {
            try await store.refresh()
        } catch {
            flowError = FlowError(error: error)
                .withTitle("The news could not be refreshed")
        }
    }
}
```

## In-place presentation

`.presentError($flowError, with: .errorPresentationView)` displays an
`ErrorPresentationView` in place of the view content (for example,
content that could not be loaded), until `flowError` is set to nil.
Unlike an alert, the error view does not go away when the user selects
an action. Follow the rules below.

- Apply `presentError` to the content that the error replaces. The
  modifiers applied before `presentError` are replaced as well: apply
  the modifiers that must remain visible (`navigationTitle`, `toolbar`,
  etc.) after `presentError`.
- When the error view goes away, the content is created again: the
  state of its subviews is reset, and its `task` and `onAppear`
  modifiers run again. Apply the modifiers that load the content after
  `presentError`, never before. Otherwise, the content loads twice after
  a successful retry.
- To customize the error view, use `.errorPresentationView {
  errorPresentation in ... }`, and display `errorPresentation` with the
  view of your choice. You can use `ErrorPresentationView`, compose a
  `ContentUnavailableView` from
  `ErrorPresentationLabel(errorPresentation)`,
  `ErrorPresentationDescription(errorPresentation)`, and
  `ErrorPresentationActions(errorPresentation, cancelButton:)`, or
  render any other view.
- The error view hides the content, even when the content becomes
  available. Set `flowError = nil` as soon as the content is available.
  Otherwise, the user is stuck on the error.
- To load a value that may fail, load from `.onAppear` with a guard so
  that it runs once, and catch there. Give the view some content before
  loading (a `ProgressView`, `Color.clear`): `onAppear` does not run on
  an empty view.

  ```swift
  struct RecipeView: View {
      var recipeID: Recipe.ID
      @Environment(RecipeClient.self) private var client
      @State private var recipe: Recipe?
      @State private var flowError: FlowError?
      @State private var didStartLoading = false

      var body: some View {
          Group {
              if let recipe {
                  RecipeContent(recipe: recipe)
              } else {
                  // While loading, and when a handler cancels the
                  // presentation of the error.
                  ProgressView()
              }
          }
          .presentError($flowError, with: .errorPresentationView)
          .onAppear {
              guard !didStartLoading else { return }
              didStartLoading = true
              Task { await load() }
          }
      }

      func load() async {
          do {
              recipe = try await client.recipe(id: recipeID)
          } catch {
              flowError = FlowError(error: error)
                  .withTitle("The recipe could not be loaded")
                  .onRetry {
                      // Removes the error view while loading.
                      flowError = nil
                      Task { await load() }
                  }
          }
      }
  }
  ```

- After the user selects an action, the error view remains on screen,
  with disabled buttons. Make sure that every action that
  can be presented dismisses the screen, or clears or replaces the flow
  error binding (`flowError = nil`, or `flowError = FlowError(error:
  newError)`). Otherwise (for example "Open Settings", appended by a
  handler), create the flow error with
  `allowMultipleActionExecutions: true`, so that the buttons remain
  enabled, and the user can select an action again.

  ```swift
  // GOOD: back from Settings, the user can select "Open Settings"
  // (appended by a handler) again.
  flowError = FlowError(error: error, allowMultipleActionExecutions: true)
      .onRetry { Task { await load() } }

  // BAD: back from Settings, the buttons are disabled, and the user
  // is stuck.
  flowError = FlowError(error: error)
      .onRetry { Task { await load() } }

  // GOOD: every outcome removes the error from the screen.
  flowError = FlowError(error: error)
      .finally { dismiss() }
  ```

- The actions that can be presented are those added by the catch site,
  and those that the handlers in scope append to the errors that the
  failed operation can actually throw, including the inner errors that
  are unwrapped (see [Wrapper errors](#wrapper-errors)). Ignore the
  other actions. For example, a handler that appends "Open Settings" to
  `CLError.denied` does not matter when the failed operation is a load
  from a local database: this load never throws `CLError`.
- With `allowMultipleActionExecutions: true`, write the closures of
  `onRetry`, `onCancel`, `finally`, and `appendingAction` so that they
  can run several times.

## Actions

- Choose between `finally`, `onCancel`, `onRetry`, and the closure of an
  action according to the outcomes that must run your code. Switch on
  the cancel reason when outcomes need different behaviors.

  Why: `onCancel { reason in ... }` does not only run when the user
  taps a Cancel button. Its closure runs with one of these reasons:
  - `.userCancelled`: the user tapped Cancel. In-place presentations
    hide this button by default.
  - `.presentationCancelled`: a handler returned `.cancel`, or the
    error was replaced or discarded, by a presenter or by your code.
  - `.supplementaryActionPerformed`: the user selected an action added
    with `appendingAction`, including actions appended by handlers.
    `onCancel` runs first, then the action.

  `finally { ... }` runs after all of the above, and after `onRetry`.

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

- You can assume that action closures run at most once, unless the
  flow error was created with `allowMultipleActionExecutions: true`
  (see [In-place presentation](#in-place-presentation)).
- Make sure the user is never stuck after dismissing an error. When the
  screen offers no way to perform the failed operation again, add one:
  a Save, Reload, or Submit button, pull to refresh, etc.

  When such a control makes little sense on the screen, add `onRetry`
  instead. But the user can still dismiss the error without retrying.
  If the screen then leaves the user stuck, look for a way out, such as
  dismissing the screen (see the cancel reasons of `onCancel` above).
  If you can't find one, ask the developer what the app should do when
  the user dismisses the error.

  Why: `onRetry` only helps while the error is presented. Once the user
  dismisses it, only the screen can offer recovery.
- Also add `onRetry` when the screen offers a control to perform the
  failed operation again, and:
  - Retrying by hand is not trivial: for example, the failed operation
    was an action on an item of a list, and the user may struggle to
    find that item again.
  - Or trivial transient errors are expected (no network in Airplane
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

- Add `onRetry` without checking the nature of the error: error
  handlers remove it, with `droppingRetryAction()`, when retrying can't
  help (see [Handlers](#handlers)).

## Handlers

- Put each action where its decision is made:
  - Error handlers add or remove actions that depend on the kind of
    error: append "Open Settings" for `CLError.denied`, drop the retry
    action for errors that retrying can't fix.
  - Catch sites add actions that depend on the failed operation:
    `onRetry`, or "Delete Document" after loading that document failed.

  Why: a handler only sees the error; the catch site knows the
  operation.

  ```swift
  // GOOD: "Open Settings" fixes CLError.denied, whatever the operation
  // that failed. A handler appends it, and drops the retry action, which
  // can't help until the user grants permission.
  struct CLErrorDeniedHandler: FlowErrorHandler {
      func handle(_ flowError: FlowError) -> FlowErrorHandling {
          guard case CLError.denied = flowError.error else {
              return .pass(flowError)
          }
          return .present(ErrorPresentation(flowError: flowError
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

- In a handler, derive flow errors from the flow error it receives
  (`.droppingRetryAction()`, `.appendingAction(...)`, `.withError(...)`,
  etc.). Never create a new `FlowError` in a handler.

  Why: a new flow error loses the identity of the caught error (see
  [Creating and handling flow
  errors](#creating-and-handling-flow-errors)).
- When a handler appends an action, or starts handling more errors,
  review the in-place presentations that may now display the action,
  and set `allowMultipleActionExecutions` where needed (see [In-place
  presentation](#in-place-presentation)).

### Registering handlers

Handlers form a chain. Each handler passes the flow error to the next
one, presents it, or cancels it. Handlers registered closer to the
presenting view come first. In a
`FlowErrorHandlerChain`, the first handler of the array comes first.
The built-in handlers of FlowErrorKit, for `CancellationError`,
`CocoaError`, and `URLError`, always come last, after all registered
handlers.

Gather the application-wide handlers in a single chain, and register
this same chain in the app and in every preview:

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

Why: previews do not run the `App` body. Without the shared chain,
handlers registered on the scene are missing from previews, which then
present the errors that these handlers would have customized with the
generic, redacted presentation of FlowErrorKit.

## Wrapper errors

A wrapper error carries an inner error, in an enum case with an
associated `Error` value
(`WebPage.NavigationError.failedProvisionalNavigation(_:)`,
`AFError.sessionTaskFailed(error:)` in Alamofire), in a property of
type `Error` (`underlyingError`, `cause`…), or in the
`NSUnderlyingErrorKey` of the `userInfo` of an `NSError`. Wrapper
errors come from the SDK, from libraries, and from the application
itself (an API client that wraps the `URLError` of its requests).

A handler is written for specific errors, and does not know the
wrapper errors that may carry them: it can't unwrap them. Unless a
handler handles the wrapper error, the user gets the generic
presentation instead of the one that the handlers of the inner error
would have provided.

- Before writing a `catch` clause, read the declarations of the errors
  that the failing operation throws, and look for wrapper errors.
- For each wrapper error, look for the handlers of the wrapper error,
  and of its inner errors: the built-in handlers, and the handlers of
  the application (see [Registering handlers](#registering-handlers)).
  Find where the application registers its handlers, with
  `handleError(with:)` or `handleError { ... }`, and read which errors
  they handle.
- When a handler handles the wrapper error, do not unwrap it: create
  the flow error from the caught error, as usual.
- Otherwise, when a handler handles the inner error, unwrap the
  wrapper error in one of two places:
  - At the catch site, by creating the flow error from the inner
    error. This fits as long as no other catch site unwraps the same
    wrapper error.
  - In a new handler that passes `flowError.withError(innerError)` (see
    the doc comment of `FlowErrorHandlerChain`). This fits when several
    catch sites unwrap the same wrapper error: when reviewing code,
    replace their unwrapping with this handler. Register it before the
    handlers of the application that handle the inner error. It comes
    before the built-in handlers wherever it is registered.

  Unwrapping depends on the kind of error, like the actions that
  handlers add or remove (see [Handlers](#handlers)). Unlike these
  actions, it can stay at the catch site while that catch site is the
  only one that needs it.
- Otherwise, create the flow error from the caught error, as usual.

The two examples below unwrap the inner error of
`WebPage.NavigationError.failedProvisionalNavigation(_:)`, often a
`URLError` that the built-in `URLError` handler handles. Take them as
an inspiration, and pick the place where to unwrap according to the
context of the application, as described above.

When no other catch site loads web pages, the catch site unwraps:

```swift
func load() async {
    do {
        for try await _ in page.load(URLRequest(url: url)) { }
    } catch {
        let error = if case WebPage.NavigationError.failedProvisionalNavigation(let innerError) = error {
            innerError
        } else {
            error
        }
        flowError = FlowError(error: error)
            .withTitle("The page could not be loaded")
            .onRetry { Task { await load() } }
    }
}
```

When several catch sites load web pages, a handler unwraps, and the
catch sites create their flow errors from the caught error, as usual:

```swift
struct WebPageNavigationErrorHandler: FlowErrorHandler {
    func handle(_ flowError: FlowError) -> FlowErrorHandling {
        guard case WebPage.NavigationError.failedProvisionalNavigation(let innerError) = flowError.error else {
            return .pass(flowError)
        }
        return .pass(flowError.withError(innerError))
    }
}
```

Add this handler to the `defaultErrorHandlers` chain (see [Registering
handlers](#registering-handlers)), before the handlers of the
application that handle `URLError`.

## Error texts

- At the catch site, give the flow error a title that names the failed
  operation (`.withTitle("The message could not be sent")`), unless the
  end user can't miss which operation has failed on this screen.

  Why: the end user should know which operation has failed, and why.
  Error handlers see the error, so they can explain why, with the title
  and message of the error presentation they return. But they do not
  know the failed operation: only the catch site does. When both
  provide a title, the title of the flow error is displayed first, and
  the title of the handler below it.
- Do not append debug details to titles or messages.

  Why: built-in presentations display the raw error in DEBUG builds.
- In the app target, write titles and messages as string literals.
  Never use `String(localized:)` nor `NSLocalizedString`.

  Why: string literals are localized and extracted to the string
  catalog of the app.
- In a Swift package, pass a `LocalizedStringResource` that is looked
  up in the bundle of the package. Create it according to the
  localization conventions of the package, or of the packages around
  it.

  Why: string literals are looked up in the main bundle, not in the
  bundle of the package (`Bundle.module`).
- In files that pass literals, `import SwiftUI`.

  Why: literals resolve to SwiftUI's `LocalizedStringKey`, which needs
  the import with the `MemberImportVisibility` upcoming feature.
- Pass `String` variables, such as server messages that may already be
  localized, when the text must be displayed verbatim (like `Text`).
- Never write `message ?? "Unknown user"`. Branch instead, so that each
  value goes to the matching overload, and comment both branches so
  that nobody refactors them into `??`:

  ```swift
  if let message {
      return .present(ErrorPresentation(flowError: flowError, title: message)) // non localized
  } else {
      return .present(ErrorPresentation(flowError: flowError, title: "Unknown user")) // localized
  }
  ```

  Only comment this contrast. A `String` variable passed on its own
  needs no comment.

  Why: with `??`, the literal becomes a `String`, and is not localized.

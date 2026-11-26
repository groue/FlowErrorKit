# Releasing a New Version

This checklist describes how to publish a new version of FlowErrorKit. Follow it in order, replacing `X.Y.Z` with the new version number.

## 1. Check the code

- Run the tests: `swift test`.
- Build the demo app (`Documentation/FlowErrorDemo`) and the test app (`Tests/FlowErrorTestApp`), so that API changes did not break them.
- Build the documentation, and fix any DocC warning: in Xcode, Product > Build Documentation.

## 2. Update the agent skill

The skill in `skills/flowerrorkit/SKILL.md` teaches coding agents how to use the library.

- If the release changes the public API or the recommended usage, update the rules in `SKILL.md`.
- Set `version` in `.claude-plugin/plugin.json` to `X.Y.Z`. Claude Code relies on this version to notice the update: when it does not change, users who installed the plugin keep the old skill.

## 3. Update the documents

- Add a `## X.Y.Z` section at the top of `CHANGELOG.md`, with the release date and the notable changes.
- If the minimum OS versions or the Swift version changed, update the **Requirements** line of `README.md`.
- If the README samples changed, or if the look of alerts or `ErrorPresentationView` changed, update the screenshots (see below).

### Updating the README screenshots

The four screenshots in `Documentation/Images` come from the app in `Documentation/ReadMeApp`: `Alert` and `ErrorPresentationView`, each in `light` and `dark` mode.

1. Run the app in the simulator of an iPhone with a notch, in the **Release** configuration (in Debug, presented errors include a "DEBUG" description), and take screenshots.

2. Draw each screenshot inside the device bezel, with the device type of the simulator. The script below currently only supports @3x iPhones with a notch: it does not draw the Dynamic Island, and does not support @2x devices such as the iPhone SE.

    ```bash
    swift Documentation/ReadMeApp/FrameScreenshot.swift <device-type> <screenshot.png> Documentation/Images/<name>.png
    ```

## 4. Publish

Commit all changes, then tag the release and push:

```bash
git push origin main
git tag X.Y.Z
git push origin X.Y.Z
```

Then create a GitHub release from the tag.

# Session Replay

## Overview

Session Replay captures a visual representation of your app's UI and sends it to the Contentsquare platform. You can view replays to understand how users interact with your app, find UX issues, and debug problems.

Session Replay is enabled automatically when you call `CSQ.start()`. No additional setup is needed unless you want to configure masking or manually control the SR lifecycle.

---

## Masking

Masking hides sensitive content in the replay so it's never recorded or sent to Contentsquare.

### Global masking

Use `setDefaultMasking(true)` to mask everything by default, then selectively unmask safe content:

```swift
CSQ.setDefaultMasking(true)
CSQ.unmask(safeView)
```

Or mask specific categories globally:

```swift
CSQ.maskTexts(true)       // UILabel, SwiftUI Text
CSQ.maskImages(true)      // UIImageView, SwiftUI Image
CSQ.maskTextInputs(true)  // UITextField, UITextView, SwiftUI TextField/SecureField/TextEditor
```

> When `setDefaultMasking(false)` is called, text inputs (`UITextField`, `UITextView`, SwiftUI `TextField`, `TextEditor`) remain masked regardless.

### Per-view masking (UIKit)

```swift
// Programmatic
CSQ.mask(view)
CSQ.unmask(view)

// IBInspectable (Interface Builder)
view.csqMaskContents = true
```

### Per-view masking (SwiftUI)

```swift
SensitiveView()
    .csqMaskContents(true)
```

### Mask all views of a type (DXA only)

```swift
CSQ.mask(viewsOfType: UILabel.self)
CSQ.unmask(viewsOfType: UILabel.self)
```

Exceptions: views explicitly masked/unmasked with `mask(_:)` / `unmask(_:)` take precedence.

### What each method masks

| Method | What gets masked |
|--------|-----------------|
| `maskTexts(true)` | `UILabel`, SwiftUI `Text` |
| `maskTextInputs(true)` | `UITextField`, `UITextView`, SwiftUI `TextField`, `SecureField`, `TextEditor` |
| `maskImages(true)` | `UIImageView`, SwiftUI `Image` |
| `mask(_ view:)` | The specific view and its subviews |
| `mask(viewsOfType:)` | All instances of a UIView subclass |
| `setDefaultMasking(true)` | Everything (text inputs always masked) |

### Masking rules and priority

The SDK evaluates rules in order; the first matching rule wins:

1. App or SDK version is fully masked (configured in the CSQ console).
2. Remote Text or Image masking (CSQ console).
3. Remote screen masking (CSQ console). The screen is masked.
4. Per-instance mask/unmask (`CSQ.mask(view)` / `CSQ.unmask(view)`).
5. Per-parent mask/unmask (parent view masked or unmasked).
6. Per-type mask/unmask (`CSQ.mask(viewsOfType:)` / `CSQ.unmask(viewsOfType:)`).
7. Parent type masked or unmasked.
8. Remote Text or Image unmasking (CSQ console).
9. Remote screen unmasking (CSQ console).
10. Default masking state (`CSQ.setDefaultMasking(...)`).

### Exception: text inputs

`UITextField`, `UITextView` and SwiftUI `TextField` follow a stricter order: app or SDK version fully masked, remote text inputs masking, remote screen masking, per-instance, per-type, then masked by default. Default masking, parent masking and remote screen unmasking do **not** unmask them.

### Remote screen masking scope

Remote screen masking (CSQ console, closed beta) applies only to the content of the screen, that is the views of the matching view controller. It does not cover the navigation bar, the tab bar, or any other element owned by a parent container controller, and no screen-name or tracking call changes that. If those elements show sensitive content (for example a navigation title containing a user name), mask them explicitly with `CSQ.mask(view)`, such as `CSQ.mask(navigationController.navigationBar)`.

### Screen names for remote screen masking

Remote screen masking matches on the screen name. Enable native autocapture in `CSQ.start` so UIKit screens are named automatically, without any API call. Remote screen masking needs it, as on Android and Flutter, where it is required:

```swift
CSQ.start(environmentID: "your-env-id", options: [.enableNativeAutocapture: true])
```

SwiftUI screens are not captured by autocapture: set the name on the screen's root view with `.csqScreenName(_:)`:

```swift
PaymentView()
    .csqScreenName("Payment")
```

`.modifier(ScreenNameViewModifier(screenName: "Payment"))` is equivalent.

### Ignoring interactions

```swift
// UIKit (programmatic)
CSQ.ignoreInteractions(view)

// UIKit (IBInspectable)
view.csqIgnoreInteractions = true
view.csqIgnoreInnerHierarchy = true

// SwiftUI
SomeView()
    .csqIgnoreInteractions(true)
```

---

## Triggering Replays

By default, Session Replay runs automatically. You can also trigger replays explicitly for segmentation:

```swift
CSQ.triggerReplayForCurrentSession(name: "checkout_error")
CSQ.triggerReplayForCurrentScreen(name: "payment_screen")
```

The `name` parameter creates a segmentation event so you can filter and find these replays in the Contentsquare platform. Using these APIs requires that ETR is enabled for your project.

---

## On-demand Session Replay

To prevent SR from starting at SDK launch and control it manually:

```swift
// 1. Disable auto-start using the start overload for your integration type

// DXA only
CSQ.start(options: [.sessionReplayAutoStart: false])

// PA with data source ID (preferred)
CSQ.start(dataSourceID: "your-data-source-id", options: [.sessionReplayAutoStart: false])

// PA with environment ID
CSQ.start(environmentID: "your-env-id", options: [.sessionReplayAutoStart: false])

// 2. Start SR once, when entering the flow you want to record
CSQ.startSessionReplay()

// 3. Stop SR when done. This is terminal -- SR cannot be restarted
//    in the same SDK lifetime. Do NOT call this in viewDidDisappear
//    or any short-lived lifecycle if you may want SR again later.
CSQ.stopSessionReplay()
```

| Method | Effect |
|--------|--------|
| `startSessionReplay()` | Starts SR on-demand. Behaves like automatic start once invoked. **One-shot** -- intended to be called at most once per SDK lifetime when `sessionReplayAutoStart: false`. |
| `stopSessionReplay()` | Stops SR only. Other tracking (events, screenviews, identity, etc.) keeps running. **Terminal** -- once called, SR cannot be restarted. Use `CSQ.stop()` to stop everything. |

> **No restart support.** This is not a pause/resume mechanism. Plan accordingly: start SR at the beginning of the journey you want to record, and only call `stopSessionReplay()` when you are certain the recording is complete for the rest of the session.

---

## Known Limitations

- **WebViews**: Not captured by Session Replay. Every `WKWebView` must be registered with `CSQ.registerWebView(_:)` for session stitching -- see the **WebView Tracking** section in [SKILL.md](../SKILL.md).
- **Animations**: Captured at periodic intervals, not frame-by-frame.
- **Metal / OpenGL views**: Not captured.

---

## Debugging

```swift
CSQ.logLevel = .debug

CSQ.metadata.onChange { metadata in
    print("Session Replay URL: \(metadata.sessionReplayURL?.absoluteString ?? "none")")
}
```

---

## Further Reading

- [Session Replay documentation](https://docs.contentsquare.com/ios/session-replay/)
- [iOS compatibility](https://docs.contentsquare.com/en/ios/compatibility/)

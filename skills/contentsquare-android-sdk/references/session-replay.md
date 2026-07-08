# Session Replay — Android

## Overview

Session Replay captures a visual representation of your app's UI as users navigate, and sends it to the Contentsquare platform. You can review replays to understand user behavior, identify UX issues, and debug problems.

Session Replay is part of **Experience Analytics**. With `CSQ.start(context)`, Session Replay starts automatically (controlled by the project's sampling rate). To disable automatic start and pilot it manually, set `sessionReplayAutoStart = false` in `AnalyticsOptions`.

> Data collection for Session Replay starts at the **first screenview event** of the session. Without `CSQ.trackScreenview(...)`, no replay data is collected.

## Verifying Session Replay is running

After starting the SDK and triggering at least one screenview, look for:

```
CSLIB|SessionReplay: Session Replay is starting.
```

Replays are **available within 5 minutes** in the Contentsquare console. Only "ended screenviews" are processed (a screenview is considered ended when the next one starts).

In-app features can be enabled to access the current session's replay link directly from the device.

## Personal Data Masking

By default, **everything is masked**. Unmask explicitly the elements you want visible.

### Masking rules and priority

The SDK evaluates rules in order; the first matching rule wins:

1. App or SDK version is fully masked (configured in the CSQ console).
2. Remote Text or Image masking (configured in the CSQ console).
3. Per-instance mask/unmask (`CSQ.mask(view)` / `CSQ.unmask(view)`).
4. Per-type mask/unmask (`CSQ.mask(View::class.java)` / `CSQ.unmask(...)`).
5. Per-parent mask/unmask (parent view masked).
6. Parent type masked.
7. Remote Text or Image unmasking (CSQ console).
8. Default masking state (`CSQ.setDefaultMasking(...)`).

### Exception: text inputs

`EditText` and Compose `TextField` follow a stricter rule set — `setDefaultMasking(false)` and parent unmasking do **not** unmask them. They must be explicitly unmasked by instance or by type.

## Public Masking APIs

### Global default

```kotlin
CSQ.setDefaultMasking(true)  // mask everything (default)
CSQ.setDefaultMasking(false) // unmask everything by default
```

> `setDefaultMasking(false)` does NOT unmask `EditText` / Compose `TextField`.

### Mask all text

```kotlin
CSQ.maskTexts(true)
```

### Per-instance (Views)

```kotlin
CSQ.mask(sensitiveView)
CSQ.unmask(safeView)

// Kotlin extension
view.csqMaskContents(enable = true)
```

### Per-type (Views, EA only)

```kotlin
CSQ.mask(EditText::class.java)
CSQ.unmask(TextView::class.java)
```

> Not available for Compose. Wrap a parent composable in `CsqMask` instead.

### Compose

```kotlin
import com.contentsquare.api.compose.CsqMask

CsqMask(enable = true) {
    Text("Sensitive content")
}

// Mask a parent, unmask a child
CsqMask(true) {
    Column {
        CsqMask(false) {
            Text("Visible")    // explicitly unmasked
        }
        Text("Masked")          // inherits parent masking
    }
}
```

### Ignoring interactions

```kotlin
// Views
CSQ.ignoreInteractions(view)
view.csqIgnoreInteractions()

// Compose
CsqIgnoreInteraction(ignore = true) {
    Button(onClick = { }) { Text("Not tracked") }
}
```

### Special composable tagging

For material `ModalBottomSheetLayout`, use `CsqTag` to enable proper Zoning/Heatmap capture:

```kotlin
CsqTag(CsqTag.ModalBottomSheetLayout) {
    ModalBottomSheetLayout(
        sheetContent = { /* sheet */ }
    ) {
        // main content
    }
}
```

### Dialogs (Views)

Dedicated extension functions on `AlertDialog`, `DatePickerDialog`, and `TimePickerDialog`:

```kotlin
val builder = AlertDialog.Builder(context)
    .setTitle("Confirmation")
    .setMessage("This text is masked")
    .setPositiveButton("Close") { _, _ -> }
    .setNegativeButton("Cancel") { _, _ -> }

val dialog = builder.create()
dialog.show()
// Apply masking AFTER show(), on the main thread:
dialog.csqUnmaskTitle()
dialog.csqUnmaskPositiveButton()
dialog.csqUnmaskNegativeButton()
```

Available on `AlertDialog`:

- `csqMask()` / `csqUnmask()`
- `csqMaskTitle()` / `csqUnmaskTitle()`
- `csqMaskMessage()` / `csqUnmaskMessage()`
- `csqMaskPositiveButton()` / `csqUnmaskPositiveButton()`
- `csqMaskNegativeButton()` / `csqUnmaskNegativeButton()`

Available on `DatePickerDialog`:

- `csqMask()` / `csqUnmask()`
- `csqMaskHeader()` / `csqUnmaskHeader()`
- `csqMaskCalendar()` / `csqUnmaskCalendar()`
- `csqMaskButtonPanel()` / `csqUnmaskButtonPanel()`

Available on `TimePickerDialog`:

- `csqMask()` / `csqUnmask()`
- `csqMaskHeader()` / `csqUnmaskHeader()`
- `csqMaskRadialPicker()` / `csqUnmaskRadialPicker()`
- `csqMaskInputMode()` / `csqUnmaskInputMode()`
- `csqMaskButtonPanel()` / `csqUnmaskButtonPanel()`

For custom dialogs (extending `Dialog`), use the standard `CSQ.mask(view)` / `CSQ.unmask(view)` APIs on individual children.

### Menus (Views)

```kotlin
override fun onCreateOptionsMenu(menu: Menu): Boolean {
    menuInflater.inflate(R.menu.activity_main, menu)
    CSQ.unmaskMenuItem(R.id.action_settings)
    CSQ.maskMenuItem(R.id.profile_settings) // contains the user's name
    return true
}
```

## Where to call masking

- **Activity** → `onCreate()`
- **Fragment** → `onViewCreated()`
- Always **before the first draw** and **on the UI thread**.

The SDK stores masked elements in a `WeakHashMap`; calling the same masking API multiple times on the same view simply overrides the previous value, with no performance penalty.

## Event-Triggered Replays (ETR)

Optional add-on. When ETR is enabled, only sessions/screens matching the global sample rate or associated with an ETR event are retained server-side.

```kotlin
CSQ.triggerReplayForCurrentSession(name = "checkout_funnel")
CSQ.triggerReplayForCurrentScreen(name = "payment_failure")
```

> Even when ETR is enabled, all sessions still generate network activity — collection happens upfront, server-side filtering happens after.

## Retrieving the replay URL

```kotlin
val replayUrl = CSQ.metadata.sessionReplayUrl

// Or subscribe to changes:
CSQ.metadata.onChanged = OnMetadataChanged { metadata ->
    val link = metadata.sessionReplayUrl
    // Forward to your CRM, crash reporter, etc.
}
// Unregister:
CSQ.metadata.onChanged = null
```

> The URL is only valid once the session is tracked (user opted in, not blocked) and at least one screenview has been sent.

## URL Masking (used in error tracking)

```kotlin
CSQ.setUrlMaskingPatterns(listOf("/users/[0-9]+", "/orders/[A-Z0-9-]+"))
```

Emails in URLs are masked automatically.

## Known limitations

- **`SurfaceView`** — not supported. Will appear as white views (covers video streaming and camera previews — useful for privacy).
- **Animations + masking by instance/type** — masking rules don't follow the animated bounding box. Solutions:
  - Mask the parent view, OR
  - Use `setDefaultMasking(true)` for the screen and reverse it on screen exit.
- **Maps** — can be masked as a whole (captured as an image), but individual map elements cannot be selectively masked.
- **Fragments with transition animations** — masking rules don't apply during transitions. Mask the container view instead of the fragment content.
- **Rotated / scaled views** — bounding box no longer matches actual position; mask the parent or the entire window for safety.
- **Transparent views over `WebView`** — unmasked overlays may leak the WebView content underneath.
- **Compose** — masking by type is unavailable. Wrap a parent composable with `CsqMask`.
- **WebView native content** — not captured by native Session Replay. Use the Contentsquare WebView Tracking Tag inside the loaded web pages.
- **Long screenshots** — the server enforces ~75 MB max payload. Very long/heavy screens may be rejected — capture a shorter area or simpler content.

## Best Practices

1. **Mask everything by default** — keep `setDefaultMasking(true)` (the default) and unmask only what you need visible.
2. **Audit sensitive screens** — profile, checkout, settings: review and add masking explicitly.
3. **Use `TriggeredOnResume`** in Compose to avoid duplicate screenviews on recomposition.
4. **Send your first screenview right after `start()`** if you need data collected from launch.
5. **Enable debug logs** during development: `CSQ.debug.logLevel = LogLevel.DEBUG` (`import com.contentsquare.api.model.LogLevel`).
6. **Tag special composables** (`ModalBottomSheetLayout`) with `CsqTag` for correct Zoning/Heatmap capture.
7. **Test on a real device** — emulators may be blocked by company VPNs/firewalls and produce no replay.

## Live source of truth

This file is a local mirror. The official, always-up-to-date documentation is at:

- **Session Replay (Android):** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/session-replay/index.md
- **Privacy & masking rules:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/privacy/index.md
- **Troubleshooting:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/troubleshooting/index.md

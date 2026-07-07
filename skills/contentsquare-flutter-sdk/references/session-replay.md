# Session Replay

## Overview

Session Replay captures a visual representation of your app's UI and sends it to the Contentsquare platform. You can view replays to understand how users interact with your app, find UX issues, and debug problems.

Session Replay is enabled automatically when you call `CSQ().start()`. No additional setup is needed unless you want to configure masking or manually trigger replays.

## Masking

Masking hides sensitive content in the replay so it's never recorded or sent to Contentsquare.

### Global masking (at SDK start)

Applies to your entire app:

```dart
await CSQ().start(
  maskingConfig: const CSQMaskingConfig(
    maskTexts: true,
    maskTextFields: true,
    maskImages: false,
  ),
);
```

### Scoped masking (per widget)

Use `CSQMask` to mask a specific part of the widget tree:

```dart
CSQMask(
  config: const CSQMaskingConfig(maskTextFields: true),
  child: CreditCardForm(),
)
```

### Default masking

When no `maskingConfig` is provided, the SDK applies sensible defaults. See [default masking docs](https://docs.contentsquare.com/en/flutter/session-replay/#default-masking).

### What each field masks

| Field              | What gets masked     | Example widgets                                 |
| ------------------ | -------------------- | ----------------------------------------------- |
| `maskTexts`        | All text content     | `Text`, `RichText`                              |
| `maskTextFields`   | Input field content  | `TextField`, `TextFormField`                    |
| `maskImages`       | Image content        | `Image`, `Image.network`, `Image.asset`         |
| `maskSvgImages`    | SVG pictures         | `flutter_svg` widgets                           |
| `maskCharts`       | Chart content        | `fl_chart` widgets                              |
| `maskCustomPaints` | Custom-drawn content | Your `CustomPaint` widgets (not framework ones) |
| `maskInteractions` | User interactions    | Taps, swipes (Product Analytics only)           |

### Masking precedence

Scoped masking (`CSQMask`) overrides global masking for its subtree. If a field is `null` in the scoped config, the global config value applies.

### Convenience factories

- `CSQMaskingConfig.maskAll()` -- masks everything
- `CSQMaskingConfig.unMaskAll()` -- masks nothing (use with caution: ensure no sensitive content is displayed)

## Triggering Replays (Event-Triggered Replays / ETR)

By default, Session Replay runs automatically. Event-Triggered Replays (ETR) lets you flag specific sessions or screens so they can be filtered in the player and used to drive segmentation events.

### Prerequisites

- ETR must be **enabled in the customer contract** -- contact CSM/Implementation Manager. Without it, the calls below succeed but produce no usable filter.

### APIs

```dart
await CSQ().triggerReplayForCurrentSession(name: 'checkout_error');
await CSQ().triggerReplayForCurrentScreen(name: 'payment_screen');
```

The `name` parameter is surfaced as the "ETR event" in the Session Player event stream.

### Important caveats

- **Network activity is global.** When ETR is enabled the SDK collects data on every session even if no `triggerReplay*` call is made. Only the sessions/screens matching the global sampling rate or an ETR trigger are retained server-side. Expect background traffic on every session.
- **Mask everything that could leak PII.** Even screens not associated with an ETR trigger may be retained -- masking must cover the full app, not just the ETR-flagged screens.

## On-demand Session Replay (4.2.0+)

To prevent SR from starting at SDK launch and control it manually:

```dart
await CSQ().start(
  startConfig: StartConfig.dxa(
    options: const AnalyticsOptions(sessionReplayAutoStart: false),
  ),
);

// Start SR once, when entering a flow you want to record:
await CSQ().startSessionReplay();

// Stop SR without stopping the rest of the SDK. This is terminal -- SR
// cannot be re-started afterwards in the same SDK lifetime.
await CSQ().stopSessionReplay();
```

| Method                 | Effect                                                                                                                                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `startSessionReplay()` | Starts SR. Behaves like the automatic start once invoked. **One-shot:** intended to be called at most once when `sessionReplayAutoStart: false`.                                                                                      |
| `stopSessionReplay()`  | Stops SR only. Other tracking (events, pageviews, identify, etc.) keeps running. **Terminal:** once called, SR cannot be re-started -- subsequent `startSessionReplay()` calls have no effect. Use `CSQ().stop()` to stop everything. |

> **No restart support.** This API only handles **starting** and **stopping** SR -- it is not a pause/resume mechanism. Plan the customer's flow accordingly: start SR at the beginning of the journey you want to record, and only call `stopSessionReplay()` when you are sure the recording is complete for the rest of the session.

Pair this with `sessionReplayAutoStart: false` for a fully manual SR lifecycle.

## Known Limitations

- **Charts** (fl_chart): set `maskCharts: true` to mask them properly
- **Animations**: captured at periodic intervals, not frame-by-frame
- **Platform views** (e.g., native maps, WebViews): not captured by Session Replay. WebViews require `CSQWebViewWrapper` for tracking — see the **WebView Tracking** section in [SKILL.md](../SKILL.md)

## Debugging

```dart
CSQ().debug.setLogLevel(LogLevel.verbose);

CSQ().metadata.onChange((metadata) {
  print('Session Replay URL: ${metadata.sessionReplayUrl}');
});
```

## Further Reading

- [Session Replay documentation](https://docs.contentsquare.com/en/flutter/session-replay/)
- [Default masking](https://docs.contentsquare.com/en/flutter/session-replay/#default-masking)

---
name: contentsquare-flutter-sdk
description: Integrate or upgrade the Contentsquare Flutter SDK -- Session Replay, screen tracking, transactions, analytics, masking, privacy opt-in/out. Use when working with Contentsquare, CSQ, CSQ.start, StartConfig, AnalyticsOptions, ProductAnalyticsOptions, CSQNavigatorObserver, CSQNavigatorAutoRouteObserver, auto_route, AutoRoute, GoRouter, go_router, CSQWebViewWrapper, configureProductAnalytics, or migrating from the legacy `Contentsquare()` API to `CSQ()` (v3.x to v4.x) or from 4.1.x to 4.4.x.
---

# Contentsquare Flutter SDK Integration

> This skill helps AI agents integrate or upgrade the Contentsquare Flutter SDK in client applications.

## Install

```yaml
dependencies:
  contentsquare: ^4.4.0
```

Then run `flutter pub get`.

> **Already on `^4.1.x`?** This release contains **breaking changes** in `AnalyticsOptions` / `ProductAnalyticsOptions` (several fields removed) and a deprecation of `configureProductAnalytics(...)`. Read the [Migration from 4.1.x to 4.4.x](references/migration.md) section before bumping.

> **Already on `^3.x`?** The v4 release contains **breaking changes** including API renames, `ContentsquareRoot` removal, and native cleanup. Read the [Legacy `Contentsquare` API to `CSQ` (v3.x → v4.x)](references/migration.md) section before upgrading.

## Quick Start

```dart
import 'package:contentsquare/csq.dart';
import 'dart:async';
import 'package:flutter/material.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      CSQ().collectFlutterError(details: details);
    };

    await CSQ().start();
    await CSQ().optIn(); // TODO: customer to manage consent — call only after user accepts
    runApp(const MyApp());
  }, (error, stack) => CSQ().collectError(error: error, stackTrace: stack));
}
```

> Avoid `runZonedGuarded` only when the app architecture makes it necessary. Alternative init without it: [references/common-patterns.md](references/common-patterns.md).

It is very important that screens should be tracked, otherwise Session replay will not work. You can either track screens manually with `trackScreenview()` or use the recommended `CSQNavigatorObserver` for automatic tracking.
Add automatic screen tracking:

```dart
MaterialApp(
  navigatorObservers: [CSQNavigatorObserver()],
);
```

Critical: Add the required iOS setup for [iOS In-App Features](#ios-in-app-features-setup).

Before wrapping the MVP, make sure you are handling webviews if they are present in the app. Webviews are not automatically tracked, and every webview must be wrapped. Check the webview section below for details.

## API Surface

Always use `CSQ` from `package:contentsquare/csq.dart`. The `Contentsquare` class is deprecated.

### Lifecycle

| Method                                    | Purpose                                                                           |
| ----------------------------------------- | --------------------------------------------------------------------------------- |
| `start({StartConfig, CSQMaskingConfig?})` | Start the SDK. Must be called before any other API.                               |
| `stop()`                                  | Shut down the SDK completely.                                                     |
| `pauseTracking()`                         | Pause data collection (for sensitive screens). Avoid unless explicitly requested. |
| `resumeTracking()`                        | Resume after `pauseTracking()`.                                                   |

### StartConfig Variants

| Factory                                        | Use Case                                                                                     | Onboarding priority                                                               |
| ---------------------------------------------- | -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `StartConfig.withDatasourceId(id:, options:)`  | CSQ with data source ID                                                                      | **1st choice for new clients** -- ask for this first                              |
| `StartConfig.withEnvironmentId(id:, options:)` | Product Analytics with environment ID                                                        | 2nd choice if no data source ID is available                                      |
| `StartConfig.dxa({options})`                   | Digital Experience Analytics only (default). `options` is `AnalyticsOptions` -- new in 4.2.0 | Fallback only -- when neither ID is available or DXA-only is explicitly requested |

All three variants accept the same `AnalyticsOptions` object (see the **AnalyticsOptions** section below).

**Recommended onboarding flow:**

1. Ask the user: _"Do you have a Contentsquare data source ID?"_ If yes, use `StartConfig.withDatasourceId(id: ...)`.
2. If not, ask: _"Do you have an environment ID?"_ If yes, use `StartConfig.withEnvironmentId(id: ...)`.
3. Only if neither is available (or the user explicitly wants DXA-only), fall back to `StartConfig.dxa()`.
4. Ask: _"Is your Product Analytics / Unified CSQ environment hosted in the EU?"_ If yes, set `baseUrl: Uri.parse('https://mh.ba.contentsquare.net')` in `AnalyticsOptions`. The default endpoint is US -- EU environments will not receive data without this override.

Do not invent an ID. Do not silently default to DXA. Do not assume US hosting -- always ask.

### Privacy

| Method     | Purpose                                                      |
| ---------- | ------------------------------------------------------------ |
| `optIn()`  | Opt the device into tracking. Starts immediately.            |
| `optOut()` | Opt out permanently. Stops until `optIn()` or app reinstall. |

### Identity

| Method                                | Context           | Purpose                                               |
| ------------------------------------- | ----------------- | ----------------------------------------------------- |
| `identify(userIdentifier:)`           | Product Analytics | Set user identity. Different ID triggers new session. |
| `resetIdentity()`                     | Product Analytics | Clear identity. Triggers new session.                 |
| `sendUserIdentifier(userIdentifier:)` | DXA               | Send hashed user ID. Max 100 chars.                   |

### Screen Tracking

| Method                                      | Purpose                                             |
| ------------------------------------------- | --------------------------------------------------- |
| `trackScreenview(screenName:, customVars:)` | Track a screen view with optional custom variables. |

`CustomVar(index:, name:, value:)` -- index (int), name (String), value (String).

### Transactions

```dart
await CSQ().trackTransaction(
  Transaction(price: 29.99, currency: Currency.USD, id: 'order_123'),
);
```

`Currency` is an ISO 4217 enum (e.g., `Currency.USD`, `Currency.EUR`).

### Custom Events and Properties

| Method                                | Purpose                                       |
| ------------------------------------- | --------------------------------------------- |
| `trackEvent(eventName:, properties:)` | Track a named event with optional properties. |
| `addDynamicVar(DynamicVar)`           | Add session-level dynamic variable.           |
| `addUserProperties(properties:)`      | Set user-level properties.                    |
| `addEventProperties(properties:)`     | Set properties on all future events.          |
| `removeEventProperty(name:)`          | Remove one event property.                    |
| `clearEventProperties()`              | Remove all event properties.                  |

Property values must be `String`, `num`, or `bool`. Other types are silently ignored.

`DynamicVar` factories: `DynamicVar.fromString(key:, value:)` and `DynamicVar.fromInt(key:, value:)`.

### Session Replay

| Method                                  | Purpose                                                                                                                              |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `triggerReplayForCurrentSession(name:)` | Flag the session for replay capture (for segmentation/filtering).                                                                    |
| `triggerReplayForCurrentScreen(name:)`  | Flag the current screen for replay capture.                                                                                          |
| `startSessionReplay()` _(new in 4.2.0)_ | Start Session Replay on-demand. Use when `sessionReplayAutoStart: false` was passed to `start()`. **One-shot** -- not a restart API. |
| `stopSessionReplay()` _(new in 4.2.0)_  | Stop Session Replay on-demand without stopping the SDK. **Terminal** -- SR cannot be re-started afterwards in the same SDK lifetime. |

**On-demand Session Replay** -- disable auto-start at SDK launch and control it manually:

```dart
await CSQ().start(
  startConfig: StartConfig.dxa(
    options: const AnalyticsOptions(sessionReplayAutoStart: false),
  ),
);
// later, when you want SR to start (e.g., entering a checkout flow):
await CSQ().startSessionReplay();
// and to stop it (final -- no restart afterwards):
await CSQ().stopSessionReplay();
```

> `startSessionReplay` / `stopSessionReplay` are **start + stop only**, not pause/resume. After `stopSessionReplay()` SR stays off until the next SDK lifetime.

### Session Metadata (get replay link)

Access session information including the replay URL:

```dart
// Get current session replay URL (returns Uri?)
final replayUrl = CSQ().metadata.sessionReplayUrl;

// Listen for metadata changes
final subscription = CSQ().metadata.onChange((metadata) {
  print('Session Replay URL: ${metadata.sessionReplayUrl}');
});
subscription.cancel(); // Stop listening when done
```

`Metadata` fields: `projectId`, `environmentId`, `userId`, `identity`, `sessionId`, `sessionReplayUrl` (Uri?).

### Error Reporting

| Method                                                | Purpose                                                                      |
| ----------------------------------------------------- | ---------------------------------------------------------------------------- |
| `collectFlutterError(details:, presentErrorDetails:)` | Report Flutter framework errors.                                             |
| `collectError(error:, stackTrace:)`                   | Report caught errors.                                                        |
| `setURLMaskingPatterns(patterns:)`                    | Mask sensitive URL paths in error tracking. Emails are masked automatically. |

For automatic HTTP request error tracking, install `CSQHttpOverrides` as the global HTTP overrides at app startup — see [references/api-reference.md](references/api-reference.md).

### Debug and Metadata

| API                           | Purpose                                                          |
| ----------------------------- | ---------------------------------------------------------------- |
| `debug.setLogLevel(LogLevel)` | Set log level (`info`, `verbose`, etc.)                          |
| `metadata`                    | Access session metadata. `metadata.onChange(handler)` to listen. |

### AnalyticsOptions (shared by all StartConfig variants)

All fields are nullable (`null` = native default behavior).

| Field                                    | Type        | Platform | Purpose                                                                                                                                                                          |
| ---------------------------------------- | ----------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `enableInteractionsAutocapture`          | `bool?`     | Both     | Enable Flutter interaction autocapture (PA)                                                                                                                                      |
| `disablePageviewAutocapture`             | `bool?`     | Both     | Disable native pageview autocapture                                                                                                                                              |
| `enablePushNotificationAutocapture`      | `bool?`     | Both     | Capture push notification events                                                                                                                                                 |
| `enablePushNotificationTitleAutocapture` | `bool?`     | Both     | Capture push notification title                                                                                                                                                  |
| `enablePushNotificationBodyAutocapture`  | `bool?`     | Both     | Capture push notification body                                                                                                                                                   |
| `baseUrl`                                | `Uri?`      | Both     | Custom API endpoint. **Required for EU-hosted Product Analytics environments**: set to `Uri.parse('https://mh.ba.contentsquare.net')`. Also used for on-prem / custom endpoints. |
| `uploadInterval`                         | `Duration?` | Both     | How often events are uploaded                                                                                                                                                    |
| `sessionReplayAutoStart`                 | `bool?`     | Both     | If `false`, SR doesn't start at SDK launch -- use `startSessionReplay()`                                                                                                         |
| `disablePageviewTitleAutocapture`        | `bool?`     | iOS only | Disable iOS page title autocapture                                                                                                                                               |
| `disableInteractionAutocapture`          | `bool?`     | iOS only | Disable native iOS interaction autocapture                                                                                                                                       |

> **Removed in 4.2.0** (breaking): `captureVendorId`, `captureAdvertiserId`, `clearEventPropertiesOnNewUser`, `resumePreviousSession`, `disableScreenviewForwardToDXA`, `disableScreenviewForwardToPA`, `messageBatchByteLimit`, `messageBatchMessageLimit`, `pruningLookBackWindow`, `maximumDatabaseSize`, `maximumBatchCountPerUpload`. See [references/migration.md](references/migration.md) for replacements.

> `ProductAnalyticsOptions` is now a `typedef` alias for `AnalyticsOptions` (kept for back-compat). Prefer `AnalyticsOptions` in new code.

## Session Replay Masking

### Global masking (at start)

```dart
await CSQ().start(
  maskingConfig: const CSQMaskingConfig(
    maskTexts: true,
    maskTextFields: true,
    maskImages: false,
  ),
);
```

### Scoped masking (per widget subtree)

```dart
CSQMask(
  config: const CSQMaskingConfig(maskTexts: true, maskInteractions: true),
  child: Text('Sensitive content'),
)
```

### CSQMaskingConfig fields

| Field              | What it masks                              |
| ------------------ | ------------------------------------------ |
| `maskTexts`        | `Text`, `RichText`                         |
| `maskTextFields`   | `TextField`, `TextFormField`               |
| `maskImages`       | `Image` widgets                            |
| `maskSvgImages`    | SVG-rendered pictures                      |
| `maskCharts`       | fl_chart widgets                           |
| `maskCustomPaints` | Developer `CustomPaint` widgets            |
| `maskInteractions` | User interactions (Product Analytics only) |

Convenience: `CSQMaskingConfig.maskAll()` and `CSQMaskingConfig.unMaskAll()`.

## Navigator Observer (Auto Screen Tracking)

> **Before adding the observer**, check `pubspec.yaml` for the navigation package in use:
>
> - `auto_route` → use `CSQNavigatorAutoRouteObserver` (see **AutoRoute** section below)
> - `go_router` → use `CSQNavigatorObserver` via `GoRouter(observers: [...])`
> - Neither → use `CSQNavigatorObserver` via `MaterialApp(navigatorObservers: [...])`

### Standard Flutter Navigator (MaterialApp / CupertinoApp)

```dart
import 'package:contentsquare/csq.dart';

MaterialApp(
  navigatorObservers: [
    CSQNavigatorObserver(
      screenNameProvider: (route) {
        if (route.settings.name == '/profile') return 'User Profile';
        return route.settings.name;
      },
      customVarsProvider: (route) => [
        CustomVar(index: 1, name: 'section', value: 'main'),
      ],
      excludeRouteFromTracking: (route) =>
          route.settings.name?.startsWith('/debug') ?? false,
    ),
  ],
);
```

All three callbacks are optional. Without them, route names are used as screen names.

> Modal routes (`showDialog`, `showModalBottomSheet`, etc.) are tracked as separate screens by default. Use `excludeRouteFromTracking` to skip them.

### GoRouter

No extra package needed. Pass `CSQNavigatorObserver` via the `observers` parameter on `GoRouter` — **not** via `MaterialApp.router`.

```dart
GoRouter(
  observers: [CSQNavigatorObserver()],
  routes: [...],
)
```

> When using `pageBuilder` in a `GoRoute`, you must set `name` on the `MaterialPage` — otherwise the observer receives a nameless route. See [references/common-patterns.md](references/common-patterns.md).

### AutoRoute

AutoRoute is **not compatible** with `CSQNavigatorObserver`. Use `CSQNavigatorAutoRouteObserver` from the `csq_navigator_auto_route_observer` package. It also handles **tab navigation automatically** (`didInitTabRoute` / `didChangeTabRoute`).

Add `csq_navigator_auto_route_observer: ^1.1.0` to `dependencies`, then attach it to the router config:

```dart
import 'package:csq_navigator_auto_route_observer/csq_navigator_auto_route_observer.dart';

MaterialApp.router(
  routerConfig: _appRouter.config(
    navigatorObservers: () => [
      CSQNavigatorAutoRouteObserver(),
    ],
  ),
);
```

Supports the same three optional callbacks as `CSQNavigatorObserver` (`screenNameProvider`, `customVarsProvider`, `excludeRouteFromTracking`). Full callback reference and modal exclusion examples: [references/screen-tracking.md](references/screen-tracking.md).

**Compatibility:** AutoRoute `>=10.1.0+1 <12.0.0`, `csq_navigator_auto_route_observer ^1.1.0`.

### PageView and TabBar (manual tracking required)

`PageView` swipes and standard `TabBar` tab changes do **not** push routes, so observers are never triggered. Call `trackScreenview` manually:

- **PageView**: use the `onPageChanged` callback
- **TabBar**: use `TabController.addListener`

See [references/screen-tracking.md](references/screen-tracking.md) for full code examples.

## WebView Tracking

WebViews are **not automatically tracked**. You must wrap them with `CSQWebViewWrapper` and set up a JavaScript channel bridge to enable session stitching between the native app and web content.

**Prerequisites:**

1. JavaScript must be enabled in the WebView
2. The web pages loaded in the WebView must have the [Contentsquare Web Tracking Tag in WebView mode](https://docs.contentsquare.com/en/webview-tracking-tag/)

### Using `webview_flutter` (JSChannelWebViewWrapperDelegate)

```dart
import 'package:contentsquare/csq.dart';
import 'package:webview_flutter/webview_flutter.dart';

webViewController.setJavaScriptMode(JavaScriptMode.unrestricted);

CSQWebViewWrapper(
  delegate: JSChannelWebViewWrapperDelegate(
    addJavaScriptChannel: (WebViewJSChannelHandler handler) {
      webViewController.addJavaScriptChannel(
        handler.channelName,
        onMessageReceived: (jsMessage) {
          handler.onMessageReceived(jsMessage.message);
        },
      );
    },
    builder: (context) {
      return WebViewWidget(controller: webViewController);
    },
  ),
);
```

### Using `flutter_inappwebview` (UserScriptWebViewWrapperDelegate)

```dart
import 'dart:collection';
import 'package:contentsquare/csq.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

CSQWebViewWrapper(
  delegate: UserScriptWebViewWrapperDelegate(
    builder: (BuildContext context, String userScript) {
      return InAppWebView(
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(javaScriptEnabled: true),
        ),
        initialUrlRequest: URLRequest(url: Uri.parse(url)),
        initialUserScripts: UnmodifiableListView([
          UserScript(
            source: userScript,
            injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          ),
        ]),
      );
    },
  ),
);
```

**Important:**

- Always use `handler.channelName` as the channel name (do not hardcode)
- Always call `handler.onMessageReceived(...)` in the JavaScript channel callback
- For `UserScript`, always set `injectionTime` to `AT_DOCUMENT_START`
- The underlying WebView must use `android.webkit.WebView` on Android and `WKWebView` on iOS

## Common Patterns

### 1. Full initialization with error handling

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CSQ().start(
    maskingConfig: const CSQMaskingConfig(maskTexts: true, maskTextFields: true),
  );
  await CSQ().optIn();

  FlutterError.onError = (details) {
    CSQ().collectFlutterError(details: details);
  };

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) => CSQ().collectError(error: error, stackTrace: stack),
  );
}
```

### 2. On-demand Session Replay (sensitive flows)

```dart
// 1) Disable SR auto-start globally
await CSQ().start(
  startConfig: StartConfig.withEnvironmentId(
    id: 'your-env-id',
    options: const AnalyticsOptions(sessionReplayAutoStart: false),
  ),
);

// 2) Start SR once, when entering the flow you want recorded
await CSQ().startSessionReplay();

// 3) Stop SR when the flow is done.
//    WARNING: this is terminal for the SDK lifetime -- you cannot
//    restart SR after this call. Do NOT wire it to dispose() of
//    short-lived widgets if you may want SR again later in the same session.
await CSQ().stopSessionReplay();
```

> More patterns (Product Analytics setup, transactions, consent flow, custom events): [references/common-patterns.md](references/common-patterns.md).

## iOS In-App Features Setup

To use Contentsquare in-app features on iOS (screenshot capture, SDK logs, Zoning Analysis), native iOS configuration is required:

1. **Add URL scheme** to `ios/Runner/Info.plist`: `cs-$(PRODUCT_BUNDLE_IDENTIFIER)`
2. **Handle deeplinks** in `AppDelegate.swift` by calling `CSQ.handle(url: url)`

This is one of the few cases where editing native files is allowed.

> Full implementation guide with code samples for AppDelegate, SceneDelegate, and SwiftUI: [references/ios-in-app-features.md](references/ios-in-app-features.md)

## Migrations

Full migration playbooks live in [references/migration.md](references/migration.md). Load that file before performing an upgrade.

| Customer's current state                                                                                                                                                          | Migration to read                                                                                                                                                                                                                                             |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| On `^3.x`, uses `Contentsquare()` singleton, `ContentsquareRoot`, `MaskingConfig`, `ContentsquareNavigatorObserver`, etc.                                                         | [Legacy `Contentsquare` API to `CSQ` (v3.x → v4.x)](references/migration.md) -- API renames, `ContentsquareRoot` removal, native `AndroidManifest.xml` / `Info.plist` cleanup, Swift `Contentsquare.handle(` → `CSQ.handle(`.                                 |
| On `^4.1.x`, may use `configureProductAnalytics(...)` and/or removed `ProductAnalyticsOptions` fields (`captureVendorId`, `resumePreviousSession`, `pruningLookBackWindow`, etc.) | [4.1.x to 4.4.x](references/migration.md) -- **breaking**: 11 `ProductAnalyticsOptions` fields removed; deprecation of `configureProductAnalytics` (removal August 2026); new `startSessionReplay` / `stopSessionReplay` and `sessionReplayAutoStart` option. |

## Important Constraints

- **Ask for IDs in this order**: Before integrating, ask the user **(1)** for a Contentsquare **data source ID** -- this is the recommended setup for new clients. **(2)** If they don't have one, ask for an **environment ID**. **(3)** Only if they have neither (or explicitly want DXA-only), fall back to `StartConfig.dxa()`. Map the answers to: `StartConfig.withDatasourceId(id:)` → `StartConfig.withEnvironmentId(id:)` → `StartConfig.dxa()`. Do not invent an ID and do not silently default to DXA.
- **Never touch native code or native config** (with exceptions): Integration is **Dart-only** by default. Do not edit files under `android/`, `ios/`, `macos/`, `windows/`, `linux/` unless explicitly allowed. **Allowed exceptions:**
  - **iOS in-app features setup**: Add the `cs-$(PRODUCT_BUNDLE_IDENTIFIER)` URL scheme to `ios/Runner/Info.plist` and add the deeplink handler to `AppDelegate.swift` (see **iOS In-App Features Setup** section).
  - **v3.x → v4.x migration cleanup**: Remove the legacy `com.contentsquare.android.autostart` meta tag from `AndroidManifest.xml`, the `CSDisableAutostart` key from `Info.plist`, and rename Swift `Contentsquare.handle(` → `CSQ.handle(` (see [references/migration.md](references/migration.md)).
    For any native change outside these scopes, stop and ask the user instead of editing.
- **Always configure iOS in-app features**: Apply the iOS setup on every new integration (URL scheme + `CSQ.handle(url:)` in `AppDelegate.swift`). See **iOS In-App Features Setup** and [references/ios-in-app-features.md](references/ios-in-app-features.md) for full samples.
- **Detect navigation package & widgets**: Scan `pubspec.yaml` and code. `auto_route` → install `csq_navigator_auto_route_observer` and use `CSQNavigatorAutoRouteObserver` on `_appRouter.config(navigatorObservers: ...)`; `go_router` → `CSQNavigatorObserver` on `GoRouter(observers: [...])` (**not** `MaterialApp.router`); neither → `CSQNavigatorObserver` on `MaterialApp(navigatorObservers: [...])`. Additionally, `PageView` and `TabBar` widgets do not push routes — require manual `trackScreenview` in `onPageChanged` / `TabController.addListener`.
- **Scan for WebViews**: During integration, search the codebase for any existing WebView usage (`webview_flutter`, `flutter_inappwebview`, `WebViewWidget`, `InAppWebView`). WebViews are not automatically tracked -- every WebView must be wrapped with `CSQWebViewWrapper` and the appropriate delegate. Do not skip this step.
- **Call `start()` first**: All other CSQ methods require `start()` to have been called.
- **CSQ, not Contentsquare**: The `Contentsquare` class is deprecated. Always use `CSQ()`.
- **`configureProductAnalytics` is deprecated** (removal **August 2026**). Use `CSQ().start(startConfig: StartConfig.withEnvironmentId(...))` instead. Never combine the two -- the deprecated API takes precedence and silently overrides `start(startConfig: ...)`.
- **`AnalyticsOptions` over `ProductAnalyticsOptions`**: the latter is a `typedef` kept for back-compat. Use `AnalyticsOptions` in new code; it now applies to DXA too.
- **Platform support**: Android and iOS only. Web/desktop return a no-op implementation.
- **Flutter version**: Requires Flutter >= 3.27.0, Dart >= 3.6.0.
- **Property types**: Only `String`, `num`, `bool` are accepted for event/user properties.
- **DynamicVar limits**: Key max 49 chars (asserted `< 50`), string value max 255 chars (asserted `< 256`), int value range `0..2^32-1`.
- **userIdentifier**: Recommended max 100 characters for both `identify()` and `sendUserIdentifier()`.
- **Privacy**: Never auto-opt-in. Always implement a consent flow.
- **PII**: Never pass emails, passwords, or real names in screen names, event names, or properties.
- **Environment IDs**: Never hardcode -- use configuration or environment variables.
- **iOS**: Check [iOS compatibility docs](https://docs.contentsquare.com/en/ios/compatibility/) before integration.

## References

- Migration playbooks (legacy v3 → v4 and 4.1.x → 4.4.x): [references/migration.md](references/migration.md)
- Full method signatures and parameter details: [references/api-reference.md](references/api-reference.md)
- Session Replay deep dive (masking, on-demand SR, known limitations): [references/session-replay.md](references/session-replay.md)
- iOS in-app features setup (URL scheme, deeplink handling, debugging): [references/ios-in-app-features.md](references/ios-in-app-features.md)
- Screen tracking setups (GoRouter, AutoRoute, PageView, TabBar, modal exclusion, naming guidelines): [references/screen-tracking.md](references/screen-tracking.md)
- Common patterns (alternative init, transactions, consent, events, GoRouter pageBuilder): [references/common-patterns.md](references/common-patterns.md)
- [Official Flutter documentation](https://docs.contentsquare.com/flutter/)

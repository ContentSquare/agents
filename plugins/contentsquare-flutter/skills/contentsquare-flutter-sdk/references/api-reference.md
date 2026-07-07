# Contentsquare Flutter SDK -- CSQ API Reference

Entry point: `import 'package:contentsquare/csq.dart';`

All methods are accessed via the `CSQ()` singleton factory.

---

## Lifecycle

### start

```dart
Future<void> start({
  StartConfig? startConfig,           // defaults to StartConfig.dxa()
  CSQMaskingConfig? maskingConfig,
})
```

Starts the SDK. Must be called before any other CSQ method. Call as early as possible in the app lifecycle (before `runApp`).

**Parameters:**

| Parameter       | Type                | Default                  | Description                   |
| --------------- | ------------------- | ------------------------ | ----------------------------- |
| `startConfig`   | `StartConfig?`      | `StartConfig.dxa()`      | SDK mode configuration        |
| `maskingConfig` | `CSQMaskingConfig?` | `null` (default masking) | Global Session Replay masking |

**StartConfig variants:**

```dart
// DXA only (default). Since 4.2.0 also accepts AnalyticsOptions.
await CSQ().start();
await CSQ().start(startConfig: StartConfig.dxa());
await CSQ().start(
  startConfig: StartConfig.dxa(
    options: const AnalyticsOptions(sessionReplayAutoStart: false),
  ),
);

// Product Analytics with environment ID
await CSQ().start(
  startConfig: StartConfig.withEnvironmentId(
    id: 'your-env-id',
    options: const AnalyticsOptions(
      enableInteractionsAutocapture: true,
    ),
  ),
);

// CSQ with data source ID (UCH / remote config)
await CSQ().start(
  startConfig: StartConfig.withDatasourceId(id: 'your-datasource-id'),
);

// EU-hosted Product Analytics / Unified CSQ environment
// (default endpoint is US -- EU environments require this override).
await CSQ().start(
  startConfig: StartConfig.withEnvironmentId(
    id: 'your-env-id',
    options: AnalyticsOptions(
      baseUrl: Uri.parse('https://mh.ba.contentsquare.net'),
    ),
  ),
);
```

### configureProductAnalytics _(deprecated -- removal August 2026)_

```dart
@Deprecated('Use start(startConfig: StartConfig.withEnvironmentId(...)) instead.')
Future<void> configureProductAnalytics({
  required String environmentId,
  ProductAnalyticsOptions options = const ProductAnalyticsOptions(),
})
```

Kept for backwards compatibility. If both `configureProductAnalytics(...)` and `start(startConfig: ...)` are called, **the deprecated config wins**. Do not mix them.

Migrate to:

```dart
await CSQ().start(
  startConfig: StartConfig.withEnvironmentId(id: '...', options: AnalyticsOptions(...)),
);
```

### stop

```dart
Future<void> stop()
```

Shuts down the SDK. No data collection until `start()` is called again.

### pauseTracking

```dart
Future<void> pauseTracking()
```

Temporarily pauses data collection. Use for sensitive screens.

### resumeTracking

```dart
Future<void> resumeTracking()
```

Resumes tracking after `pauseTracking()`.

---

## Privacy

### optIn

```dart
Future<void> optIn()
```

Opts the device into tracking. Tracking starts immediately.

### optOut

```dart
Future<void> optOut()
```

Permanently opts the device out. Tracking never resumes unless:

- `optIn()` is called (new user ID, no link to previous activity)
- The app is reinstalled

---

## Identity

### identify (Product Analytics only)

```dart
Future<void> identify({required String userIdentifier})
```

Sets user identity. If a different identity was already set, this starts a new session with a new user ID.

| Parameter        | Type     | Constraint         |
| ---------------- | -------- | ------------------ |
| `userIdentifier` | `String` | Max 100 characters |

### resetIdentity (Product Analytics only)

```dart
Future<void> resetIdentity()
```

Clears the identity set by `identify()`. Starts a new session with a new user ID. No-op if no identity was set.

### sendUserIdentifier (DXA only)

```dart
Future<void> sendUserIdentifier({required String userIdentifier})
```

Sends a user identifier to DXA tracking. The identifier is immediately hashed -- no PII is ever accessible.

| Parameter        | Type     | Constraint         |
| ---------------- | -------- | ------------------ |
| `userIdentifier` | `String` | Max 100 characters |

---

## Screen Tracking

### trackScreenview

```dart
Future<void> trackScreenview({
  required String screenName,
  List<CustomVar>? customVars,
})
```

Tracks a screen view. Follow the [screen naming rules](https://docs.contentsquare.com/en/flutter/track-screens/#how-to-name-screens).

**CustomVar:**

```dart
class CustomVar {
  const CustomVar({
    required int index,
    required String name,
    required String value,
  });
}
```

**Example:**

```dart
await CSQ().trackScreenview(
  screenName: 'ProductDetail',
  customVars: [
    CustomVar(index: 1, name: 'category', value: 'electronics'),
    CustomVar(index: 2, name: 'product_id', value: 'sku_456'),
  ],
);
```

### CSQNavigatorObserver (automatic tracking)

```dart
factory CSQNavigatorObserver({
  List<CustomVar>? Function(Route<dynamic> route)? customVarsProvider,
  String? Function(Route<dynamic>)? screenNameProvider,
  bool Function(Route<dynamic> route)? excludeRouteFromTracking,
})
```

A `NavigatorObserver` that automatically tracks screen views on route changes.

| Callback                   | Return             | Purpose                                        |
| -------------------------- | ------------------ | ---------------------------------------------- |
| `screenNameProvider`       | `String?`          | Custom screen name. Return `null` for default. |
| `customVarsProvider`       | `List<CustomVar>?` | Custom variables per screen.                   |
| `excludeRouteFromTracking` | `bool`             | Return `true` to skip tracking this route.     |

**Example:**

```dart
MaterialApp(
  navigatorObservers: [
    CSQNavigatorObserver(
      screenNameProvider: (route) => route.settings.name,
      excludeRouteFromTracking: (route) =>
          route.settings.name?.startsWith('/internal') ?? false,
    ),
  ],
);
```

---

## Transactions

### trackTransaction

```dart
Future<void> trackTransaction(Transaction transaction)
```

**Transaction:**

```dart
class Transaction {
  const Transaction({
    required double price,
    required Currency currency,
    String? id,
  });
}
```

`Currency` is an ISO 4217 enum (e.g., `Currency.USD`, `Currency.EUR`, `Currency.GBP`). Use `currency.toStr()` if you need the string representation.

**Example:**

```dart
await CSQ().trackTransaction(
  Transaction(price: 99.99, currency: Currency.USD, id: 'order_789'),
);
```

---

## Custom Events and Properties

### trackEvent

```dart
Future<void> trackEvent({
  required String eventName,
  Map<String, dynamic>? properties,
})
```

Supported property types: `String`, `num`, `bool`. Other types are silently ignored.

```dart
await CSQ().trackEvent(
  eventName: 'search',
  properties: {'query': 'flutter sdk', 'results_count': 42},
);
```

### addDynamicVar

```dart
Future<void> addDynamicVar(DynamicVar dynamicVar)
```

**DynamicVar** is a sealed class with two factories:

```dart
DynamicVar.fromString(key: 'accountType', value: 'Premium')  // value max 255 chars (asserted `< 256`)
DynamicVar.fromInt(key: 'loginCount', value: 15)              // value 0 to 2^32-1
```

Key: max 49 characters (asserted `< 50`).

### addUserProperties

```dart
Future<void> addUserProperties({required Map<String, dynamic> properties})
```

Properties associated with the user. Supported types: `String`, `num`, `bool`.

### addEventProperties

```dart
Future<void> addEventProperties({required Map<String, dynamic> properties})
```

Properties attached to all future events until cleared.

### removeEventProperty

```dart
Future<void> removeEventProperty({required String name})
```

### clearEventProperties

```dart
Future<void> clearEventProperties()
```

---

## Session Replay

### triggerReplayForCurrentSession

```dart
Future<void> triggerReplayForCurrentSession({required String name})
```

Triggers Session Replay for the entire current session. The `name` parameter is used for segmentation filtering.

### triggerReplayForCurrentScreen

```dart
Future<void> triggerReplayForCurrentScreen({required String name})
```

Triggers Session Replay for the current screen only.

### startSessionReplay _(new since 4.2.0)_

```dart
Future<void> startSessionReplay()
```

Starts Session Replay on-demand. Use when SR auto-start was disabled via `AnalyticsOptions(sessionReplayAutoStart: false)`. Once called, SR follows the same rules as automatic start.

**One-shot.** Designed to start SR at most once. After `stopSessionReplay()` has been called, this method has no effect -- SR cannot be re-started in the same SDK lifetime.

### stopSessionReplay _(new since 4.2.0)_

```dart
Future<void> stopSessionReplay()
```

Stops Session Replay on-demand without stopping the rest of the SDK. To stop everything, use `stop()` instead.

**Terminal.** This is not a pause/resume API. Once called, SR cannot be re-started for the remainder of the SDK lifetime. Plan the recording window accordingly.

```dart
await CSQ().start(
  startConfig: StartConfig.dxa(
    options: const AnalyticsOptions(sessionReplayAutoStart: false),
  ),
);
// ...
await CSQ().startSessionReplay();
// later -- final stop, no restart possible
await CSQ().stopSessionReplay();
```

---

## Error Reporting

### collectFlutterError

```dart
Future<void> collectFlutterError({
  required FlutterErrorDetails details,
  bool presentErrorDetails = true,
})
```

Reports errors caught by the Flutter framework. Set `presentErrorDetails: false` to suppress console output.

**Typical setup:**

```dart
FlutterError.onError = (details) {
  CSQ().collectFlutterError(details: details);
};
```

### collectError

```dart
Future<void> collectError({
  required Object error,
  required StackTrace stackTrace,
})
```

Reports caught errors (e.g., from `try/catch` or `runZonedGuarded`).

```dart
runZonedGuarded(
  () => runApp(const MyApp()),
  (error, stack) => CSQ().collectError(error: error, stackTrace: stack),
);
```

### setURLMaskingPatterns

```dart
Future<void> setURLMaskingPatterns({required List<String> patterns})
```

Masks sensitive data in URL paths captured by error tracking. Pattern example: `"www.example.com/user/:user_id"` masks all user IDs in that path. Email addresses are masked automatically without this API.

```dart
await CSQ().setURLMaskingPatterns(
  patterns: ['api.example.com/users/:user_id/profile'],
);
// "api.example.com/users/198?x=1" -> "api.example.com/users/CS_ANONYMIZED_USER_ID?x=1"
```

---

## Debug and Metadata

### debug.setLogLevel

```dart
Future<void> debug.setLogLevel(LogLevel logLevel)
```

`LogLevel` values: `info` (default), `verbose`, `warning`, etc.

### metadata

```dart
MetadataProvider get metadata
```

Access session metadata including the session replay URL. `MetadataProvider` implements `Metadata`, so properties are accessed directly.

**Get current values:**

```dart
final replayUrl = CSQ().metadata.sessionReplayUrl; // Uri?
final sessionId = CSQ().metadata.sessionId;
final userId = CSQ().metadata.userId;
```

**Listen for metadata changes:**

```dart
final subscription = CSQ().metadata.onChange((metadata) {
  print('Session Replay URL: ${metadata.sessionReplayUrl}');
});

// Stop listening
subscription.cancel();
```

**Metadata fields:**

| Field              | Type      | Description                                     |
| ------------------ | --------- | ----------------------------------------------- |
| `projectId`        | `String?` | Project ID for the current session              |
| `environmentId`    | `String?` | Environment ID for the current session          |
| `userId`           | `String?` | User identifier                                 |
| `identity`         | `String?` | Identity of the current user                    |
| `sessionId`        | `String?` | Current session identifier                      |
| `sessionReplayUrl` | `Uri?`    | URL to view the session replay in Contentsquare |

---

## WebView Tracking

### CSQWebViewWrapper

```dart
CSQWebViewWrapper({
  required WebViewWrapperDelegate delegate,
})
```

Wraps a WebView widget to enable Contentsquare session stitching between the native app and web content. The web pages must have the [Contentsquare Web Tracking Tag in WebView mode](https://docs.contentsquare.com/en/webview-tracking-tag/).

### JSChannelWebViewWrapperDelegate

Use with `webview_flutter` or `flutter_webview_plugin`. Injects the Contentsquare bridge script via a JavaScript channel.

```dart
JSChannelWebViewWrapperDelegate({
  required void Function(WebViewJSChannelHandler handler) addJavaScriptChannel,
  required Widget Function(BuildContext context) builder,
})
```

| Parameter              | Type                                     | Description                                                                                         |
| ---------------------- | ---------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `addJavaScriptChannel` | `void Function(WebViewJSChannelHandler)` | Registers the JS channel. Must use `handler.channelName` and call `handler.onMessageReceived(...)`. |
| `builder`              | `Widget Function(BuildContext)`          | Builds the WebView widget.                                                                          |

### UserScriptWebViewWrapperDelegate

Use with `flutter_inappwebview`. Injects the Contentsquare bridge script via a user script.

```dart
UserScriptWebViewWrapperDelegate({
  required Widget Function(BuildContext context, String userScript) builder,
})
```

| Parameter | Type                                    | Description                                                                                           |
| --------- | --------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `builder` | `Widget Function(BuildContext, String)` | Builds the WebView widget. The `userScript` must be injected with `injectionTime: AT_DOCUMENT_START`. |

---

## CSQMaskingConfig

```dart
const factory CSQMaskingConfig({
  bool? maskTexts,
  bool? maskImages,
  bool? maskTextFields,
  bool? maskSvgImages,
  bool? maskCharts,
  bool? maskCustomPaints,
  bool? maskInteractions,
})
```

| Field              | What It Masks                                   |
| ------------------ | ----------------------------------------------- |
| `maskTexts`        | `Text`, `RichText` (`RenderParagraph`)          |
| `maskTextFields`   | `TextField`, `TextFormField` (`RenderEditable`) |
| `maskImages`       | `Image` widgets (`RenderImage`)                 |
| `maskSvgImages`    | SVG pictures                                    |
| `maskCharts`       | fl_chart widgets                                |
| `maskCustomPaints` | Developer `CustomPaint` widgets                 |
| `maskInteractions` | User interactions (PA context only)             |

Convenience factories:

- `CSQMaskingConfig.maskAll()` -- all fields `true`
- `CSQMaskingConfig.unMaskAll()` -- all fields `false`

Omitted fields default to `null` (no masking applied for that category).

---

## CSQMask Widget

```dart
CSQMask(
  config: const CSQMaskingConfig(maskTexts: true),
  child: Text('This text is masked in Session Replay'),
)
```

Applies masking to its widget subtree. Combines Session Replay masking and interaction masking.

---

## AnalyticsOptions

Applies to all `StartConfig` variants (DXA, environment ID, data source ID). All fields are nullable -- `null` means "use the native SDK default".

```dart
const AnalyticsOptions({
  bool? enableInteractionsAutocapture,
  bool? disablePageviewAutocapture,
  bool? disablePageviewTitleAutocapture,
  bool? disableInteractionAutocapture,
  bool? enablePushNotificationAutocapture,
  bool? enablePushNotificationTitleAutocapture,
  bool? enablePushNotificationBodyAutocapture,
  Uri? baseUrl,
  Duration? uploadInterval,
  bool? sessionReplayAutoStart,
})
```

| Option                                   | Type        | Platform | Purpose                                                                                                                                                                                                                                                                              |
| ---------------------------------------- | ----------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `enableInteractionsAutocapture`          | `bool?`     | Both     | Enable Flutter interaction autocapture (PA)                                                                                                                                                                                                                                          |
| `disablePageviewAutocapture`             | `bool?`     | Both     | Disable native pageview autocapture                                                                                                                                                                                                                                                  |
| `enablePushNotificationAutocapture`      | `bool?`     | Both     | Capture push notification events. Off by default.                                                                                                                                                                                                                                    |
| `enablePushNotificationTitleAutocapture` | `bool?`     | Both     | Capture push notification title text. Off by default -- enable only when title is non-PII.                                                                                                                                                                                           |
| `enablePushNotificationBodyAutocapture`  | `bool?`     | Both     | Capture push notification body text. Off by default -- enable only when body is non-PII.                                                                                                                                                                                             |
| `baseUrl`                                | `Uri?`      | Both     | Custom API endpoint. **EU-hosted Product Analytics / Unified CSQ environments must set this to `Uri.parse('https://mh.ba.contentsquare.net')`** -- the SDK defaults to the US endpoint and EU environments will receive no data otherwise. Also used for on-prem / custom endpoints. |
| `uploadInterval`                         | `Duration?` | Both     | Frequency at which events are uploaded                                                                                                                                                                                                                                               |
| `sessionReplayAutoStart`                 | `bool?`     | Both     | If `false`, SR doesn't start at SDK launch -- use `startSessionReplay()`                                                                                                                                                                                                             |
| `disablePageviewTitleAutocapture`        | `bool?`     | iOS only | Disable iOS page title autocapture                                                                                                                                                                                                                                                   |
| `disableInteractionAutocapture`          | `bool?`     | iOS only | Disable native iOS interaction autocapture                                                                                                                                                                                                                                           |

`AnalyticsOptions` exposes a `copyWith(...)` method for incremental updates.

> **Removed in 4.2.0** (breaking change vs 4.1.x): `captureVendorId`, `captureAdvertiserId`, `clearEventPropertiesOnNewUser`, `resumePreviousSession`, `disableScreenviewForwardToDXA`, `disableScreenviewForwardToPA`, `messageBatchByteLimit`, `messageBatchMessageLimit`, `pruningLookBackWindow` (Android), `maximumDatabaseSize` (Android), `maximumBatchCountPerUpload` (Android). Apps using any of these will fail to compile -- remove the references. Use `uploadInterval` to tune batching cadence; the rest now follow native defaults with no Flutter-side override.

> `ProductAnalyticsOptions` is preserved as `typedef ProductAnalyticsOptions = AnalyticsOptions;`. Prefer `AnalyticsOptions` in new code.

---

## CSQHttpOverrides

Wraps Dart's global `HttpOverrides` so the SDK can track HTTP requests made through the global `HttpClient` (used for error analysis on network failures).

```dart
import 'dart:io';
import 'package:contentsquare/csq.dart';

void main() {
  HttpOverrides.global = CSQHttpOverrides(
    httpOverrides: HttpOverrides.current ?? HttpOverrides(),
  );
  // ...then call CSQ().start() and runApp()
}
```

If the app already sets a custom `HttpOverrides`, pass it as the `httpOverrides:` argument so both behaviors compose. Set this **before** any HTTP requests are made.

---

## ReliableTarget

Marks a widget subtree as a stable zoning target. Used by Zoning Analysis to keep targeting consistent across builds even when the widget tree changes.

```dart
ReliableTarget(
  name: 'add_to_cart_button', // unique, non-empty, max 256 chars
  child: ElevatedButton(
    onPressed: ...,
    child: const Text('Add to cart'),
  ),
)
```

| Constraint        | Value                                           |
| ----------------- | ----------------------------------------------- |
| `name` non-empty  | asserted                                        |
| `name` max length | 256 characters (`ReliableTarget.nameMaxLength`) |

# Contentsquare Flutter SDK -- Migration Guide

Two distinct migrations are documented here. Pick the one that matches the customer's starting point.

- [Legacy `Contentsquare` API to `CSQ` (v3.x → v4.x)](#legacy-contentsquare-api-to-csq-v3x--v4x)
- [4.1.x to 4.4.x](#41x-to-44x)

---

## Legacy `Contentsquare` API to `CSQ` (v3.x → v4.x)

If the customer is upgrading from a `^3.x` release that uses the old `Contentsquare()` singleton, all of the following changes are required. The legacy `Contentsquare` class is still exported for backwards compatibility but is **deprecated and will be removed**. There is no codemod -- apply these transforms manually (or via a project-wide find/replace).

### Pubspec & imports

```yaml
# Before
dependencies:
  contentsquare: ^3.x

# After
dependencies:
  contentsquare: ^4.4.0
```

```dart
// Before
import 'package:contentsquare/contentsquare.dart';

// After
import 'package:contentsquare/csq.dart';
```

### App entry point

`ContentsquareRoot` has been **removed**. Wrap nothing -- just call `CSQ().start()` early in `main()`.

```dart
// Before
runApp(ContentsquareRoot(child: MyApp()));

// After
await CSQ().start();
runApp(const MyApp());
```

### API method mapping

| v3.x (`Contentsquare()`)                                | v4.x (`CSQ()`)                                                            | Notes                                                                                         |
| ------------------------------------------------------- | ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `Contentsquare().start()`                               | `CSQ().start()`                                                           | Now accepts `StartConfig` + `CSQMaskingConfig`.                                               |
| `Contentsquare().send(name)`                            | `CSQ().trackScreenview(screenName: name)`                                 | Argument is now named.                                                                        |
| `Contentsquare().sendTransaction(price, currency, id)`  | `CSQ().trackTransaction(Transaction(price: ..., currency: ..., id: ...))` | Wrap in `Transaction(...)`.                                                                   |
| `Contentsquare().sendDynamicVar(key, stringValue: ...)` | `CSQ().addDynamicVar(DynamicVar.fromString(key: ..., value: ...))`        | `stringValue:` / `intValue:` collapsed into `value:`. Use `DynamicVar.fromInt(...)` for ints. |
| `Contentsquare().optIn()` / `optOut()`                  | `CSQ().optIn()` / `CSQ().optOut()`                                        | Same semantics.                                                                               |
| `Contentsquare().forgetMe()`                            | **Removed.** Closest substitute: `CSQ().optOut()`.                        | No direct equivalent.                                                                         |
| `Contentsquare().getUserId()`                           | `CSQ().metadata.userId`                                                   | Now a synchronous getter on `metadata`.                                                       |
| `Contentsquare().stopTracking()`                        | `CSQ().pauseTracking()`                                                   | Renamed.                                                                                      |
| `Contentsquare().resumeTracking()`                      | `CSQ().resumeTracking()`                                                  | Same name.                                                                                    |
| `Contentsquare().sendUserIdentifier(id)`                | `CSQ().sendUserIdentifier(userIdentifier: id)`                            | Now a named argument.                                                                         |
| `Contentsquare().setURLMaskingPatterns(patterns)`       | `CSQ().setURLMaskingPatterns(patterns: patterns)`                         | Now a named argument.                                                                         |
| `Contentsquare().collectFlutterError(...)`              | `CSQ().collectFlutterError(...)`                                          | Same shape.                                                                                   |
| `Contentsquare().collectError(...)`                     | `CSQ().collectError(...)`                                                 | Same shape.                                                                                   |
| `Contentsquare().triggerReplayForCurrentSession(name)`  | `CSQ().triggerReplayForCurrentSession(name: name)`                        | Now a named argument.                                                                         |
| `Contentsquare().triggerReplayForCurrentScreen(name)`   | `CSQ().triggerReplayForCurrentScreen(name: name)`                         | Now a named argument.                                                                         |
| `Contentsquare().currentSessionReplayUrl`               | `CSQ().metadata.sessionReplayUrl`                                         | Now exposed via `metadata`.                                                                   |
| `Contentsquare().onSessionReplayLinkChange(handler)`    | `CSQ().metadata.onChange((m) => use(m.sessionReplayUrl))`                 | Subscribe via `metadata.onChange(...)`. Cancel the returned subscription.                     |

### Class / widget renames

| v3.x                                            | v4.x                                                                          |
| ----------------------------------------------- | ----------------------------------------------------------------------------- |
| `MaskingConfig`                                 | `CSQMaskingConfig`                                                            |
| `SessionReplayMaskingScope(maskingConfig: ...)` | `CSQMask(config: ...)` (note: parameter renamed `maskingConfig:` → `config:`) |
| `ContentsquareNavigatorObserver`                | `CSQNavigatorObserver`                                                        |
| `ContentsquareWebViewWrapper`                   | `CSQWebViewWrapper`                                                           |
| `ContentsquareHttpOverrides`                    | `CSQHttpOverrides`                                                            |

### Native cleanup

**Android** -- remove the legacy autostart meta tag from every `AndroidManifest.xml`:

```xml
<!-- Remove this entirely (no longer used in v4): -->
<meta-data android:name="com.contentsquare.android.autostart" android:value="false" />
```

**iOS** -- remove the legacy `CSDisableAutostart` key from `Info.plist`:

```xml
<!-- Remove this entirely (no longer used in v4): -->
<key>CSDisableAutostart</key>
<false/>
```

If any AppDelegate / Swift code calls `Contentsquare.handle(...)`, rename it to `CSQ.handle(...)`.

### Find-usages cheat sheet

```bash
# Dart references that must be migrated
rg "Contentsquare\(\)|ContentsquareRoot|ContentsquareNavigatorObserver|ContentsquareWebViewWrapper|ContentsquareHttpOverrides|SessionReplayMaskingScope|MaskingConfig\(|onSessionReplayLinkChange|currentSessionReplayUrl|forgetMe|stopTracking|sendDynamicVar|sendTransaction|\.send\(" --type dart

# Native config that must be removed
rg "com\.contentsquare\.android\.autostart" android/
rg "CSDisableAutostart" ios/
rg "Contentsquare\.handle\(" ios/
```

After all replacements, run `flutter pub get` and rebuild both platforms.

---

## 4.1.x to 4.4.x

### ⚠️ Breaking change: removed `AnalyticsOptions` / `ProductAnalyticsOptions` fields

Several fields previously available on `ProductAnalyticsOptions` have been **removed** in 4.2.x. Apps using any of them **will not compile** until the references are removed.

| Removed field                   | Type             | Notes / replacement                                               |
| ------------------------------- | ---------------- | ----------------------------------------------------------------- |
| `captureVendorId`               | `bool?`          | Removed -- behavior is now native default                         |
| `captureAdvertiserId`           | `bool?`          | Removed -- behavior is now native default                         |
| `clearEventPropertiesOnNewUser` | `bool?`          | Removed -- manage manually via `clearEventProperties()` if needed |
| `resumePreviousSession`         | `bool?`          | Removed -- behavior is now native default                         |
| `disableScreenviewForwardToDXA` | `bool?`          | Removed -- no replacement                                         |
| `disableScreenviewForwardToPA`  | `bool?`          | Removed -- no replacement                                         |
| `messageBatchByteLimit`         | `int?` (iOS)     | Removed -- use `uploadInterval` to tune batching cadence          |
| `messageBatchMessageLimit`      | `int?`           | Removed -- use `uploadInterval` to tune batching cadence          |
| `pruningLookBackWindow`         | `int?` (Android) | Removed -- native default applies                                 |
| `maximumDatabaseSize`           | `int?` (Android) | Removed -- native default applies                                 |
| `maximumBatchCountPerUpload`    | `int?` (Android) | Removed -- use `uploadInterval` to tune batching cadence          |

**How to find usages:**

```bash
rg "captureVendorId|captureAdvertiserId|clearEventPropertiesOnNewUser|resumePreviousSession|disableScreenviewForwardToDXA|disableScreenviewForwardToPA|messageBatchByteLimit|messageBatchMessageLimit|pruningLookBackWindow|maximumDatabaseSize|maximumBatchCountPerUpload"
```

The surviving / new `AnalyticsOptions` fields are documented in [api-reference.md](api-reference.md) (see the **AnalyticsOptions** section).

### Decision tree

| Your 4.1.x setup                                                                        | Action in +4.2.x                                                                                                                                                                           |
| --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Uses any removed field listed above                                                     | **Required:** remove the reference. There is no drop-in replacement; see the table for guidance. Then proceed below.                                                                       |
| `CSQ().start()` only (DXA)                                                              | No change needed. Optionally pass `StartConfig.dxa(options: ...)` to use new options (`uploadInterval`, `sessionReplayAutoStart`, push notif autocapture, etc.)                            |
| `CSQ().configureProductAnalytics(environmentId:, options:)` + `CSQ().start()`           | **Recommended:** collapse into a single `CSQ().start(startConfig: StartConfig.withEnvironmentId(id:, options:))` call. See [Scenario A](#scenario-a-migrate-off-configureproductanalytics) |
| `CSQ().start(startConfig: StartConfig.withEnvironmentId(...))` (already on the new API) | No change needed beyond the removed-field cleanup                                                                                                                                          |
| Uses `ProductAnalyticsOptions(...)`                                                     | Optionally rename to `AnalyticsOptions(...)` (alias is preserved). No behavior change                                                                                                      |
| Wants Session Replay only on specific screens                                           | New: pass `sessionReplayAutoStart: false` and call `startSessionReplay()` / `stopSessionReplay()` -- see [Scenario C](#scenario-c-on-demand-session-replay)                                |

### Scenario A: Migrate off `configureProductAnalytics`

**Before (4.1.x, still works in +4.2.x but deprecated):**

```dart
await CSQ().configureProductAnalytics(
  environmentId: 'env-id',
  options: ProductAnalyticsOptions(enableInteractionsAutocapture: true),
);
await CSQ().start();
```

**After (4.2.x recommended):**

```dart
await CSQ().start(
  startConfig: StartConfig.withEnvironmentId(
    id: 'env-id',
    options: const AnalyticsOptions(enableInteractionsAutocapture: true),
  ),
);
```

**Compatibility note:** if both `configureProductAnalytics(...)` and `start(startConfig: ...)` are called, the **deprecated `configureProductAnalytics` config wins** (intentional, for back-compat). Do not mix them: pick one.

### Scenario B: DXA-only customers wanting new options

All `AnalyticsOptions` fields are now usable in DXA mode too:

```dart
await CSQ().start(
  startConfig: StartConfig.dxa(
    options: const AnalyticsOptions(
      uploadInterval: Duration(seconds: 30),
      enablePushNotificationAutocapture: true,
    ),
  ),
);
```

### Scenario C: On-demand Session Replay

If the customer wants SR to **not** start automatically (e.g., only record certain user journeys):

```dart
await CSQ().start(
  startConfig: StartConfig.withEnvironmentId(
    id: 'env-id',
    options: const AnalyticsOptions(sessionReplayAutoStart: false),
  ),
);

// Later, anywhere in the app -- start SR once:
await CSQ().startSessionReplay();
// and to stop it (final, no restart afterwards):
await CSQ().stopSessionReplay();
```

`stopSessionReplay()` only stops SR -- the rest of the SDK keeps tracking. To stop everything, use `CSQ().stop()`.

> **Not a pause/resume API.** `startSessionReplay()` is intended to be called at most once, and `stopSessionReplay()` is terminal: SR cannot be re-started in the same SDK lifetime. If a customer needs to record multiple separate windows in one session, leave SR auto-started and use `triggerReplayForCurrentSession(name:)` / `triggerReplayForCurrentScreen(name:)` for segmentation instead.

### Scenario D: `ProductAnalyticsOptions` rename

`ProductAnalyticsOptions` is preserved as `typedef ProductAnalyticsOptions = AnalyticsOptions;` -- existing code keeps compiling. In new code, prefer `AnalyticsOptions` because it now also applies to DXA-only setups.

# Contentsquare Android SDK — CSQ API Reference

Entry point: `import com.contentsquare.CSQ`

> Note: the package is `com.contentsquare`, **not** `com.contentsquare.android`.

All public APIs are exposed on the `CSQ` object. This file documents method signatures, parameters and constraints. For workflows and integration patterns, see the parent `SKILL.md`.

---

## SDK Initialization and Management

### start

The SDK is started through a single `start(context, …)` call that combines configuration and initialization. There are three overloads.

#### Experience Analytics only (default)

```kotlin
CSQ.start(context = this)
```

#### Product Analytics (with optional Experience Analytics extension) — `environmentId`

```kotlin
import com.contentsquare.CSQ
import com.contentsquare.StartConfig
import com.contentsquare.api.model.AnalyticsOptions

CSQ.start(
    context = this,
    StartConfig.withEnvironmentId(
        id = "YOUR_ENVIRONMENT_ID",
        options = AnalyticsOptions(
            enableViewAutocapture = true
        )
    )
)
```

#### Unified CSQ — `dataSourceId`

```kotlin
CSQ.start(
    context = this,
    StartConfig.withDataSourceId(id = "YOUR_DATASOURCE_ID")
)
```

**Parameters:**

| Parameter     | Type                     | Description                                                                                                                                       |
| ------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `context`     | `Context`                | Android `Context` (typically the `Application` instance).                                                                                         |
| `startConfig` | `StartConfig` (optional) | Configuration created via `StartConfig.withEnvironmentId(id, options)` or `StartConfig.withDataSourceId(id)`. Omit for Experience Analytics only. |

`environmentId` and `dataSourceId` are obtained from the Contentsquare project settings on `app.contentsquare.com`. Never hardcode them.

### configureProductAnalytics — DEPRECATED

`CSQ.configureProductAnalytics(...)` is **deprecated**. Use `CSQ.start(context, StartConfig.withEnvironmentId(...))` instead, which combines configuration and initialization in a single call.

### stop

```kotlin
CSQ.stop()
```

Stop all SDK activity. No requests, telemetry, or logs will be generated.

### pauseTracking

```kotlin
CSQ.pauseTracking()
```

Pause all tracking features. Useful on a sensitive screen (e.g. payment flow).

### resumeTracking

```kotlin
CSQ.resumeTracking()
```

Resume tracking after `pauseTracking()`.

---

## `AnalyticsOptions` (passed to `StartConfig.withEnvironmentId` / `withDataSourceId` / `dxa`)

| Option                                   | Type               | Default                                  | Description                                                                                                                    |
| ---------------------------------------- | ------------------ | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `enableViewAutocapture`                  | `Boolean`          | `false`                                  | Auto-capture UI interactions and pageviews. **Android Views only — no Compose support.**                                       |
| `disablePageviewAutocapture`             | `Boolean`          | `false`                                  | Disable autocaptured source pageviews.                                                                                         |
| `enablePushNotificationAutocapture`      | `Boolean`          | `false`                                  | Auto-capture interaction events on notifications.                                                                              |
| `enablePushNotificationTitleAutocapture` | `Boolean`          | `false`                                  | Capture notification title (requires `enablePushNotificationAutocapture = true`).                                              |
| `enablePushNotificationBodyAutocapture`  | `Boolean`          | `false`                                  | Capture notification body (requires `enablePushNotificationAutocapture = true`).                                               |
| `baseUri`                                | `URI`              | `URI("https://mh.bf.contentsquare.net")` | Base URI for the API endpoint.                                                                                                 |
| `uploadInterval`                         | `Double` (seconds) | `15.0`                                   | Interval at which event batches are uploaded.                                                                                  |
| `sessionReplayAutoStart`                 | `Boolean`          | `true`                                   | Set to `false` to disable automatic Session Replay start; control with `CSQ.startSessionReplay()` / `CSQ.stopSessionReplay()`. |

---

## GDPR / Identification

### optIn

```kotlin
CSQ.optIn()
```

Get user consent. Generates a user ID and initiates tracking.

> A `CSQ.optIn(context: Context)` overload exists but is **deprecated** — always use the no-arg form.
>
> **Order matters:** `optIn()` must be called **after** `start()`, and only from your consent flow — never automatically in `Application.onCreate()`.

### optOut

```kotlin
CSQ.optOut()
```

Revoke consent, delete the stored `userId`, stop the SDK, flush local data and delete all files. The SDK will not track again until `optIn()` is called.

### identify

```kotlin
CSQ.identify(identity: String)
```

Product Analytics. Assigns an identity to the current user. Changing identity forces a new user ID and a new session.

| Parameter  | Type     | Constraints | Description                          |
| ---------- | -------- | ----------- | ------------------------------------ |
| `identity` | `String` | ≤ 255 chars | Identity to associate with the user. |

### resetIdentity

```kotlin
CSQ.resetIdentity()
```

Product Analytics. Equivalent to `optOut()` then `optIn()`. Creates a new unidentified user and session.

### sendUserIdentifier

```kotlin
CSQ.sendUserIdentifier(identifier: String)
```

Experience Analytics. Associate a hashed user identifier (email, phone number, customer ID…) to the session. The SDK hashes the value before sending.

| Parameter    | Type     | Constraints | Description                            |
| ------------ | -------- | ----------- | -------------------------------------- |
| `identifier` | `String` | ≤ 100 chars | Trimmed and lowercased before hashing. |

Recommended: call on every foreground entry via `ProcessLifecycleOwner` (a session ends 30 minutes after the last event).

---

## Session Metadata

### metadata properties

```kotlin
val userId        = CSQ.metadata.userId           // String?
val sessionId     = CSQ.metadata.sessionId        // String?
val projectId     = CSQ.metadata.projectId        // String?
val environmentId = CSQ.metadata.environmentId    // String?
val replayUrl     = CSQ.metadata.sessionReplayUrl // String?
val identity      = CSQ.metadata.identity         // String?
```

**Java:**

```java
String userId    = CSQ.metadata.getUserId();
String sessionId = CSQ.metadata.getSessionId();
```

### metadata.onChanged

```kotlin
CSQ.metadata.onChanged = OnMetadataChanged { metadata ->
    // Forward replay URL to your CRM / crash reporter
}
// Unregister:
CSQ.metadata.onChanged = null
```

> Only one callback at a time — assigning a new one overrides the previous. To avoid memory leaks, register/unregister with `ProcessLifecycleOwner` foreground/background events.

---

## Logging

### debug.logLevel

```kotlin
import com.contentsquare.api.model.LogLevel

CSQ.debug.logLevel = LogLevel.DEBUG
```

**Levels:** `LogLevel.NONE`, `TRACE`, `DEBUG`, `INFO` (default), `WARN`, `ERROR`.

### debug.logChannel

```kotlin
import com.contentsquare.api.contract.LogChannel

CSQ.debug.logChannel = customChannel
```

Route SDK logs to Timber, Arbor, or any custom logger. Default: Logcat.

```kotlin
class TimberLogChannel : LogChannel {
    override fun printLog(logLevel: LogLevel, message: String, source: String?, throwable: Throwable?) {
        Timber.log(/* ... */)
    }
}
```

---

## Screen Tracking

### trackScreenview

```kotlin
CSQ.trackScreenview(name: String, customVars: List<CustomVar> = emptyList())
```

| Parameter    | Type              | Description                                                        |
| ------------ | ----------------- | ------------------------------------------------------------------ |
| `name`       | `String`          | Screen name. Keep distinct names ≤ 100 per app. Never include PII. |
| `customVars` | `List<CustomVar>` | Optional custom variables.                                         |

**`CustomVar`:**

| Field   | Type     | Constraints |
| ------- | -------- | ----------- |
| `index` | `Int`    | 0..20       |
| `name`  | `String` | ≤ 512 chars |
| `value` | `String` | ≤ 255 chars |

> Sessions without at least one screenview are discarded server-side.

**Java:** `CSQ.trackScreenview("ScreenName", cvars);`

### TriggeredOnResume (Compose)

```kotlin
import com.contentsquare.api.compose.TriggeredOnResume

@Composable
fun TriggeredOnResume(block: () -> Unit)
```

Helper for Jetpack Compose. Ensures only one screenview per screen presentation, preventing duplicates during recomposition.

---

## Event Tracking

### trackTransaction (EA)

```kotlin
import com.contentsquare.api.model.Transaction
import com.contentsquare.api.model.Currency

val transaction = Transaction(value = 430.99f, currency = Currency.EUR, id = "order_123")
CSQ.trackTransaction(transaction)
```

**`Transaction`:**

| Parameter  | Type       | Required | Description                                                                                                                                                       |
| ---------- | ---------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `value`    | `Float`    | yes      | Transaction value. Note: very large numbers are subject to floating-point rounding (e.g. `1234567890f` → `1234567936f`). Regular currency amounts are unaffected. |
| `currency` | `Currency` | yes      | ISO 4217 currency.                                                                                                                                                |
| `id`       | `String?`  | no       | Transaction identifier. Default `null`.                                                                                                                           |

> **Send each transaction only once.** Do not call this from `onResume()` of a confirmation screen — it will fire every time the user re-foregrounds the app.

**`Currency`:** ISO 4217 enum.

```kotlin
val currency      = Currency.USD
val fromString    = Currency.fromString("USD")
val fromInteger   = Currency.fromInteger(840)
val isoCode       = Currency.USD.stringCode  // "USD"
```

If an unsupported currency is passed, the SDK sends `-1` and the project's default currency is used server-side.

### trackEvent (PA)

```kotlin
CSQ.trackEvent(
    event: String,
    properties: Map<String, Any> = mapOf()
)
```

Track a named event with optional properties.

Property values: `String`, `Number`, `Boolean`, or objects implementing `com.contentsquare.api.contract.Property`.

### trackMotionEvent (EA)

```kotlin
override fun dispatchTouchEvent(motionEvent: MotionEvent): Boolean {
    CSQ.trackMotionEvent(motionEvent)
    return super.dispatchTouchEvent(motionEvent)
}
```

Track a gesture manually. Use when autocapture cannot reach a particular view.

---

## Property Tracking

### addDynamicVar (EA)

```kotlin
CSQ.addDynamicVar("plan", "premium")
CSQ.addDynamicVar("loyalty_points", 1500L)
```

Two overloads: `addDynamicVar(key: String, value: String)` and `addDynamicVar(key: String, value: Long)`. Session-scoped key/value pairs. Constraints:

- `key` ≤ 512 chars (truncated otherwise); empty key replaced by `"cs-empty"`.
- 40 distinct keys per screenview (additional ignored).
- Same key reused on the same screenview overrides the previous value.
- `String` values: ≤ 255 chars (truncated); empty replaced by `"cs-empty"`.
- `Long` values: clamped to `[0, 2^32 - 1]`.

### addUserProperties (PA)

```kotlin
CSQ.addUserProperties(mapOf("plan" to "premium", "age" to 25))
```

Associate properties with the current user.

### addEventProperties (PA)

```kotlin
CSQ.addEventProperties(mapOf("app_version" to "2.1.0"))
```

Properties attached to all future events.

### removeEventProperty (PA)

```kotlin
CSQ.removeEventProperty("app_version")
```

### clearEventProperties (PA)

```kotlin
CSQ.clearEventProperties()
```

---

## Personal Data / Masking

> All Android View elements, their subclasses, and Jetpack Compose components are **fully masked by default**. See `reference/session-replay.md` for the full masking rules and priorities.

### setDefaultMasking

```kotlin
CSQ.setDefaultMasking(masked: Boolean)
```

Set the global masking default. **Does not affect `EditText` or Compose `TextField`** (these always require explicit unmasking by instance or by type).

### mask / unmask (view instance)

```kotlin
CSQ.mask(sensitiveView)
CSQ.unmask(safeView)
```

### mask / unmask (view type) — EA

```kotlin
CSQ.mask(EditText::class.java)
CSQ.unmask(TextView::class.java)
```

> Not available for Compose. To mask a group of composables, wrap them in a parent and apply `CsqMask`.

### maskTexts

```kotlin
CSQ.maskTexts(mask: Boolean)
```

Global text masking switch.

### Kotlin extensions

```kotlin
view.csqMaskContents(enable = true)
view.csqIgnoreInteractions()
```

### Compose composables

```kotlin
import com.contentsquare.api.compose.CsqMask
import com.contentsquare.api.compose.CsqIgnoreInteraction
import com.contentsquare.api.compose.CsqTag

CsqMask(enable = true) {
    Text("Sensitive content")
}

CsqIgnoreInteraction(ignore = true) {
    Button(onClick = { }) { Text("Untracked") }
}

CsqTag(CsqTag.ModalBottomSheetLayout) {
    ModalBottomSheetLayout { /* content */ }
}
```

### ignoreInteractions

```kotlin
CSQ.ignoreInteractions(view: View)
```

### Dialog masking extensions (Views)

Available in `com.contentsquare.api.sessionreplay`:

```kotlin
alertDialog.csqMask()
alertDialog.csqUnmaskTitle()
alertDialog.csqUnmaskPositiveButton()
alertDialog.csqUnmaskNegativeButton()
// Also: csqMaskMessage / csqUnmaskMessage, csqMaskNegativeButton, etc.

datePickerDialog.csqMaskHeader()
datePickerDialog.csqMaskCalendar()
datePickerDialog.csqMaskButtonPanel()
// + matching csqUnmask* counterparts

timePickerDialog.csqMaskHeader()
timePickerDialog.csqMaskRadialPicker()
timePickerDialog.csqMaskInputMode()
timePickerDialog.csqMaskButtonPanel()
// + matching csqUnmask* counterparts
```

> Call dialog masking extensions immediately after `dialog.show()`, on the main thread.

### Menu masking

```kotlin
override fun onCreateOptionsMenu(menu: Menu): Boolean {
    menuInflater.inflate(R.menu.activity_main, menu)
    CSQ.unmaskMenuItem(R.id.action_settings)
    CSQ.maskMenuItem(R.id.profile_settings) // contains the user's name
    return true
}
```

---

## Event-Triggered Replays (ETR, optional add-on)

```kotlin
CSQ.triggerReplayForCurrentSession(name = "checkout_funnel")
CSQ.triggerReplayForCurrentScreen(name = "payment_failure")
```

Both methods are `@UiThread` — call from the main thread.

When ETR is enabled (contract-level), only sessions/screens matching the global sample rate or associated with an ETR event are retained server-side.

## Session Replay manual control

```kotlin
CSQ.startSessionReplay()
CSQ.stopSessionReplay()
```

Use when `AnalyticsOptions.sessionReplayAutoStart = false`.

---

## WebView Interoperability

### registerWebView

```kotlin
CSQ.registerWebView(webView: WebView)
```

Register a `WebView` for session stitching. The web pages loaded inside also need the Contentsquare WebView Tracking Tag.

### unregisterWebView

```kotlin
CSQ.unregisterWebView(webView: WebView)
```

---

## Surveys

### triggerSurvey

```kotlin
CSQ.triggerSurvey(triggerName: String)
```

Experience Analytics — Voice of Customer. Trigger a survey by predefined trigger name (configured in the Contentsquare console).

---

## Error Tracking

### CsqOkHttpInterceptor

```kotlin
import com.contentsquare.api.contract.CsqOkHttpInterceptor

val client = OkHttpClient.Builder()
    .addInterceptor(CsqOkHttpInterceptor())
    .build()
```

Experience Analytics. Intercept OkHttp calls to collect API errors automatically. Requires OkHttp 4.x on the classpath.

### setUrlMaskingPatterns

```kotlin
CSQ.setUrlMaskingPatterns(patterns: List<String>)
```

Experience Analytics. Mask sensitive URL paths (regex). Emails embedded in URLs are masked automatically.

### trackNetworkMetric

```kotlin
CSQ.trackNetworkMetric(networkMetric: NetworkMetric)
```

Experience Analytics. Track HTTP network errors manually.

---

## View Tracking

### excludeFromExposureMetric

```kotlin
CSQ.excludeFromExposureMetric(view: View)
```

Experience Analytics. Exclude a `ScrollView` or `RecyclerView` from Exposure Metric computations.

---

## Live source of truth

This file is a local mirror. The official, always-up-to-date API reference is available at:

- **Experience Analytics:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/command-reference/index.md
- **Product Analytics:** https://docs.contentsquare.com/en/csq-sdk-android/product-analytics/command-reference/index.md
- **Documentation index (LLM-friendly):** https://docs.contentsquare.com/llms.txt

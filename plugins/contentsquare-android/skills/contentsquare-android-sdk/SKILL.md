---
name: contentsquare-android-sdk
description: Use this skill when integrating the Contentsquare Android SDK (CSQ) — including Session Replay, screen tracking, transactions, custom events, masking, Jetpack Compose support, privacy opt-in/opt-out, and migration from the Classic Contentsquare or Heap SDKs.
---

# Contentsquare Android SDK Integration

> Tested against CSQ SDK `1.11.x`. The official documentation is the source of truth — see the **References** section to fetch the latest pages on demand.

## Definition of Done

An integration is NOT done until ALL of the following are true. If any item is missing, the integration is broken and no data will reach Contentsquare.

1. ✅ `com.contentsquare.android:sdk:<latest>` is in the module dependencies (and `sdk-compose:<same version>` if Compose is used).
2. ✅ A custom `Application` subclass exists, is registered via `android:name` in `AndroidManifest.xml`, and its `onCreate()` calls `CSQ.start(this, …)`.
3. ✅ **`CSQ.optIn()` is called** — unconditionally, in `Application.onCreate()`, immediately after `CSQ.start(...)`, guarded by a `TODO: REVIEW BEFORE RELEASE` comment. **This is mandatory for the integration phase.** CSQ ships opted-out by default; without `optIn()` logcat shows `enabledForCollection is false` and zero data is uploaded — meaning the integration cannot be verified. Moving `optIn()` to a consent flow is a SEPARATE, LATER task that the app team performs before release; do not attempt it during initial integration. Reporting "integration done" while delegating `optIn()` to a future consent flow is a FAILED integration.
4. ✅ At least one screen is instrumented (`CSQ.trackScreenview(...)` for Views, `TriggeredOnResume { CSQ.trackScreenview(...) }` for Compose).
5. ✅ Logcat smoke test passes — see "Verifying the integration" below. **Look for `Tracked pageview …` / `writeToDb: Attempting to insert session …` / `All pending data has been uploaded`** as positive signals. The line `enabledForCollection is false` is emitted during normal boot and is NOT a failure signal on its own — do not delete `optIn()` because of it.

## Concepts

The CSQ SDK ("CSQ" stands for ContentSQuare) unifies three product lines:

- **Experience Analytics (EA)** — formerly "Contentsquare". Provides Session Replay, screenviews, transactions, dynamic vars, error analysis, surveys (Voice of Customer), heatmaps and zoning. **Active by default** with a plain `CSQ.start(context)`.
- **Product Analytics (PA)** — formerly "Heap". Provides custom events, user properties, event properties, identify / resetIdentity. Activated by passing a `StartConfig.withEnvironmentId(...)` to `start()`.
- **Unified CSQ** — both EA and PA configured via a single `dataSourceId`, passed via `StartConfig.withDataSourceId(...)`.

Pick one of the three `start()` overloads below depending on what the customer has subscribed to. EA only is the most common entry point.

## Install

**Always fetch the latest stable version** from Maven Central before adding the dependency.
Do not leave a `<version>` placeholder.

Each artifact has its own metadata file. Fetch BOTH:

- `sdk`: `https://repo1.maven.org/maven2/com/contentsquare/android/sdk/maven-metadata.xml`
- `sdk-compose` (only if Jetpack Compose is used): `https://repo1.maven.org/maven2/com/contentsquare/android/sdk-compose/maven-metadata.xml`

These files are served directly by Maven Central and are the source of truth.
Do NOT use the `search.maven.org` API — its index lags behind and frequently returns outdated versions.

How to pick the version from each `maven-metadata.xml`:

1. Read all `<version>` entries inside `<versioning><versions>`.
2. Filter out any pre-release: discard versions containing `-SNAPSHOT`, `-alpha`, `-beta`, `-rc`, `-dev`, `-M` (case-insensitive).
3. Sort the remaining versions using semantic version ordering (compare numerically: major, then minor, then patch).
4. Pick the highest one. The `<latest>` tag MAY be used as a hint, but always cross-check it is not a pre-release.

Version alignment rule:

- `sdk` and `sdk-compose` MUST be pinned to the exact same version string.
- Compute the latest stable for each artifact independently, then use the **highest version that exists in BOTH lists**.

```kotlin
// Module-level build.gradle.kts
dependencies {
    implementation("com.contentsquare.android:sdk:X.Y.Z") // resolved latest stable

    // Only if the app uses Jetpack Compose (MUST match sdk version exactly):
    implementation("com.contentsquare.android:sdk-compose:X.Y.Z")
}
```

### Project requirements

- **minSdkVersion**: 21 (Android 5.0 Lollipop)
- **compileSdkVersion**: 34 or higher
- **Java**: 11 (`sourceCompatibility` / `targetCompatibility` / `jvmTarget` = 11; lower Java versions yield a `bad class file` error). Java 17+ also works.
- **Kotlin**: 1.8.22 (the SDK ships with `stdlib`; in case of conflict, exclude `org.jetbrains.kotlin:kotlin-stdlib-jdk8`)
- **Jetpack Compose**: Compose Compiler 1.4.8 (Compose BOM 2024.09.00 tested) — when using `sdk-compose`

No `AndroidManifest.xml` permissions need to be added manually — the SDK declares what it needs and merges it automatically.

## Quick Start

Minimal Experience Analytics integration. **Both `CSQ.start(...)` AND `CSQ.optIn()` are required for the SDK to collect any data**: without `optIn()` the user is opted-out by default and `enabledForCollection` stays `false` (visible in logcat). Always emit BOTH calls — never omit `optIn()` from the Quick Start integration even if it looks like it should live in a consent flow. The `TODO: REVIEW BEFORE RELEASE` comment is the contract that signals to a reviewer the call must be moved to the real consent flow before shipping.

```kotlin
import android.app.Application
import com.contentsquare.CSQ

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CSQ.start(this)
        // TODO: REVIEW BEFORE RELEASE — `optIn()` MUST be wired to your real
        // consent flow (CMP / consent dialog) and NOT called unconditionally
        // here.
        CSQ.optIn()
    }
}
```

Don't forget to register `MyApplication` in `AndroidManifest.xml`:

```xml
<application android:name=".MyApplication" ... >
```

Track a screen (Android Views):

```kotlin
import com.contentsquare.CSQ

class HomeActivity : AppCompatActivity() {
    override fun onResume() {
        super.onResume()
        CSQ.trackScreenview("HomeScreen")
    }
}
```

Track a screen (Jetpack Compose):

```kotlin
import com.contentsquare.CSQ
import com.contentsquare.api.compose.TriggeredOnResume

@Composable
fun HomeScreen() {
    TriggeredOnResume {
        CSQ.trackScreenview("HomeScreen")
    }
    // screen content
}
```

### Verifying the integration

The integration is verified end-to-end when **both** of these logs appear in the same run:

1. **SDK boot** (always emitted):

   ```
   CSQ <version> for <Product Analytics|Experience Analytics> is attempting to start.
   ```

   and

   ```
   Contentsquare SDK <legacy-version> starting in app: <package>
   ```

2. **Data is being collected and persisted** — at least one of:
   ```
   Tracked pageview from android_view_autocapture.
   User.writeToDb: Attempting to insert user - envId: <ID>, userId: <ID>, ...
   writeToDb: Attempting to insert session - envId: <ID>, userId: <ID>, sessionId: <ID>
   All pending data has been uploaded.
   ```
   Any of these proves `optIn()` worked and data is flowing.

#### ⚠️ Do NOT use `enabledForCollection` as a diagnostic

The line:

```
BatchUploaderOrchestrator: Condition not met - state.isFullyStopped: false  enabledForCollection is false.
```

is emitted **multiple times during normal SDK boot** — even when `optIn()` has been called correctly — because the orchestrator runs before the in-memory state has finished loading. **It is NOT a failure signal on its own.** Three or four occurrences interleaved with `Starting service DXA` / `Starting service PA` are expected.

It only indicates a real problem if **no** "writeToDb" / "Tracked pageview" / "All pending data has been uploaded" line ever appears in the same logcat session. Do not delete `CSQ.optIn()` from the integration based on this log.

#### Common failure modes

- ❌ Boot log present, but never any `writeToDb: Attempting to insert user`/`session` line → `CSQ.optIn()` is missing or never reached. Add `CSQ.optIn()` immediately after `CSQ.start(...)` in `Application.onCreate()` (see Definition of Done item 3).
- ❌ No `CSQ` logs at all → your `Application` subclass is not registered in `AndroidManifest.xml` via `android:name=".MyApplication"`.
- ❌ `404` on `mobile-production.content-square.net/android/config/v2/<package>.json` → the Contentsquare project is not provisioned for this `applicationId` yet. Expected during early integration; ask the customer to create the project. Tracking still works locally; events are persisted to SQLite and uploaded once the project exists.
- ❌ `onTrackingStarted: config, or environment null aborting.` appearing once during boot → harmless: it's the EA path complaining when the app is started PA-only. Ignore unless it persists for many seconds.

To get verbose logs during development, enable debug logging right after `start()`:

```kotlin
import com.contentsquare.api.model.LogLevel
CSQ.debug.logLevel = LogLevel.DEBUG
```

## Starting the SDK — three overloads

All start variants are exposed on `com.contentsquare.CSQ`. Note that the package is `com.contentsquare`, **not** `com.contentsquare.android`.

### 1. Experience Analytics only (default)

```kotlin
CSQ.start(context = this)
```

### 2. Product Analytics (with optional EA extension) — `environmentId`

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

> `StartConfig` is a top-level sealed class in package `com.contentsquare`. `AnalyticsOptions`, `Transaction`, `Currency`, `CustomVar`, `NetworkMetric`, `Metadata`, `Debug`, `LogLevel` all live in `com.contentsquare.api.model`.

### 3. Unified CSQ — `dataSourceId`

```kotlin
CSQ.start(
    context = this,
    StartConfig.withDataSourceId(id = "YOUR_DATASOURCE_ID")
)
```

`environmentId` and `dataSourceId` are obtained from the Contentsquare project settings on `app.contentsquare.com`. Never hardcode them — read from `BuildConfig`, environment variables, or a config resource.

### `AnalyticsOptions` (current options, v1.11.x)

| Option                                   | Type               | Default                                  | Purpose                                                                                                                                    |
| ---------------------------------------- | ------------------ | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `enableViewAutocapture`                  | `Boolean`          | `false`                                  | Auto-capture UI interactions and source pageviews (Android Views only — no Compose).                                                       |
| `disablePageviewAutocapture`             | `Boolean`          | `false`                                  | Disable autocaptured source pageviews.                                                                                                     |
| `enablePushNotificationAutocapture`      | `Boolean`          | `false`                                  | Auto-capture interactions on notifications.                                                                                                |
| `enablePushNotificationTitleAutocapture` | `Boolean`          | `false`                                  | Capture notification title (requires `enablePushNotificationAutocapture = true`).                                                          |
| `enablePushNotificationBodyAutocapture`  | `Boolean`          | `false`                                  | Capture notification body (requires `enablePushNotificationAutocapture = true`).                                                           |
| `baseUri`                                | `URI`              | `URI("https://mh.bf.contentsquare.net")` | Base URI for the API endpoint.                                                                                                             |
| `uploadInterval`                         | `Double` (seconds) | `15.0`                                   | Interval for event batch uploads.                                                                                                          |
| `sessionReplayAutoStart`                 | `Boolean`          | `true`                                   | Set to `false` to disable automatic Session Replay start; control it manually with `CSQ.startSessionReplay()` / `CSQ.stopSessionReplay()`. |

`StartConfig.dxa()` also accepts an optional `AnalyticsOptions` parameter (e.g. to disable Session Replay auto-start in EA-only mode).

> Older docs and the previous `CSQ.configureProductAnalytics(...)` method are **deprecated**. Always use `CSQ.start(context, StartConfig.…)` for new integrations.

## Heap autocapture (PA / Unified mode only)

> **Skip this entire section if the customer started CSQ with `CSQ.start(context)` alone (EA-only mode).** The `io.heap.gradle` plugin and `ComposeAutocaptureSDK` only apply when CSQ is started with `StartConfig.withEnvironmentId(...)` (Product Analytics) or `StartConfig.withDataSourceId(...)` (Unified). EA-only integrations get pageviews via the explicit `CSQ.trackScreenview(...)` API and do not need any of this.

When the customer provides an `environmentId` (PA) or `dataSourceId` (Unified), they have opted into Heap-style autocapture. To actually capture interactions automatically (button taps, screen views, etc.), the app must add bytecode instrumentation via the **Heap Gradle Plugin**.

### View autocapture (Android Views)

1. Apply the plugin in the **module** `build.gradle.kts` (NOT settings, NOT root):

   ```kotlin
   plugins {
       id("com.android.application")
       kotlin("android")
       id("io.heap.gradle") version "1.1.1" // latest stable
   }
   ```

   Latest stable available at: `https://repo1.maven.org/maven2/io/heap/gradle/io.heap.gradle.gradle.plugin/maven-metadata.xml`. Apply the same selection rule as for `sdk` / `sdk-compose`.

2. Enable view autocapture via `AnalyticsOptions` (this calls `ViewAutocaptureSDK.register()` internally — do NOT call it manually):

   ```kotlin
   CSQ.start(
       context = this,
       StartConfig.withEnvironmentId(
           id = BuildConfig.CSQ_ENVIRONMENT_ID,
           options = AnalyticsOptions(enableViewAutocapture = true)
       )
   )
   ```

Verification: logcat shows `Source android_view_autocapture successfully registered.` and (after a tap or screen change) `Tracked pageview from android_view_autocapture.`.

### Compose autocapture

`enableViewAutocapture = true` does **NOT** cover Jetpack Compose — its doc string explicitly says _"Only for Android View system, no Compose support."_ For Compose autocapture, all THREE of the following are required:

1. `io.heap.gradle` plugin applied (same as for View autocapture above).
2. The `sdk-compose` artifact already pulled in via `implementation("com.contentsquare.android:sdk-compose:<version>")` (it transitively brings `io.heap.autocapture:heap-autocapture-compose`).
3. **Manual** registration after `CSQ.start(...)`:

   ```kotlin
   import io.heap.autocapture.compose.ComposeAutocaptureSDK

   override fun onCreate() {
       super.onCreate()
       CSQ.start(this, StartConfig.withEnvironmentId(BuildConfig.CSQ_ENVIRONMENT_ID))
       ComposeAutocaptureSDK.register()  // Compose autocapture is NOT enabled by AnalyticsOptions
       CSQ.optIn() // TODO: REVIEW BEFORE RELEASE — see Privacy/Consent
   }
   ```

   Note the import: `io.heap.autocapture.compose.ComposeAutocaptureSDK` (it lives in the bundled Heap autocapture-compose module, NOT in `com.contentsquare.*`).

Verification: logcat shows `Source android_compose_autocapture successfully registered.`. The line `(HeapInstrumentation) semantics: capture is disabled; using stock Modifier.semantics` is normal — semantics capture is opt-in via `ComposeAutocaptureSDK.register(enableSemanticsCapture = true)`; default is fine for most apps.

### Manual screenviews still work alongside autocapture

Even with autocapture enabled, you can (and often should) emit named screenviews via `CSQ.trackScreenview("Conversation")` or `TriggeredOnResume { … }` in Compose. Manual names yield more meaningful labels in the Heap UI than auto-derived class/route names.

## Privacy / Consent

The SDK considers every user **opted-out by default**. Tracking only starts after `optIn()` is called.

```kotlin
// In your consent UI (button click, dialog confirmation, etc.)
CSQ.optIn()

// To revoke consent
CSQ.optOut()
```

> A previous `CSQ.optIn(context: Context)` overload exists but is **deprecated** — always use the no-arg `CSQ.optIn()`.

Rules:

- Call `optIn()` **after** `start()`.
- Never call `optIn()` automatically in `Application.onCreate()` — wait for explicit user consent.
- `optOut()` deletes the user ID and stops all tracking until `optIn()` is called again.
- To get the Contentsquare user ID for a Data Subject Request: `CSQ.metadata.userId`.

### Pause / Resume

Temporarily pause tracking on sensitive screens (e.g. a payment flow):

```kotlin
CSQ.pauseTracking()
// ... user is on the sensitive screen ...
CSQ.resumeTracking()
```

## API Surface

All methods live on the `com.contentsquare.CSQ` object.

### Lifecycle

- `CSQ.start(context)` — Start the SDK (EA only).
- `CSQ.start(context, StartConfig.withEnvironmentId(id, options))` — PA (+ optional EA).
- `CSQ.start(context, StartConfig.withDataSourceId(id))` — Unified CSQ.
- `CSQ.stop()` — Shut down the SDK.
- `CSQ.pauseTracking()` / `CSQ.resumeTracking()` — Temporarily pause/resume data collection.

### Privacy

- `CSQ.optIn()` — Opt user into tracking. Must be called after `start()`.
- `CSQ.optOut()` — Stop tracking and clear user data.

### Identity

- `CSQ.identify(identity: String)` — (PA) Assign an identity. Max 255 chars. Triggers a new user ID + session.
- `CSQ.resetIdentity()` — (PA) Clear identity and start a new session.
- `CSQ.sendUserIdentifier(identifier: String)` — (EA) Send a hashed user identifier. Max 100 chars. Recommended to call on every foreground entry (use `ProcessLifecycleOwner`).

### Screen tracking

- `CSQ.trackScreenview(name: String, customVars: List<CustomVar> = emptyList())` — Track a screen view.
- `CustomVar(index: Int /* 0..20 */, name: String /* ≤ 512 chars */, value: String /* ≤ 255 chars */)`
- `TriggeredOnResume { ... }` (composable, in `com.contentsquare.api.compose`) — Wraps `trackScreenview` calls in Compose to fire only once per screen presentation.

Screen names: keep distinct names under 100 per app. Never include PII (no emails, names, account IDs, etc.).

### Transactions (EA)

```kotlin
import com.contentsquare.api.model.Transaction
import com.contentsquare.api.model.Currency

val transaction = Transaction(value = 430.99f, currency = Currency.EUR, id = "order_123")
CSQ.trackTransaction(transaction)
```

Signature: `Transaction(value: Float, currency: Currency, id: String? = null)`.

⚠️ **Send each transaction only once.** A common mistake is to call this from `onResume()` of a confirmation screen, which fires it every time the user re-foregrounds the app.

`Currency` is an enum following ISO 4217. Helpers: `Currency.fromString("USD")`, `Currency.fromInteger(840)`, `Currency.USD.stringCode`.

### Custom events and properties

- `CSQ.trackEvent(event: String, properties: Map<String, Any> = mapOf())` — (PA) Track a named event.
- `CSQ.addUserProperties(properties: Map<String, Any>)` — (PA) Set user-level properties.
- `CSQ.addEventProperties(properties: Map<String, Any>)` — (PA) Set properties added to all subsequent events.
- `CSQ.removeEventProperty(key: String)` — (PA) Remove one event-wide property.
- `CSQ.clearEventProperties()` — (PA) Remove all event-wide properties.
- `CSQ.addDynamicVar(key: String, value: String)` / `CSQ.addDynamicVar(key: String, value: Long)` — (EA) Add a session-level variable. Key max 512 chars; max 40 distinct keys per screenview.

Property values: `String`, `Number`, `Boolean`, or objects implementing the `Property` interface.

### Session Replay masking

Default behavior: **everything is masked**. Unmask explicitly the elements you want visible.

Views:

- `CSQ.setDefaultMasking(masked: Boolean)` — Global default. Does not affect `EditText` / Compose `TextField`.
- `CSQ.mask(view: View)` / `CSQ.unmask(view: View)` — Per-instance.
- `CSQ.mask(type: Class<*>)` / `CSQ.unmask(type: Class<*>)` — Per-type. (EA)
- `CSQ.maskTexts(mask: Boolean)` — Global text masking switch.
- `view.csqMaskContents(enable: Boolean)` — Kotlin extension on `View`.
- `CSQ.ignoreInteractions(view: View)` / `view.csqIgnoreInteractions()` — Stop gesture tracking for a view.

Compose:

- `CsqMask(enable: Boolean) { content }` — Mask a composable subtree (Session Replay + analytics).
- `CsqIgnoreInteraction(ignore: Boolean) { content }` — Ignore interactions on a subtree.
- `CsqTag(CsqTag.ModalBottomSheetLayout) { content }` — Tag a composable for special handling (Heatmap/Zoning support of `ModalBottomSheetLayout`).

Dialogs (Views) — extension functions in `com.contentsquare.api.sessionreplay`:

- `AlertDialog.csqMask()`, `csqMaskTitle()`, `csqMaskMessage()`, `csqMaskPositiveButton()`, `csqMaskNegativeButton()` (and `csqUnmask…` counterparts).
- `DatePickerDialog.csqMask()`, `csqMaskHeader()`, `csqMaskCalendar()`, `csqMaskButtonPanel()` (and `csqUnmask…` counterparts).
- `TimePickerDialog.csqMask()`, `csqMaskHeader()`, `csqMaskRadialPicker()`, `csqMaskInputMode()`, `csqMaskButtonPanel()` (and `csqUnmask…` counterparts).
- Call these immediately after `dialog.show()` on the main thread.

Menus (Views):

- `CSQ.maskMenuItem(itemId)` / `CSQ.unmaskMenuItem(itemId)` — Mask/unmask a single menu entry.

Where to call masking:

- **Activity**: in `onCreate()`.
- **Fragment**: in `onViewCreated()`.
- Always before the first draw, on the UI thread.

Limitations to keep in mind:

- Animations are not supported when masking by instance or by type — mask the parent or the entire screen instead.
- Compose: masking by **type** is not available; wrap a parent composable in `CsqMask` instead.
- `SurfaceView`, `MapView` content cannot be partially masked.

### Session Replay control

When `AnalyticsOptions.sessionReplayAutoStart = false`, control recording manually:

```kotlin
CSQ.startSessionReplay()
// ...
CSQ.stopSessionReplay()
```

### Event-Triggered Replays (ETR, optional add-on)

```kotlin
CSQ.triggerReplayForCurrentSession(name = "checkout_funnel")
CSQ.triggerReplayForCurrentScreen(name = "payment_failure")
```

### WebView tracking

```kotlin
CSQ.registerWebView(webView)
// later:
CSQ.unregisterWebView(webView)
```

The web pages loaded inside also need the Contentsquare WebView Tracking Tag — see the WebView docs.

### Surveys (EA Voice of Customer)

```kotlin
CSQ.triggerSurvey("purchase-complete")
```

### Error tracking (EA)

```kotlin
import com.contentsquare.api.contract.CsqOkHttpInterceptor

val client = OkHttpClient.Builder()
    .addInterceptor(CsqOkHttpInterceptor())
    .build()

// Mask sensitive URL paths
CSQ.setUrlMaskingPatterns(listOf("/users/[0-9]+", "/orders/[A-Z0-9-]+"))

// Manual network metric tracking (statusCode required for proper error reporting)
import com.contentsquare.api.model.NetworkMetric
import com.contentsquare.api.model.HttpMethod

val metric = NetworkMetric("http://www.example.com", HttpMethod.GET)
// ... perform request ...
metric.statusCode = 500
metric.responseBody = body
CSQ.trackNetworkMetric(metric)

// Manual gesture tracking when autocapture is not enough
override fun dispatchTouchEvent(motionEvent: MotionEvent): Boolean {
    CSQ.trackMotionEvent(motionEvent)
    return super.dispatchTouchEvent(motionEvent)
}
```

> `CsqOkHttpInterceptor` requires OkHttp 4.x on the classpath (declared `compileOnly` in the SDK).

### View tracking

- `CSQ.excludeFromExposureMetric(view: View)` — Exclude a `ScrollView` or `RecyclerView` from Exposure Metrics. (EA)

### Debug, logging, metadata

```kotlin
import com.contentsquare.api.model.LogLevel

CSQ.debug.logLevel = LogLevel.DEBUG // NONE, ERROR, WARN, INFO (default), DEBUG, TRACE
CSQ.debug.logChannel = customLogChannel // Implement com.contentsquare.api.contract.LogChannel to route to Timber, etc.

val userId       = CSQ.metadata.userId
val sessionId    = CSQ.metadata.sessionId
val projectId    = CSQ.metadata.projectId
val envId        = CSQ.metadata.environmentId
val replayUrl    = CSQ.metadata.sessionReplayUrl
val identity     = CSQ.metadata.identity

CSQ.metadata.onChanged = OnMetadataChanged { metadata ->
    // Forward replay URL to your CRM / crash reporter
}
// Unregister:
CSQ.metadata.onChanged = null
```

## Common Patterns

### 1. Application initialization (EA only)

```kotlin
import com.contentsquare.api.model.LogLevel

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CSQ.start(this)
        if (BuildConfig.DEBUG) CSQ.debug.logLevel = LogLevel.DEBUG
        // TODO: REVIEW BEFORE RELEASE — wire `optIn()` to your real consent flow.
        CSQ.optIn()
    }
}
```

### 2. Application initialization (Product Analytics)

```kotlin
import com.contentsquare.CSQ
import com.contentsquare.StartConfig
import com.contentsquare.api.model.AnalyticsOptions

class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        CSQ.start(
            context = this,
            StartConfig.withEnvironmentId(
                id = BuildConfig.CSQ_ENV_ID,
                options = AnalyticsOptions(enableViewAutocapture = true)
            )
        )
    }
}
```

### 3. Consent flow

```kotlin
fun handleConsent(userAccepted: Boolean) {
    if (userAccepted) CSQ.optIn() else CSQ.optOut()
}
```

### 4. Track a purchase

```kotlin
CSQ.trackTransaction(
    Transaction(value = 49.99f, currency = Currency.EUR, id = "txn_abc")
)
```

### 5. Custom event with properties (PA)

```kotlin
CSQ.trackEvent(
    event = "add_to_cart",
    properties = mapOf(
        "product_id" to "sku_123",
        "quantity"   to 2,
        "is_promo"   to true
    )
)
```

### 6. OkHttp error tracking

```kotlin
import com.contentsquare.api.contract.CsqOkHttpInterceptor

val client = OkHttpClient.Builder()
    .addInterceptor(CsqOkHttpInterceptor())
    .build()
```

### 7. Compose screen with selective masking

```kotlin
@Composable
fun ProductDetailScreen(product: Product) {
    TriggeredOnResume { CSQ.trackScreenview("ProductDetail") }
    Column {
        Text(text = product.name) // masked by default
        CsqMask(enable = false) {
            Text(text = product.publicDescription) // explicitly visible
        }
    }
}
```

### 8. Sending a hashed user identifier on each foreground entry (EA)

```kotlin
ProcessLifecycleOwner.get().lifecycle.addObserver(object : DefaultLifecycleObserver {
    override fun onStart(owner: LifecycleOwner) {
        currentUser?.email?.let { CSQ.sendUserIdentifier(it) }
    }
})
```

## Anti-patterns to avoid

- ❌ `CSQ.trackScreenview("user@example.com")` → PII in screen names. ✅ `"ProfileScreen"`.
- ❌ Hardcoding `environmentId` / `dataSourceId` in source. ✅ Use `BuildConfig` or a resource.
- ❌ Shipping `CSQ.optIn()` unconditionally in `Application.onCreate()` to **production**. ✅ Wire it to your real consent flow (CMP / consent dialog) before release. It is acceptable to leave it in `onCreate()` during initial integration & QA — guarded by a `TODO: REVIEW BEFORE RELEASE` comment — so the SDK can be validated end-to-end.
- ❌ Sending the same `Transaction` from `onResume()` of the confirmation screen. ✅ Send once, after the order succeeds.
- ❌ Different versions for `sdk` and `sdk-compose`. ✅ Pin both to the exact same version.
- ❌ Using deprecated `CSQ.configureProductAnalytics(...)`. ✅ Use `CSQ.start(context, StartConfig.…)`.
- ❌ Calling `CSQ.trackScreenview` directly inside a `@Composable` (fires on every recomposition). ✅ Wrap with `TriggeredOnResume { … }`.
- ❌ Calling `CSQ.optIn()` before `CSQ.start()`. ✅ `start` first, then `optIn`.

## Migrating from older versions

If the host app already declares the CSQ SDK (`com.contentsquare.android:sdk`) at an older version, load the matching migration guide **before** touching anything else:

| Current version   | Target version | Guide                                                                        |
| ----------------- | -------------- | ---------------------------------------------------------------------------- |
| `1.0.x` – `1.5.x` | `1.11.x`       | [`references/migration-1.5-to-1.11.md`](references/migration-1.5-to-1.11.md) |

For migrations from the **Classic Contentsquare SDK** (`com.contentsquare.android:library`) or the **Heap Core + Contentsquare** combo, fetch the dedicated `upgrade-from-cs-sdk` / `upgrade-from-heap-and-cs-sdk` pages from the Contentsquare docs (see the _References_ section below) — those paths are not covered by this skill.

## References

The official Contentsquare docs expose Markdown versions of every page — fetch them on demand for the most up-to-date information. Always prefer these over a cached snapshot in this skill.

- **Documentation index (LLM-friendly):** https://docs.contentsquare.com/llms.txt
- **Getting started (Experience Analytics):** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/index.md
- **Getting started (Product Analytics):** https://docs.contentsquare.com/en/csq-sdk-android/product-analytics/index.md
- **EA SDK API reference:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/command-reference/index.md
- **PA SDK API reference:** https://docs.contentsquare.com/en/csq-sdk-android/product-analytics/command-reference/index.md
- **Compatibility (minSdk, Java/Kotlin/Compose versions):** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/compatibility/index.md
- **Privacy & consent:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/privacy/index.md
- **Session Replay (masking deep dive):** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/session-replay/index.md
- **Track screens:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/track-screens/index.md
- **Track transactions:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/track-transactions/index.md
- **Troubleshooting:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/troubleshooting/index.md
- **Changelog:** https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/changelog/index.md
- **Sample Android app (GitHub):** https://github.com/ContentSquare/contentsquare-android-sample

When to load each reference:

- Need exact method signatures or full parameter lists → fetch the API reference.
- Implementing or debugging masking → fetch the Session Replay page.
- Compatibility / version conflicts (Kotlin, Compose, dependencies) → fetch the Compatibility page.
- Migrating from the Classic Contentsquare SDK or Heap → fetch the corresponding `upgrade-from-…` page from `llms.txt`.

Local mirror of selected references is also available next to this skill:

- [references/api-reference.md](references/api-reference.md)
- [references/session-replay.md](references/session-replay.md)
- [references/migration-1.5-to-1.11.md](references/migration-1.5-to-1.11.md)

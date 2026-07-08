# Migrating from CSQ SDK 1.5.x → 1.11.x

> **When to load this file:** the host app already declares `com.contentsquare.android:sdk` (and usually `com.contentsquare.android:sdk-compose`) at a version `1.0.x – 1.5.x` and needs to upgrade to `1.11.x`.
>
> For migrations from the **Classic Contentsquare SDK** (`com.contentsquare.android:library`) or the **Heap Core + Contentsquare** combo, do NOT use this file — fetch the dedicated `upgrade-from-cs-sdk` / `upgrade-from-heap-and-cs-sdk` pages from the Contentsquare docs instead.
>
> No `1.6.x – 1.9.x` versions were ever published — Maven Central jumps straight from `1.5.2` to `1.11.0`. Do not look for an intermediate version.

## 1. Bump the dependency

```kotlin
// Before
implementation("com.contentsquare.android:sdk:1.5.2")
implementation("com.contentsquare.android:sdk-compose:1.5.2")

// After — keep both artifacts on the exact same version
implementation("com.contentsquare.android:sdk:1.11.0")
implementation("com.contentsquare.android:sdk-compose:1.11.0")
```

Always re-check Maven Central for the latest published version of **both** artifacts and pick the highest version present in both — see the _Install_ section of `SKILL.md`. If you cannot reach Maven Central, fall back to `1.11.0` (known good at the time this guide was written).

## 2. `CSQ.start()` signature change (breaking)

`CSQ.start()` now takes a `StartConfig` wrapper. The old `CSQ.configureProductAnalytics(...)` entry point has been removed.

```kotlin
// Before (1.5.x) — Product Analytics
CSQ.configureProductAnalytics(
    context = this,
    envId = "YOUR_ENVIRONMENT_ID",
    options = ProductAnalyticsOptions(enableViewAutocapture = true),
)
CSQ.start(this)

// After (1.11.x) — Product Analytics
CSQ.start(
    context = this,
    StartConfig.withEnvironmentId(
        id = "YOUR_ENVIRONMENT_ID",
        options = AnalyticsOptions(enableViewAutocapture = true),
    ),
)
```

Experience-Analytics-only callers (`CSQ.start(this)` with no second argument) are **not affected** — the no-arg overload still exists.

## 3. `ProductAnalyticsOptions` → `AnalyticsOptions` (renamed)

The class was renamed and `envId` was renamed to `id` on the factory. Several Product Analytics tuning options were **removed entirely** and must be deleted from your call site or the project will not compile:

- `captureVendorId`
- `captureAdvertiserId`
- `clearEventPropertiesOnNewUser`
- `messageBatchMessageLimit`
- `resumePreviousSession`
- `pruningLookBackWindow`
- `maximumDatabaseSize`
- `maximumBatchCountPerUpload`
- `disableUploadsInBackground`
- `disableScreenviewForwardToDXA`
- `disableScreenviewForwardToPA`

A new option was **added**: `sessionReplayAutoStart` (defaults to `true`; set to `false` to drive Session Replay manually via `CSQ.startSessionReplay()` / `CSQ.stopSessionReplay()`).

## 4. `CSQ.optIn(context)` deprecated

```kotlin
// Before
CSQ.optIn(this)

// After
CSQ.optIn()
```

The context-taking overload still works at runtime in `1.11.x` but is deprecated; switch to the no-arg version.

## 5. Behavior change — Session timeout (Experience Analytics)

In `1.11.x` (EA `4.50.0`) the EA session timeout definition changed from _"30 minutes after the app went to background"_ to **"30 minutes after the last event"**. Sessions in active foreground use will now also roll over after 30 minutes of inactivity. Consider this when computing session-scoped metrics across the upgrade boundary.

## 6. Migration checklist

- [ ] Both `sdk` and `sdk-compose` updated to the same `1.11.x` version.
- [ ] `CSQ.configureProductAnalytics(...)` replaced by `CSQ.start(context, StartConfig.withEnvironmentId(...))`.
- [ ] `ProductAnalyticsOptions` renamed to `AnalyticsOptions`; removed options deleted from the call site.
- [ ] `CSQ.optIn(this)` replaced by `CSQ.optIn()`.
- [ ] Build compiles — any remaining unresolved symbol is a removed option (delete it) or an internal API (was never public, must not be used).
- [ ] Logcat smoke test passes (see _Verifying the integration_ in `SKILL.md`).

## 7. (Optional) Switch to Unified CSQ

If your CSM has provisioned a Unified CSQ data source for the app, replace the environment ID with the data source ID in the same call:

```kotlin
CSQ.start(this, StartConfig.withDataSourceId("YOUR_DATASOURCE_ID"))
```

Find the data source ID in the Unified CSQ web app under **Definitions → Data sources → \[your mobile data source\] → App ID**, or ask your CSM. Do **not** invent or guess this value.

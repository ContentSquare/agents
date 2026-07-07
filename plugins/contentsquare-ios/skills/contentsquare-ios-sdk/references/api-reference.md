# Contentsquare iOS SDK -- CSQ API Reference

Entry point: `import ContentsquareSDK`

All methods are static members on the `CSQ` class.

---

## Lifecycle

### start (DXA only)

```swift
static func start()
static func start(options: [AnalyticsOption: Any] = [:])
```

Starts the SDK in DXA-only mode. Must be called before any other CSQ method, as early as possible in the app lifecycle.

- UIKit: call in `application(_:didFinishLaunchingWithOptions:)`
- SwiftUI: call in `App.init()`

### start (Product Analytics with environment ID)

```swift
static func start(environmentID: String, options: [AnalyticsOption: Any] = [:])
```

Starts Product Analytics with the given environment ID, and also starts DXA if configured for the app.

| Parameter       | Type                     | Description                                                           |
| --------------- | ------------------------ | --------------------------------------------------------------------- |
| `environmentID` | `String`                 | Numeric string. Invalid (non-numeric) value logs an error and aborts. |
| `options`       | `[AnalyticsOption: Any]` | Optional configuration. See [AnalyticsOption](#analyticsoption).      |

### start (Product Analytics + DXA with data source ID)

```swift
static func start(dataSourceID: String, options: [AnalyticsOption: Any] = [:])
```

Starts both DXA and Product Analytics with the given data source ID. Preferred for new clients.

| Parameter      | Type                     | Description                                                           |
| -------------- | ------------------------ | --------------------------------------------------------------------- |
| `dataSourceID` | `String`                 | Numeric string. Invalid (non-numeric) value logs an error and aborts. |
| `options`      | `[AnalyticsOption: Any]` | Optional configuration. See [AnalyticsOption](#analyticsoption).      |

### stop

```swift
static func stop()
```

Shuts down the SDK completely. Stops both DXA and Product Analytics.

### pauseTracking

```swift
static func pauseTracking()
```

Temporarily pauses data collection. Use for sensitive screens. Tracking resumes automatically on next app launch.

### resumeTracking

```swift
static func resumeTracking()
```

Resumes tracking after `pauseTracking()`.

---

## Privacy

### isOptedIn

```swift
static var isOptedIn: Bool { get }
```

Returns whether the current device is opted into tracking.

### optIn

```swift
static func optIn()
```

Opts the device into tracking. Tracking starts immediately. All users are opted out by default.

### optOut

```swift
static func optOut()
```

Permanently opts the device out. Tracking stops immediately and never resumes unless `optIn()` is called (generates a new user ID, no link to previous activity) or the app is reinstalled.

---

## Identity

### identify (Product Analytics only)

```swift
static func identify(_ identity: String)
```

Sets the user identity. If a different identity was already set, starts a new session with a new user ID.

| Parameter  | Constraint         |
| ---------- | ------------------ |
| `identity` | Max 255 characters |

### resetIdentity (Product Analytics only)

```swift
static func resetIdentity()
```

Clears the identity set by `identify(_:)`.

### sendUserIdentifier (DXA only)

```swift
static func sendUserIdentifier(_ userIdentifier: String)
```

Sends a user identifier to DXA. The identifier is immediately hashed -- no PII is stored.

| Parameter        | Constraint         |
| ---------------- | ------------------ |
| `userIdentifier` | Max 100 characters |

---

## Screen Tracking

### trackScreenview

```swift
static func trackScreenview(_ name: String, cvars: [CustomVar] = [])
```

Tracks a screen view. Call on every screen appearance — Session Replay will not work without screen tracking.

- UIKit: call in `viewDidAppear(_:)`
- SwiftUI: call in `.onAppear { }`

**Example:**

```swift
CSQ.trackScreenview("ProductDetail")
CSQ.trackScreenview("Checkout", cvars: [
    CustomVar(index: 1, name: "category", value: "electronics")
])
```

### CustomVar

```swift
public init(index: UInt32, name: String, value: String)
```

Additional context attached to a screen view.

| Parameter | Constraint                                                                 |
| --------- | -------------------------------------------------------------------------- |
| `index`   | `UInt32` identifier. Use consistent index for a given name across the app. |
| `name`    | Max 512 characters. Empty string uses `"cs-empty"`.                        |
| `value`   | Max 255 characters. Empty string uses `"cs-empty"`.                        |

---

## Transactions

### trackTransaction

```swift
static func trackTransaction(_ transaction: Transaction)
```

### Transaction

```swift
public init(id: String?, value: Float, currency: Currency)
public init(id: String?, value: Float, currency: String)
```

| Parameter  | Description                                                                                                                 |
| ---------- | --------------------------------------------------------------------------------------------------------------------------- |
| `id`       | Optional purchase identifier.                                                                                               |
| `value`    | Purchase amount as `Float`.                                                                                                 |
| `currency` | ISO 4217 `Currency` enum (e.g. `.usd`, `.eur`, `.gbp`) or a string matching a case name. Invalid string maps to `.unknown`. |

**Example:**

```swift
CSQ.trackTransaction(Transaction(id: "order_123", value: 49.99, currency: .eur))
```

---

## Custom Events and Properties

### trackEvent

```swift
static func trackEvent(_ name: String, properties: [String: PropertyValue] = [:])
```

Tracks a named event with optional properties. Supported `PropertyValue` types: `String`, `Substring`, `Bool`, `Double`, `Float`, `Int`, `Int64`, `Int32`, `Int16`, `Int8`.

**Example:**

```swift
CSQ.trackEvent("add_to_cart", properties: ["product_id": "sku_123", "quantity": 2, "is_promo": true])
```

### addDynamicVar (DXA only)

```swift
static func addDynamicVar(_ dVar: DynamicVar)
```

Adds a session-level dynamic variable.

```swift
public init(key: String, value: String)  // string variant
public init(key: String, value: UInt32)  // int variant
```

| Variant        | Key limit     | Value limit   |
| -------------- | ------------- | ------------- |
| String         | Max 512 chars | Max 255 chars |
| Int (`UInt32`) | Max 50 chars  | 0 to 2^32-1   |

Empty key or string value uses `"cs-empty"`.

### addUserProperties (Product Analytics only)

```swift
static func addUserProperties(_ properties: [String: PropertyValue])
```

Sets properties on the current user.

### addEventProperties (Product Analytics only)

```swift
static func addEventProperties(_ properties: [String: PropertyValue])
```

Sets properties included in all subsequent events. Does not affect already-processed events.

### removeEventProperty (Product Analytics only)

```swift
static func removeEventProperty(_ key: String)
```

Removes one event property added with `addEventProperties`.

### clearEventProperties (Product Analytics only)

```swift
static func clearEventProperties()
```

Removes all event properties added with `addEventProperties`.

---

## Session Replay

### startSessionReplay

```swift
static func startSessionReplay()
```

Starts Session Replay on-demand. Use when `sessionReplayAutoStart: false` was passed at `start()`. Once SR is started, it follows the same rules as automatic start.

**One-shot** — after `stopSessionReplay()` is called, SR cannot be restarted in the same SDK lifetime.

### stopSessionReplay

```swift
static func stopSessionReplay()
```

Stops Session Replay without stopping the rest of the SDK. **Terminal** — SR cannot be restarted after this call.

### triggerReplayForCurrentSession

```swift
static func triggerReplayForCurrentSession(name: String)
```

Flags the current session for replay capture. `name` is used for segmentation/filtering.

### triggerReplayForCurrentScreen

```swift
static func triggerReplayForCurrentScreen(name: String)
```

Flags the current screen for replay capture. `name` is used for segmentation/filtering.

---

## Session Replay Masking

### setDefaultMasking

```swift
static func setDefaultMasking(_ masked: Bool)
```

Sets the global masking state. When `false`, text inputs (`UITextField`, `UITextView`, SwiftUI `TextField`, `TextEditor`) remain masked regardless.

### mask / unmask (view)

```swift
static func mask(_ view: UIView)
static func unmask(_ view: UIView)
```

Masks or unmasks a specific view and its subviews.

### mask / unmask (viewsOfType) (DXA only)

```swift
static func mask(viewsOfType: UIView.Type)
static func unmask(viewsOfType: UIView.Type)
```

Masks or unmasks all instances of a UIView subclass, except those explicitly overridden with `mask(_:)` / `unmask(_:)`.

### ignoreInteractions (Product Analytics only)

```swift
static func ignoreInteractions(_ view: UIView)
```

Prevents interactions on the given view from being tracked.

### maskTexts

```swift
static func maskTexts(_ mask: Bool)
```

Masks or unmasks all `UILabel` (UIKit) and `Text` (SwiftUI) components.

### maskImages

```swift
static func maskImages(_ mask: Bool)
```

Masks or unmasks all `UIImageView` (UIKit) and `Image` (SwiftUI) components.

### maskTextInputs

```swift
static func maskTextInputs(_ mask: Bool)
```

Masks or unmasks all `UITextField`, `UITextView` (UIKit) and `TextField`, `SecureField`, `TextEditor` (SwiftUI) components.

### IBInspectable properties (UIKit)

```swift
var csqMaskContents: Bool        // on UIView — mask/unmask the view
var csqIgnoreInteractions: Bool  // on UIResponder — ignore interactions
var csqIgnoreInnerHierarchy: Bool // on UIResponder — ignore inner hierarchy
```

### SwiftUI modifiers

```swift
.csqMaskContents(true)       // mask the view subtree
.csqIgnoreInteractions(true) // ignore interactions on the view
```

---

## WebView Tracking

### registerWebView

```swift
static func registerWebView(_ webView: WKWebView)
```

Registers a `WKWebView` for tracking. Must be called for every `WKWebView` instance — WebViews are not automatically tracked.

### unregisterWebView

```swift
static func unregisterWebView(_ webView: WKWebView)
```

Unregisters a `WKWebView`. Call on `deinit` or when the WebView is no longer needed.

---

## Surveys (DXA only)

### triggerSurvey

```swift
static func triggerSurvey(_ triggerName: String)
```

Programmatically attempts to trigger a survey by its predefined trigger name. The survey only activates if all configured targeting conditions are met.

---

## Error Tracking (DXA only)

### onCrashReporterStart

```swift
static func onCrashReporterStart(_ onCrashReporterStart: @escaping (Bool) -> Void)
```

Sets a callback to execute after the crash reporter is initialized. The `Bool` argument indicates whether the crash reporter is actually enabled.

**Example:**

```swift
CSQ.onCrashReporterStart { enabled in
    if enabled {
        // Start Firebase Crashlytics or other crash reporter here
    }
}
```

### setURLMaskingPatterns

```swift
static func setURLMaskingPatterns(_ patterns: [String])
```

Masks sensitive data in URL paths captured by error tracking. Email addresses are masked automatically without this API.

Pattern example: `"www.example.com/user/:user_id"` masks all user IDs in that path to `CS_ANONYMIZED_USER_ID`.

---

## CSInApp (DXA only)

### handle(url:)

```swift
static func handle(url: URL)
```

Allows the SDK to monitor CSInApp activation through a custom URL scheme. Call in `application(_:open:options:)` of your `UIApplicationDelegate`.

### csInApp

```swift
static var csInApp: Bool { get set }
```

Read/write property to manually activate or deactivate in-app debug features without an incoming URL.

---

## Exposure Metrics (DXA only)

### excludeFromExposureMetrics

```swift
// UIScrollView extension
func excludeFromExposureMetrics()
```

Excludes a `UIScrollView` from exposure metric tracking.

---

## Debug and Metadata

### debug.logLevel

```swift
static let debug: CSQ.Debug

debug.logLevel: Log.Level  // get/set
```

`Log.Level` values (in increasing severity): `.none`, `.trace`, `.debug`, `.info`, `.warn`, `.error`, `.important` (default).

### debug.logChannel

```swift
debug.logChannel: LogChannel  // get/set
```

Routes SDK logs to a custom logger. Implement the `LogChannel` protocol:

```swift
public protocol LogChannel {
    func printLog(logLevel: Log.Level, message: () -> String, source: String?, file: String, line: UInt)
}
```

### metadata

```swift
static let metadata: CSQ.Metadata
```

Read-only access to current session information.

| Property           | Type      | Description                     |
| ------------------ | --------- | ------------------------------- |
| `userID`           | `String?` | Current user identifier         |
| `sessionID`        | `String?` | Current session identifier      |
| `identity`         | `String?` | Identity set via `identify(_:)` |
| `environmentID`    | `String?` | PA environment ID               |
| `projectID`        | `String?` | DXA project ID                  |
| `sessionReplayURL` | `URL?`    | URL to view the session replay  |

### metadata.onChange

```swift
func onChange(_ handler: @escaping (CSQ.Metadata) -> Void)
```

Sets a callback executed whenever metadata changes. Calling this again overrides the previous closure.

**Example:**

```swift
CSQ.metadata.onChange { metadata in
    print("Replay URL: \(metadata.sessionReplayURL?.absoluteString ?? "none")")
}
```

---

## AnalyticsOption

Configuration options passed to `start(options:)`. All options are optional.

| Option                                    | Type           | Description                                                                                   |
| ----------------------------------------- | -------------- | --------------------------------------------------------------------------------------------- |
| `.uploadInterval`                         | `TimeInterval` | How often events are uploaded                                                                 |
| `.baseURL`                                | `URL`          | Custom API endpoint (e.g. EU data residency)                                                  |
| `.sessionReplayAutoStart`                 | `Bool`         | If `false`, SR doesn't start at launch — use `startSessionReplay()` manually. Default: `true` |
| `.disablePageviewAutocapture`             | `Bool`         | Disable native pageview autocapture                                                           |
| `.disablePageviewTitleAutocapture`        | `Bool`         | Disable iOS page title autocapture                                                            |
| `.disableInteractionAutocapture`          | `Bool`         | Disable native iOS interaction autocapture                                                    |
| `.enableNativeAutocapture`                | `Bool`         | Enable native UIKit autocapture (PA)                                                          |
| `.enablePushNotificationAutocapture`      | `Bool`         | Capture push notification events                                                              |
| `.enablePushNotificationTitleAutocapture` | `Bool`         | Capture push notification title                                                               |
| `.enablePushNotificationBodyAutocapture`  | `Bool`         | Capture push notification body                                                                |

> `.enableUIKitAutocapture` is deprecated — use `.enableNativeAutocapture` instead.
> `ProductAnalyticsOption` is a deprecated typealias for `AnalyticsOption` — prefer `AnalyticsOption` in new code.

---

## Deprecated API

### configureProductAnalytics

```swift
@available(*, deprecated, message: "Use start(environmentID:options:) instead")
static func configureProductAnalytics(environmentID: String, additionalOptions: [ProductAnalyticsOption: Any] = [:])
```

Do not mix with `start(environmentID:options:)` or `start(dataSourceID:options:)`. Migrate to:

```swift
CSQ.start(environmentID: "your-env-id", options: [.enableNativeAutocapture: true])
// or
CSQ.start(dataSourceID: "your-data-source-id")
```

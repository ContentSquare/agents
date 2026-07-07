---
name: contentsquare-ios-sdk
description: Integrate or upgrade the Contentsquare iOS SDK (current version 1.11.x) -- Session Replay, screen tracking, transactions, analytics, masking, privacy opt-in/out. Use when working with Contentsquare, CSQ, CSQ.start, CSQ.trackScreenview, CSQ.optIn, CSQ.registerWebView, WKWebView tracking, or migrating from SDK versions 1.0–1.6 / `configureProductAnalytics` to `CSQ.start(environmentID:options:)`.
---

# Contentsquare iOS SDK Integration

> This skill helps AI agents integrate or upgrade the Contentsquare iOS SDK in client applications.

## Install

### Swift Package Manager (recommended)

See [xcode-project-setup](./references/xcode-project-setup.md) to add https://github.com/ContentSquare/apple-sdk

### CocoaPods

```ruby
pod 'ContentsquareSDK'
```

Then `pod install`.

## Quick Start

```swift
import ContentsquareSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CSQ.start(dataSourceID: "your-data-source-id") // or start(environmentID:) if no data source ID
        CSQ.optIn() // TODO: Only call after user consent. The SDK stays inactive until optIn() is called. Implement a consent prompt and call optIn()/optOut() based on user choice.
        return true
    }
}
```

SwiftUI:

```swift
import ContentsquareSDK

@main
struct MyApp: App {
    init() {
        CSQ.start(dataSourceID: "your-data-source-id") // or start(environmentID:) if no data source ID
        CSQ.optIn() // TODO: Only call after user consent. The SDK stays inactive until optIn() is called. Implement a consent prompt and call optIn()/optOut() based on user choice.
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

For DXA-only (no Product Analytics), use `CSQ.start()` without parameters.

It is very important that screens should be tracked, otherwise Session Replay will not work. You can track screens manually with `trackScreenview()` in `viewWillAppear(_:)` (UIKit) or `.onAppear` (SwiftUI):

```swift
CSQ.trackScreenview("HomeScreen")
```

Before wrapping up the integration, make sure you are handling WebViews if they are present in the app. WebViews are not automatically tracked, and every WebView must be registered. Check the WebView Tracking section below for details.

## Integration Workflow

When integrating Contentsquare into an iOS app, follow this order:

1. **Add dependency** -- SPM: `https://github.com/ContentSquare/apple-sdk.git`, or CocoaPods: `pod 'ContentsquareSDK'`.
2. **Start the SDK** -- Call `CSQ.start(dataSourceID:)` (preferred) or `CSQ.start(environmentID:)` in `application(_:didFinishLaunchingWithOptions:)` or `App.init()`. For DXA-only, use `CSQ.start()`.
3. **Implement consent** -- Add `CSQ.optIn()` with a TODO comment for the customer to manage their own consent flow. The SDK stays inactive until `optIn()` is called.
4. **Set up screen tracking** -- Call `CSQ.trackScreenview(_:)` on each screen appearance (e.g., `viewWillAppear`, `.onAppear`).
5. **Track transactions** -- Use `CSQ.trackTransaction(Transaction(id:, value:, currency:))` for purchases.
6. **Configure Session Replay masking** -- Use `CSQ.setDefaultMasking(true)` globally, then `CSQ.unmask(view)` / `CSQ.mask(view)` or SwiftUI `.csqMaskContents(true)` for sensitive content.
7. **Set up error tracking** -- Use `CSQ.onCrashReporterStart { }` to coordinate with third-party crash reporters.
8. **Register WebViews** -- Call `CSQ.registerWebView(webView)` for every `WKWebView` instance.
9. **Add identity** -- Use `identify()` for Product Analytics or `sendUserIdentifier()` for Experience Analytics.
10. **Configure in-app features** -- Add the custom URL scheme and handle the deeplink. **This step is mandatory** to access screenshot capture, SDK logs, Log Visualizer, and Zoning Analysis. See [references/ios-in-app-features.md](references/ios-in-app-features.md).

## API Surface

Always use `CSQ` from `import ContentsquareSDK`. The `Contentsquare` class is the legacy SDK and should not be used.

### Lifecycle

| Method             | Purpose                                             |
| ------------------ | --------------------------------------------------- |
| `start()`          | Start the SDK. Must be called before any other API. |
| `stop()`           | Shut down the SDK completely.                       |
| `pauseTracking()`  | Pause data collection (for sensitive screens).      |
| `resumeTracking()` | Resume after `pauseTracking()`.                     |

Avoid using `pauseTracking` and `resumeTracking` unless you are specifically asked for it.

### Start Configuration

| Method                            | Use Case                                           | Onboarding priority                                                               |
| --------------------------------- | -------------------------------------------------- | --------------------------------------------------------------------------------- |
| `start(dataSourceID:, options:)`  | Both DXA and Product Analytics with data source ID | **1st choice for new clients** -- ask for this first                              |
| `start(environmentID:, options:)` | Product Analytics with environment ID              | 2nd choice if no data source ID is available                                      |
| `start(options:)`                 | Digital Experience Analytics only                  | Fallback only -- when neither ID is available or DXA-only is explicitly requested |

**Recommended onboarding flow:**

1. Ask the user: _"Do you have a Contentsquare data source ID?"_ If yes, use `CSQ.start(dataSourceID: "your-data-source-id")`.
2. If not, ask: _"Do you have an environment ID?"_ If yes, use `CSQ.start(environmentID: "your-env-id")`.
3. Only if neither is available (or the user explicitly wants DXA-only), fall back to `CSQ.start()`.

Do not invent an ID. Do not silently default to DXA without asking.

Options include: `.uploadInterval`, `.baseURL`, `.disablePageviewAutocapture`, `.enableNativeAutocapture`, `.enablePushNotificationAutocapture`, `.sessionReplayAutoStart`.

### Privacy

| Method     | Purpose                                                              |
| ---------- | -------------------------------------------------------------------- |
| `optIn()`  | Opt the device into tracking. Generates user ID, starts immediately. |
| `optOut()` | Opt out permanently. Stops until `optIn()` or app reinstall.         |

### Identity

| Method                         | Context                      | Purpose                                                              |
| ------------------------------ | ---------------------------- | -------------------------------------------------------------------- |
| `identify("userId")`           | Product Analytics            | Set user identity. Different ID triggers new session. Max 255 chars. |
| `resetIdentity()`              | Product Analytics            | Clear identity.                                                      |
| `sendUserIdentifier("userId")` | Digital Experience Analytics | Send hashed user ID. Max 100 chars.                                  |

### Screen Tracking

| Method                        | Purpose                                             |
| ----------------------------- | --------------------------------------------------- |
| `trackScreenview(_:, cvars:)` | Track a screen view with optional custom variables. |

`CustomVar(index:, name:, value:)` -- index (`UInt32`), name (`String`, max 512 chars), value (`String`, max 255 chars).

### Transactions

```swift
let transaction = Transaction(id: "order_123", value: 29.99, currency: .usd)
CSQ.trackTransaction(transaction)
```

`Currency` is an ISO 4217 enum (e.g., `.usd`, `.eur`, `.gbp`).

### Custom Events and Properties

| Method                                        | Purpose                                       |
| --------------------------------------------- | --------------------------------------------- |
| `trackEvent(_:, properties:)`                 | Track a named event with optional properties. |
| `addDynamicVar(DynamicVar)`                   | Add session-level dynamic variable (EA).      |
| `addUserProperties([String: PropertyValue])`  | Set user-level properties (PA).               |
| `addEventProperties([String: PropertyValue])` | Set properties on all future events (PA).     |
| `removeEventProperty("key")`                  | Remove one event property.                    |
| `clearEventProperties()`                      | Remove all event properties.                  |

`PropertyValue` in Swift: `String`, `Substring`, `Bool`, `Double`, `Float`, `Int`, `Int64`, `Int32`, `Int16`, `Int8`.

`DynamicVar(key:, value:)` -- value is `String` (key max 512 chars, value max 255 chars) or `UInt32` (key max 50 chars).

### Session Replay Masking

| Method                             | Purpose                                                                                                     |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `setDefaultMasking(Bool)`          | Set global masking state. Note: text inputs stay masked even when set to `false`.                           |
| `mask(UIView)`                     | Mask a specific view and its subviews.                                                                      |
| `unmask(UIView)`                   | Unmask a specific view.                                                                                     |
| `mask(viewsOfType: UIView.Type)`   | Mask all views of a type (DXA).                                                                             |
| `unmask(viewsOfType: UIView.Type)` | Unmask all views of a type (DXA).                                                                           |
| `ignoreInteractions(UIView)`       | Ignore interactions on a specific view (PA).                                                                |
| `maskTexts(Bool)`                  | Mask all text content (`UILabel`, SwiftUI `Text`).                                                          |
| `maskImages(Bool)`                 | Mask all image components (`UIImageView`, SwiftUI `Image`).                                                 |
| `maskTextInputs(Bool)`             | Mask all text input fields (`UITextField`, `UITextView`, SwiftUI `TextField`, `SecureField`, `TextEditor`). |

UIKit `IBInspectable` properties: `view.csqMaskContents = true`, `view.csqIgnoreInteractions = true`, `view.csqIgnoreInnerHierarchy = true`.

SwiftUI modifiers: `.csqMaskContents(true)`, `.csqIgnoreInteractions(true)`.

### WebView Tracking

| Method                         | Purpose                            |
| ------------------------------ | ---------------------------------- |
| `registerWebView(WKWebView)`   | Register a WKWebView for tracking. |
| `unregisterWebView(WKWebView)` | Unregister a WKWebView.            |

WebViews are **not automatically tracked**. Every `WKWebView` instance must be registered.

### Surveys

| Method                         | Purpose                                                |
| ------------------------------ | ------------------------------------------------------ |
| `triggerSurvey("triggerName")` | Trigger a survey by predefined trigger name (DXA VoC). |

### Error Tracking

| Method                                | Purpose                                         |
| ------------------------------------- | ----------------------------------------------- |
| `onCrashReporterStart { enabled in }` | Callback when crash reporter initializes (DXA). |
| `setURLMaskingPatterns(["pattern"])`  | Mask sensitive URL paths (DXA).                 |
| `trackNetworkMetric(NetworkMetric)`   | Track HTTP network errors (DXA).                |

### CSInApp

> **In-app features must be configured in the app for any of these APIs to work.** Without the URL scheme and deeplink handler in place, `handle(url:)` will never be triggered and in-app features (Screenshot Capture, SDK Logs, Log Visualizer) will not be accessible. See [references/ios-in-app-features.md](references/ios-in-app-features.md) for the full setup.

| Method         | Purpose                                                                             |
| -------------- | ----------------------------------------------------------------------------------- |
| `handle(url:)` | Handle CSInApp URL scheme activation (DXA). Call in `application(_:open:options:)`. |
| `csInApp`      | Read/write property to manually activate or deactivate in-app debug features (DXA). |

### Debug and Metadata

| API                                 | Purpose                                                                               |
| ----------------------------------- | ------------------------------------------------------------------------------------- |
| `debug.logLevel = .debug`           | Set log level (`.none`, `.trace`, `.debug`, `.info`, `.warn`, `.error`, `.important`) |
| `debug.logChannel = customChannel`  | Route logs to custom logger.                                                          |
| `metadata`                          | Access session metadata.                                                              |
| `metadata.onChange { metadata in }` | Listen for metadata changes.                                                          |

Metadata properties: `userID`, `sessionID`, `projectID`, `environmentID`, `sessionReplayURL`, `identity`.

## Common Patterns

### 1. Full initialization with Product Analytics

```swift
import ContentsquareSDK

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    CSQ.start(dataSourceID: "your-data-source-id", options: [.enableNativeAutocapture: true]) // or start(environmentID:) if no data source ID
    CSQ.optIn() // TODO: Only call after user consent
    return true
}
```

### 2. Track a purchase

```swift
let transaction = Transaction(id: "txn_abc", value: 49.99, currency: .eur)
CSQ.trackTransaction(transaction)
```

### 3. Custom event with properties

```swift
CSQ.trackEvent(
    "add_to_cart",
    properties: ["product_id": "sku_123", "quantity": 2, "is_promo": true]
)
```

### 4. Crash reporter coordination

```swift
CSQ.onCrashReporterStart { enabled in
    if enabled {
        // Start Firebase Crashlytics or other crash reporter here
    }
}
```

### 5. SwiftUI screen tracking

```swift
struct ProductDetailView: View {
    var body: some View {
        VStack { /* content */ }
            .onAppear {
                CSQ.trackScreenview("ProductDetail")
            }
    }
}
```

### 6. WebView registration

```swift
let webView = WKWebView()
CSQ.registerWebView(webView)
// When done or on deinit:
CSQ.unregisterWebView(webView)
```

## Platform Guidance

### UIKit

- Call `CSQ.start()` in `application(_:didFinishLaunchingWithOptions:)`.
- Track screens in `viewWillAppear(_:)` with `CSQ.trackScreenview(_:)`.
- Mask views with `CSQ.mask(view)` / `view.csqMaskContents = true`.

### SwiftUI

- Call `CSQ.start()` in `App.init()`.
- Track screens with `.onAppear { CSQ.trackScreenview("ScreenName") }`.
- Mask views with `.csqMaskContents(true)` modifier.
- Ignore interactions with `.csqIgnoreInteractions(true)`.

## Migration from older SDK versions

**Current SDK version: 1.11.x**

This section covers migration from SDK versions **1.0–1.6** to **1.11.x**. If you are migrating from an older version, apply all changes below. They are cumulative — a project on 1.0 must apply every step.

### Step 1 — Upgrade SDK version to 1.11.x

Check whether the SDK is up to date. If not, upgrade the Contentsquare SPM package to 1.11.x.
See [xcode-project-setup](xcode-project-setup.md) for upgrading the Swift Package.

### Step 2 — Replace the deprecated initialization pattern

The two-step `CSQ.configureProductAnalytics(environmentID:, additionalOptions:)` + `CSQ.start()` pattern was removed. Replace it with the unified `CSQ.start(environmentID:, options:)` or `CSQ.start(dataSourceID:, options:)`.

```swift
// Old (removed — will not compile in 1.11.x)
CSQ.configureProductAnalytics(environmentID: "your-env-id", additionalOptions: [.enableUIKitAutocapture: true])

// New
CSQ.start(environmentID: "your-env-id", options: [.enableNativeAutocapture: true])
```

If the project has a data source ID (preferred for new clients), use `start(dataSourceID:)` instead.

### Step 3 — Rename options

| Old name                        | New name                                                                                                      |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `.enableUIKitAutocapture`       | `.enableNativeAutocapture`                                                                                    |
| `ProductAnalyticsOption` (type) | `AnalyticsOption` (`ProductAnalyticsOption` is a deprecated typealias — prefer `AnalyticsOption` in new code) |

### Step 4 — Delete removed options

The following options were **removed entirely** from `AnalyticsOption`. Delete every occurrence from all `start(...)` or `configureProductAnalytics(...)` call sites — the project will not compile if any remain:

- `.captureVendorID`
- `.captureAdvertiserID`
- `.clearEventPropertiesOnNewUser`
- `.messageBatchByteLimit`
- `.messageBatchMessageLimit`
- `.resumePreviousSession`
- `.pruningLookBackWindow`
- `.disableScreenviewForwardToDXA`
- `.disableScreenviewForwardToPA`
- `.interactionHierarchyCaptureLimit`
- `.disableInteractionTextCapture`
- `.disableInteractionAccessibilityLabelCapture`

### Step 5 — Review Session Replay auto-start behavior

A new option `.sessionReplayAutoStart` (defaults to `true`) was added. No action required if you want the default behavior. Set it to `false` only if you need to control Session Replay manually:

```swift
CSQ.start(environmentID: "your-env-id", options: [.sessionReplayAutoStart: false])
// Then start/stop manually:
CSQ.startSessionReplay()
CSQ.stopSessionReplay() // terminal — cannot be restarted in the same SDK lifetime
```

### Migration checklist (1.0–1.6 → 1.11.x)

- [ ] SPM package is updated to 1.11.x
- [ ] Replaced `configureProductAnalytics` + `start()` with unified `CSQ.start(environmentID:options:)` or `CSQ.start(dataSourceID:options:)`
- [ ] Renamed `.enableUIKitAutocapture` → `.enableNativeAutocapture`
- [ ] Renamed `ProductAnalyticsOption` type references → `AnalyticsOption`
- [ ] Deleted all removed options from every call site
- [ ] Build succeeds with no deprecated-API warnings related to the above

## In-App Features (Mandatory Setup)

In-app features (Screenshot Capture, SDK Logs, Log Visualizer, Zoning Analysis) are **essential for Contentsquare users to validate and debug the integration**. They are not optional — without this setup, Contentsquare users cannot access any of these tools.

Two steps are required:

1. Add the `cs-$(PRODUCT_BUNDLE_IDENTIFIER)` URL scheme to `Info.plist`.
2. Call `CSQ.handle(url: url)` in the appropriate deeplink handler (`AppDelegate`, `SceneDelegate`, or `.onOpenURL` in SwiftUI).

Always include this setup when integrating the SDK. Refer to [references/ios-in-app-features.md](references/ios-in-app-features.md) for the complete implementation guide.

## Important Constraints

- **Ask for IDs in this order**: Before integrating, ask the user **(1)** for a Contentsquare **data source ID** -- preferred for new clients. **(2)** If they don't have one, ask for an **environment ID**. **(3)** Only if they have neither (or explicitly want DXA-only), fall back to `CSQ.start()`. Do not invent an ID and do not silently default to DXA without asking.
- **Scan for WebViews**: During integration, search the codebase for any existing `WKWebView` usage. WebViews are not automatically tracked -- every instance must be registered with `CSQ.registerWebView(_:)`. Do not skip this step.
- **In-app features are mandatory**: Always configure the URL scheme (`cs-$(PRODUCT_BUNDLE_IDENTIFIER)`) and `CSQ.handle(url:)` deeplink handler. Without this, Contentsquare users cannot use Screenshot Capture, SDK Logs, Log Visualizer, or Zoning Analysis. See [references/ios-in-app-features.md](references/ios-in-app-features.md).
- **Platform support**: iOS only. Check [compatibility docs](https://docs.contentsquare.com/en/ios/compatibility/).
- **Property types**: Only `String`, `Bool`, and numeric types are accepted as `PropertyValue`.
- **DynamicVar limits**: String variant: key max 512 chars, value max 255 chars. Int variant: key max 50 chars, value is `UInt32`.
- **userIdentifier**: Max 255 characters for `identify()`, max 100 characters for `sendUserIdentifier()`.
- **Privacy**: Never auto-opt-in. Always implement a consent flow.
- **PII**: Never pass emails, passwords, or real names in screen names, event names, or properties.
- **Environment IDs**: Never hardcode -- use configuration or environment variables.

## Integration Checklist

Before considering an integration complete, verify:

- [ ] Dependency added (SPM or CocoaPods)
- [ ] `CSQ.start(dataSourceID:)`, `CSQ.start(environmentID:)`, or `CSQ.start()` called as the first SDK call in AppDelegate or App.init
- [ ] `CSQ.optIn()` added with TODO comment for customer consent flow
- [ ] Screen tracking is set up for all main screens
- [ ] Session Replay masking configured for sensitive content
- [ ] All `WKWebView` instances registered with `CSQ.registerWebView(_:)`
- [ ] Crash reporter coordination via `CSQ.onCrashReporterStart { }`
- [ ] No PII in screen names, event names, or properties
- [ ] Transaction tracking uses the `Currency` enum
- [ ] IDs (dataSourceID, environmentID) are not hardcoded
- [ ] In-app features configured: `cs-$(PRODUCT_BUNDLE_IDENTIFIER)` URL scheme added to `Info.plist` and `CSQ.handle(url:)` called in the deeplink handler

## References

- For full method signatures and parameter details: [references/api-reference.md](references/api-reference.md)
- For Session Replay deep dive (masking, known limitations): [references/session-replay.md](references/session-replay.md)
- **For in-app features setup (mandatory)**: [references/ios-in-app-features.md](references/ios-in-app-features.md)
- [Official iOS in-app features documentation](https://docs.contentsquare.com/en/csq-sdk-ios/experience-analytics/in-app-features/)
- [Official iOS documentation](https://docs.contentsquare.com/ios/)
- [iOS compatibility](https://docs.contentsquare.com/en/ios/compatibility/)

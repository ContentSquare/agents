# Contentsquare React Native SDK -- CSQ API Reference

Entry point: `import { CSQ } from '@contentsquare/react-native-bridge';`

All methods are accessed via the `CSQ` singleton.

---

## Lifecycle

### start

```typescript
CSQ.start(config?: CSQConfig): void
```

Starts the SDK. Must be called before any other CSQ method. Call as early as possible in the app lifecycle (typically in `App` component's `useEffect` or before app initialization).

**Parameters:**

| Parameter | Type         | Default             | Description            |
| --------- | ------------ | ------------------- | ---------------------- |
| `config`  | `CSQConfig?` | `StartConfig.dxa()` | SDK mode configuration |

**StartConfig variants:**

```typescript
// DXA only
CSQ.start(StartConfig.dxa());

// Product Analytics with environment ID
CSQ.start(
  StartConfig.withEnvironmentId("your-env-id", {
    enableRNAutocapture: true,
    sessionReplayAutoStart: true,
  }),
);

// CSQ with data source ID
CSQ.start(
  StartConfig.withDataSourceId("your-datasource-id", {
    sessionReplayAutoStart: true,
  }),
);
```

### stop

```typescript
CSQ.stop(): void
```

Shuts down the SDK. No data collection until `start(config)` is called again.

### pauseTracking

```typescript
CSQ.pauseTracking(): void
```

Temporarily pauses data collection. Use for sensitive screens where you don't want any tracking.

**Note**: Prefer using `CSQMask` component for masking sensitive content instead of pausing tracking entirely.

### resumeTracking

```typescript
CSQ.resumeTracking(): void
```

Resumes tracking after `pauseTracking()`.

---

## Privacy

### optIn

```typescript
CSQ.optIn(): void
```

Opt the device into tracking. Starts data collection immediately.

**Important**: Must only be called after the user explicitly consents to tracking. This is a legal requirement (GDPR, CCPA, etc.).

### optOut

```typescript
CSQ.optOut(): void
```

Opt out permanently. Stops all tracking until `optIn()` is called or the app is reinstalled. Clears all collected data.

---

## Identity

### identify (Product Analytics only)

```typescript
CSQ.identify(userIdentifier: string): void
```

Set user identity for Product Analytics. Calling with a different ID triggers a new session.

**Parameters:**

- `userIdentifier: string` - User identifier (max 100 characters). Plain text, will be hashed by the SDK.

**Context:** Only for Product Analytics (`StartConfig.withEnvironmentId` or `StartConfig.withDataSourceId` with PA enabled)

**Example:**

```typescript
CSQ.identify("user_12345");
```

### resetIdentity (Product Analytics only)

```typescript
CSQ.resetIdentity(): void
```

Clear the current user identity. Triggers a new session.

**Context:** Only for Product Analytics

### sendUserIdentifier (DXA only)

```typescript
CSQ.sendUserIdentifier(userIdentifier: string): void
```

Send a user identifier for DXA. The identifier is hashed immediately by the SDK.

**Parameters:**

- `userIdentifier: string` - User identifier (max 100 characters)

**Context:** DXA only (`StartConfig.dxa()`)

---

## Screen Tracking

### trackScreenview

```typescript
CSQ.trackScreenview(screenName: string, customVars?: CustomVar[]): void
```

Track a screen view with optional custom variables.

**Parameters:**

- `screenName: string` - Name of the screen
- `customVars?: CustomVar[]` - Optional array of custom variables

**CustomVar type:**

```typescript
type CustomVar = {
  index: number; // 1-20
  key: string; // max 50 chars
  value: string; // max 255 chars
};
```

**Example:**

```typescript
CSQ.trackScreenview("ProductDetails");

CSQ.trackScreenview("ProductDetails", [
  { index: 1, key: "product_id", value: "12345" },
  { index: 2, key: "category", value: "electronics" },
  { index: 3, key: "price_range", value: "50-100" },
]);
```

---

## Transactions

### trackTransaction

```typescript
CSQ.trackTransaction(transaction: Transaction): void
```

Track an e-commerce transaction.

**Parameters:**

- `transaction: Transaction` - Transaction object

**Transaction type:**

```typescript
type Transaction = {
  price: number;
  currency: Currency;
  id?: string;
};
```

**Currency enum:**

ISO 4217 currency codes (e.g., `Currency.USD`, `Currency.EUR`, `Currency.GBP`, `Currency.JPY`, etc.)

**Example:**

```typescript
import { CSQ, Currency } from "@contentsquare/react-native-bridge";

CSQ.trackTransaction({
  price: 29.99,
  currency: Currency.USD,
  id: "order_123",
});

// With string currency (also supported)
CSQ.trackTransaction({
  price: 49.99,
  currency: "EUR",
  id: "order_456",
});
```

---

## Custom Events and Properties

### trackEvent

```typescript
CSQ.trackEvent(eventName: string, properties?: Record<string, PropertyValue>): void
```

Track a named event with optional properties.

**Parameters:**

- `eventName: string` - Name of the event
- `properties?: Record<string, PropertyValue>` - Optional event properties

**PropertyValue:** `string | number | boolean | bigint`

**Example:**

```typescript
CSQ.trackEvent("add_to_cart");

CSQ.trackEvent("purchase_completed", {
  product_id: "12345",
  amount: 99.99,
  payment_method: "credit_card",
  is_first_purchase: true,
});
```

**Important**: Arrays and objects are not supported as property values. They will be silently ignored or cause unexpected behavior.

### addDynamicVar (DXA only)

```typescript
CSQ.addDynamicVar(key: string, value: string | number, onError?: (error: Error) => void): void
```

Add a session-level dynamic variable.

**Context:** DXA only (`StartConfig.dxa()`)

**Parameters:**

- `key: string` - Variable key (max 50 characters)
- `value: string | number` - Variable value
  - String: max 255 characters
  - Number: must be unsigned integer (0 to 2^32-1)
- `onError?: (error: Error) => void` - Optional error callback

**Example:**

```typescript
// String value
CSQ.addDynamicVar("user_segment", "high_value");

// Number value
CSQ.addDynamicVar("ab_test_variant", 2);

// With error callback
CSQ.addDynamicVar("page_number", -1, error => {
  console.error("Invalid dynamic var:", error.message);
  // Error: value must be unsigned integer
});
```

**Important:** Number values must be unsigned integers (>= 0). Negative numbers or floats will trigger an error.

### addUserProperties (Product Analytics only)

```typescript
CSQ.addUserProperties(properties: Record<string, PropertyValue>): void
```

Set user-level properties that persist across sessions.

**Context:** Product Analytics only

**Example:**

```typescript
CSQ.addUserProperties({
  subscription_tier: "premium",
  account_age_days: 30,
  is_verified: true,
});
```

### addEventProperties (Product Analytics only)

```typescript
CSQ.addEventProperties(properties: Record<string, PropertyValue>): void
```

Set properties that will be automatically added to all future tracked events.

**Context:** Product Analytics only

**Example:**

```typescript
CSQ.addEventProperties({
  app_version: "2.1.0",
  environment: "production",
});
```

### removeEventProperty (Product Analytics only)

```typescript
CSQ.removeEventProperty(name: string): void
```

Remove a single event property.

**Example:**

```typescript
CSQ.removeEventProperty("environment");
```

### clearEventProperties (Product Analytics only)

```typescript
CSQ.clearEventProperties(): void
```

Remove all event properties.

---

## Session Replay

### startSessionReplay

```typescript
CSQ.startSessionReplay(): void
```

Manually start session replay recording.

**Example:**

```typescript
// Start recording for this session
CSQ.startSessionReplay();
```

**Note**: This is a **one-shot** operation. Once called, session replay will start and continue until `stopSessionReplay()` is called or the session ends. It's not a toggle.

**Alternative:** Set `sessionReplayAutoStart: true` in `AnalyticsOptions` to automatically start session replay when the SDK initializes:

```typescript
CSQ.start(
  StartConfig.withEnvironmentId("your-env-id", {
    sessionReplayAutoStart: true, // Automatically start session replay
  }),
);
```

### stopSessionReplay

```typescript
CSQ.stopSessionReplay(): void
```

Stop session replay recording.

**Important**: This is a **terminal** operation. Once stopped, session replay cannot be restarted in the same SDK lifetime. The SDK must be stopped and restarted to enable session replay again.

### setDefaultMasking

```typescript
CSQ.setDefaultMasking(masked: boolean): void
```

Set global default masking for all content in session replay.

**Important**: `setDefaultMasking` must be called **after** `CSQ.start(...)`. Calling it before `start()` has no effect.

**Parameters:**

- `masked: boolean` - `true` to mask everything by default, `false` to unmask everything

**Example:**

```typescript
// Mask everything by default
CSQ.setDefaultMasking(true);

// Unmask everything (use with caution - privacy risk)
CSQ.setDefaultMasking(false);
```

**Important**: This is an all-or-nothing setting. For fine-grained control, use `CSQMask` component instead.

---

## Session Metadata

### onMetadataChange

```typescript
CSQ.onMetadataChange(callback: (metadata: CSQMetadata) => void): () => void
```

Listen for changes to session metadata (session ID, replay URL, user ID, etc.). Returns an **unsubscribe function** -- call it to remove the listener.

**Parameters:**

- `callback: (metadata: CSQMetadata) => void` - Callback function that receives metadata updates

**Returns:** `() => void` - Unsubscribe function to remove the listener.

**CSQMetadata type:**

```typescript
interface CSQMetadata {
  userID: string | null;
  sessionID: string | null;
  identity: string | null;
  environmentID: string | null;
  projectID: string | null;
  sessionReplayUrl: string | null;
}
```

**Example:**

```typescript
import { useEffect } from "react";

useEffect(() => {
  const unsubscribe = CSQ.onMetadataChange(metadata => {
    console.log("Session Replay URL:", metadata.sessionReplayUrl);
    console.log("Session ID:", metadata.sessionID);
    console.log("User ID:", metadata.userID);

    // Send replay URL to customer support, analytics, etc.
    if (metadata.sessionReplayUrl) {
      sendToSupportSystem(metadata.sessionReplayUrl);
    }
  });

  return unsubscribe; // Cleanup on unmount to prevent memory leaks
}, []);
```

---

## Error Tracking

### setUrlMaskingPatterns

```typescript
CSQ.setUrlMaskingPatterns(patterns: string[]): void
```

Mask sensitive URL paths in error tracking. Email addresses are automatically masked.

**Parameters:**

- `patterns: string[]` - Array of URL path patterns to mask

**Example:**

```typescript
CSQ.setUrlMaskingPatterns(["/api/user/*/private", "/admin/*", "/secure/*"]);
```

---

## Debug and Logging

### setLogLevel

```typescript
CSQ.setLogLevel(level: LogLevel): void
```

Set the SDK log level.

**LogLevel enum:**

```typescript
import { CSQ, LogLevel } from "@contentsquare/react-native-bridge";

CSQ.setLogLevel(LogLevel.VERBOSE);
CSQ.setLogLevel(LogLevel.INFO);
CSQ.setLogLevel(LogLevel.WARN);
CSQ.setLogLevel(LogLevel.ERROR);
CSQ.setLogLevel(LogLevel.NONE);
```

### setLogChannel

```typescript
CSQ.setLogChannel(channel: LogChannel): void
```

Set the log output channel.

**LogChannel enum:**

```typescript
import { CSQ, LogChannel } from "@contentsquare/react-native-bridge";

CSQ.setLogChannel(LogChannel.CONSOLE);
CSQ.setLogChannel(LogChannel.NATIVE);
```

### logToConsole

```typescript
CSQ.logToConsole(): void
```

Enable console logging (shorthand for `setLogChannel(LogChannel.CONSOLE)`).

---

## StartConfig Factories

### StartConfig.dxa

```typescript
StartConfig.dxa(): CSQConfig
```

Create a config for DXA-only mode (no Product Analytics).

**Example:**

```typescript
import { CSQ, StartConfig } from "@contentsquare/react-native-bridge";

CSQ.start(StartConfig.dxa());
```

### StartConfig.withEnvironmentId

```typescript
StartConfig.withEnvironmentId(id: string, options?: AnalyticsOptions): CSQConfig
```

Create a config for Product Analytics with Heap environment ID.

**Parameters:**

- `id: string` - Heap environment ID
- `options?: AnalyticsOptions` - Optional analytics configuration

**Example:**

```typescript
CSQ.start(
  StartConfig.withEnvironmentId("heap-env-123", {
    enableRNAutocapture: true,
    sessionReplayAutoStart: true,
  }),
);
```

### StartConfig.withDataSourceId

```typescript
StartConfig.withDataSourceId(id: string, options?: AnalyticsOptions): CSQConfig
```

Create a config for CSQ with data source ID.

**Parameters:**

- `id: string` - Data source ID
- `options?: AnalyticsOptions` - Optional analytics configuration

**Example:**

```typescript
CSQ.start(
  StartConfig.withDataSourceId("datasource-123", {
    uploadInterval: 10000,
  }),
);
```

---

## AnalyticsOptions

Configuration options for analytics behavior.

```typescript
type AnalyticsOptions = {
  enableRNAutocapture?: boolean; // Enable React Native autocapture (default: false)
  sessionReplayAutoStart?: boolean; // Automatically start session replay on SDK init (default: false)
  uploadInterval?: number; // Upload interval in milliseconds (default: 15000)
  baseUrl?: string; // Custom API endpoint
  disablePageviewAutocapture?: boolean; // Disable automatic screen tracking
  disableInteractionAutocapture?: boolean; // Disable automatic touch tracking (iOS only)
  disableInteractionTextCapture?: boolean; // Disable text capture in interactions (iOS only)
  disableInteractionAccessibilityLabelCapture?: boolean; // Disable accessibility label capture (iOS only)
  disablePageviewTitleAutocapture?: boolean; // Disable page title capture (iOS only)
  enablePushNotificationAutocapture?: boolean; // Capture push notification events
  enablePushNotificationTitleAutocapture?: boolean; // Capture push notification title
  enablePushNotificationBodyAutocapture?: boolean; // Capture push notification body
};
```

---

## Components

### CSQMask

Component for masking sensitive content in session replay.

```typescript
import { CSQMask } from '@contentsquare/react-native-bridge';

<CSQMask
  isSessionReplayMasked={true}
  ignoreTextOnly={false}
  allowInnerHierarchy={false}
  allowProps={false}
  allowText={false}
  allowInteraction={false}
  allowAccessibilityLabel={false}
>
  <YourContent />
</CSQMask>;
```

**Props:**

- `isSessionReplayMasked?: boolean` - Whether to mask visual content in Session Replay (default: true) - **Session Replay**
- `ignoreTextOnly?: boolean` - Ignore text only (conflicts with allow\* props) - **Product Analytics**
- `allowInnerHierarchy?: boolean` - Allow inner view hierarchy in PA events - **Product Analytics**
- `allowProps?: boolean` - Allow view properties in PA events - **Product Analytics**
- `allowText?: boolean` - Allow text content in PA events - **Product Analytics**
- `allowInteraction?: boolean` - Allow interaction tracking in PA events - **Product Analytics**
- `allowAccessibilityLabel?: boolean` - Allow accessibility labels in PA events - **Product Analytics**

**Important:**

- Only `isSessionReplayMasked` affects Session Replay visual masking
- The `allow*` props control Product Analytics event data capture
- When `ignoreTextOnly` is `true`, all `allow*` props are ignored and should not be set

### CSQWebView

Wrapper for WebView components to enable session stitching between native and web.

```typescript
import { CSQWebView } from '@contentsquare/react-native-bridge';
import { WebView } from 'react-native-webview';

<CSQWebView>
  <WebView source={{ uri: 'https://example.com' }} />
</CSQWebView>;
```

**Requirements:**

- The web page must include the [Contentsquare Web Tracking Tag in WebView mode](https://docs.contentsquare.com/en/webview-tracking-tag/)
- Only wraps `react-native-webview` WebView component

### withCSQMask

Higher-order component for masking content.

```typescript
import { withCSQMask } from '@contentsquare/react-native-bridge';

function SensitiveComponent(props) {
  return (
    <View>
      <Text>{props.sensitiveData}</Text>
    </View>
  );
}

const MaskedSensitiveComponent = withCSQMask(SensitiveComponent, {
  isSessionReplayMasked: true, // SR visual masking
  allowText: false, // Optional: PA event data masking
});

// Usage
<MaskedSensitiveComponent sensitiveData="Secret" />;
```

**CSQMaskProps:** Same props as `CSQMask` component (isSessionReplayMasked, ignoreTextOnly, allow\*, etc.)

### CSWebView (deprecated)

Legacy WebView wrapper. Use `CSQWebView` instead.

```typescript
import { CSWebView } from '@contentsquare/react-native-bridge';

<CSWebView>
  <WebView source={{ uri: 'https://example.com' }} />
</CSWebView>;
```

---

## Type Definitions

### CSQConfig

Union type for SDK configuration:

```typescript
type CSQConfig =
  | { type: ProductType.DXA }
  | { type: ProductType.PA; id: string; options?: AnalyticsOptions }
  | { type: ProductType.PA_CSQ; id: string; options?: AnalyticsOptions };
```

### PropertyValue

Valid property value types:

```typescript
type PropertyValue = string | number | boolean | bigint;
```

---

## Best Practices

- **Start early**: Call `CSQ.start(config)` with appropriate configuration in your root `App` component's `useEffect` or before app initialization
- **Consent first**: Never call `optIn()` without user consent
- **Track screens**: Session replay requires screen tracking. Use `trackScreenview()` or React Navigation integration
- **Wrap WebViews**: Every WebView must be wrapped with `CSQWebView` for proper tracking
- **Mask PII**: Use `CSQMask` to mask sensitive content (passwords, credit cards, personal info)
- **Error handling**: Use try-catch around SDK calls in production
- **Upload interval**: Configure `uploadInterval` in `AnalyticsOptions` (default: 15000ms)
- **Test thoroughly**: Test session replay and screen tracking in development before release

---

## Links

- [React Native SDK](https://docs.contentsquare.com/react-native/)
- [Android SDK](https://docs.contentsquare.com/android/)
- [iOS SDK](https://docs.contentsquare.com/ios/)
- [WebView Tracking Tag](https://docs.contentsquare.com/en/webview-tracking-tag/)

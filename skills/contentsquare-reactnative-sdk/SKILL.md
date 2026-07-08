---
name: contentsquare-react-native-sdk
description: Integrate or upgrade the Contentsquare React Native SDK -- Session Replay, screen tracking, transactions, analytics, masking, privacy opt-in/out. Use when working with Contentsquare, CSQ, StartConfig, AnalyticsOptions, CSQMask, CSQWebView, @contentsquare/react-native-bridge, or migrating from the legacy `Contentsquare` API to `CSQ`.
---

# Contentsquare React Native SDK Integration

> This skill helps AI agents integrate or upgrade the Contentsquare React Native SDK in client applications.

## Install

```json
{
  "dependencies": {
    "@contentsquare/react-native-bridge": "^6.0.1"
  }
}
```

Then run `npm install` or `yarn install`.

### iOS Setup

```bash
cd ios && pod install && cd ..
```

### Android Setup

No additional setup required after `npm install`.

## Quick Start

```typescript
import { CSQ, StartConfig } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function App() {
  useEffect(() => {
    // Start the SDK with Product Analytics
    CSQ.start(StartConfig.withEnvironmentId('your-env-id', {
      enableRNAutocapture: true,
      sessionReplayAutoStart: true  // Optional: auto-start session replay
    }));

    // TODO: customer to manage consent — call only after user accepts
    CSQ.optIn();
  }, []);

  return <YourApp />;
}
```

> **Critical**: Never call `optIn()` without a user consent flow. This is a legal requirement.

It is very important that screens should be tracked, otherwise Session Replay will not work. Track screens manually with `trackScreenview()` or use React Navigation integration (see [Screen Tracking](#screen-tracking-integration)).

Before wrapping the MVP, make sure you are handling WebViews if they are present in the app. WebViews are not automatically tracked, and every WebView must be wrapped. Check the [WebView section](#webview-tracking) below for details.

## API Surface

Always use `CSQ` from `@contentsquare/react-native-bridge`. The `Contentsquare` default export is deprecated.

### Lifecycle

| Method             | Purpose                                                                           |
| ------------------ | --------------------------------------------------------------------------------- |
| `start(config?)`   | Start the SDK. Must be called before any other API.                               |
| `stop()`           | Shut down the SDK completely.                                                     |
| `pauseTracking()`  | Pause data collection (for sensitive screens). Avoid unless explicitly requested. |
| `resumeTracking()` | Resume after `pauseTracking()`.                                                   |

### StartConfig Variants

| Factory                                       | Use Case                                    | Onboarding priority                                                               |
| --------------------------------------------- | ------------------------------------------- | --------------------------------------------------------------------------------- |
| `StartConfig.withDataSourceId(id, options?)`  | CSQ with data source ID                     | **1st choice for new clients** -- ask for this first                              |
| `StartConfig.withEnvironmentId(id, options?)` | Product Analytics with environment ID       | 2nd choice if no data source ID is available                                      |
| `StartConfig.dxa()`                           | Digital Experience Analytics only (default) | Fallback only -- when neither ID is available or DXA-only is explicitly requested |

`withDataSourceId` and `withEnvironmentId` accept the same `AnalyticsOptions` object (see the **AnalyticsOptions** section below). `StartConfig.dxa()` takes no arguments -- it has no `AnalyticsOptions` parameter.

**Recommended onboarding flow:**

1. Ask the user: _"Do you have a Contentsquare data source ID?"_ If yes, use `StartConfig.withDataSourceId(id, ...)`.
2. If not, ask: _"Do you have an environment ID?"_ If yes, use `StartConfig.withEnvironmentId(id, ...)`.
3. Only if neither is available (or the user explicitly wants DXA-only), fall back to `StartConfig.dxa()`.

Do not invent an ID. Do not silently default to DXA without asking.

### Privacy

| Method     | Purpose                                                      |
| ---------- | ------------------------------------------------------------ |
| `optIn()`  | Opt the device into tracking. Starts immediately.            |
| `optOut()` | Opt out permanently. Stops until `optIn()` or app reinstall. |

### Identity

| Method                               | Context           | Purpose                                               |
| ------------------------------------ | ----------------- | ----------------------------------------------------- |
| `identify(userIdentifier)`           | Product Analytics | Set user identity. Different ID triggers new session. |
| `resetIdentity()`                    | Product Analytics | Clear identity. Triggers new session.                 |
| `sendUserIdentifier(userIdentifier)` | DXA               | Send hashed user ID. Max 100 chars.                   |

### Screen Tracking

| Method                                     | Purpose                                             |
| ------------------------------------------ | --------------------------------------------------- |
| `trackScreenview(screenName, customVars?)` | Track a screen view with optional custom variables. |

`CustomVar` structure: `{ index: number, key: string, value: string }` -- index (1-20), key (max 50 chars), value (max 255 chars).

See [Screen Tracking Integration](#screen-tracking-integration) for React Navigation examples.

### Transactions

```typescript
import { CSQ, Currency } from "@contentsquare/react-native-bridge";

CSQ.trackTransaction({
  price: 29.99,
  currency: Currency.USD,
  id: "order_123",
});
```

`Currency` is an ISO 4217 enum (e.g., `Currency.USD`, `Currency.EUR`).

### Custom Events and Properties

| Method                                | Purpose                                        |
| ------------------------------------- | ---------------------------------------------- |
| `trackEvent(eventName, properties?)`  | Track a named event with optional properties.  |
| `addDynamicVar(key, value, onError?)` | Add session-level dynamic variable (DXA only). |
| `addUserProperties(properties)`       | Set user-level properties (PA only).           |
| `addEventProperties(properties)`      | Set properties on all future events (PA only). |
| `removeEventProperty(name)`           | Remove one event property.                     |
| `clearEventProperties()`              | Remove all event properties.                   |

Property values must be `string`, `number`, `boolean`, or `bigint`. Other types are silently ignored.

Dynamic variables (DXA only):

- `key`: string (max 50 chars)
- `value`: string (max 255 chars) or unsigned integer (0 to 2^32-1)
- `onError`: optional callback for validation errors

### Session Replay

| Method                 | Purpose                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `startSessionReplay()` | Start Session Replay on-demand. Use when `sessionReplayAutoStart: false` was passed to `start()`. **One-shot** -- not a restart API. |
| `stopSessionReplay()`  | Stop Session Replay on-demand without stopping the SDK. **Terminal** -- SR cannot be re-started afterwards in the same SDK lifetime. |

**On-demand Session Replay** -- disable auto-start at SDK launch and control it manually:

```typescript
CSQ.start(StartConfig.dxa());
// Note: sessionReplayAutoStart defaults to false, no need to pass options

// later, when you want SR to start (e.g., entering a checkout flow):
CSQ.startSessionReplay();

// and to stop it (final -- no restart afterwards):
CSQ.stopSessionReplay();
```

> `startSessionReplay` / `stopSessionReplay` are **start + stop only**, not pause/resume. After `stopSessionReplay()` SR stays off until the next SDK lifetime.

### Session Metadata (get replay link)

Access session information including the replay URL. `onMetadataChange` returns an **unsubscribe function** -- call it to remove the listener (e.g., on component unmount):

```typescript
import { useEffect } from "react";

useEffect(() => {
  const unsubscribe = CSQ.onMetadataChange(metadata => {
    console.log("Session Replay URL:", metadata.sessionReplayUrl);
    console.log("Session ID:", metadata.sessionID);
    console.log("User ID:", metadata.userID);
  });

  return unsubscribe; // Cleanup on unmount
}, []);
```

`Metadata` fields: `projectID`, `environmentID`, `userID`, `identity`, `sessionID`, `sessionReplayUrl` (string or null).

### Debug

| API                         | Purpose                                 |
| --------------------------- | --------------------------------------- |
| `setLogLevel(LogLevel)`     | Set log level (`info`, `verbose`, etc.) |
| `setLogChannel(LogChannel)` | Set log output channel                  |
| `logToConsole()`            | Enable console logging                  |

### AnalyticsOptions (shared by `withDataSourceId` and `withEnvironmentId`)

`StartConfig.dxa()` does **not** accept `AnalyticsOptions`. The options below apply only to `withDataSourceId` and `withEnvironmentId`.

All fields are nullable (`undefined` = native default behavior).

| Field                                         | Type       | Purpose                                              |
| --------------------------------------------- | ---------- | ---------------------------------------------------- |
| `enableRNAutocapture`                         | `boolean?` | Enable React Native interaction autocapture (PA)     |
| `sessionReplayAutoStart`                      | `boolean?` | If `true`, SR starts at SDK launch. Default: `false` |
| `uploadInterval`                              | `number?`  | Upload interval in milliseconds (default: 15000)     |
| `baseUrl`                                     | `string?`  | Custom API endpoint (e.g., for EU data residency)    |
| `disablePageviewAutocapture`                  | `boolean?` | Disable automatic screen tracking                    |
| `disableInteractionAutocapture`               | `boolean?` | Disable automatic touch tracking (iOS only)          |
| `disableInteractionTextCapture`               | `boolean?` | Disable text capture in interactions (iOS only)      |
| `disableInteractionAccessibilityLabelCapture` | `boolean?` | Disable accessibility label capture (iOS only)       |
| `disablePageviewTitleAutocapture`             | `boolean?` | Disable page title capture (iOS only)                |
| `enablePushNotificationAutocapture`           | `boolean?` | Capture push notification events                     |
| `enablePushNotificationTitleAutocapture`      | `boolean?` | Capture push notification title                      |
| `enablePushNotificationBodyAutocapture`       | `boolean?` | Capture push notification body                       |

## Session Replay Masking

### Global masking (setDefaultMasking)

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// Mask everything by default
CSQ.setDefaultMasking(true);

// Unmask everything (use with caution - privacy risk)
CSQ.setDefaultMasking(false);
```

**Important**:

- `setDefaultMasking` takes a **boolean**, not a configuration object. It's all-or-nothing global masking.
- `setDefaultMasking` must be called **after** `CSQ.start(...)`. Calling it before `start()` has no effect.

### Scoped masking (per component)

```typescript
import { CSQMask } from '@contentsquare/react-native-bridge';

<CSQMask isSessionReplayMasked={true}>
  <Text>Sensitive content</Text>
</CSQMask>
```

**Note**: `isSessionReplayMasked` controls Session Replay visual masking. Use `allow*` props to also control Product Analytics event data.

### Fine-grained control with allow\* props (Product Analytics)

```typescript
<CSQMask
  isSessionReplayMasked={true}  // Masks visual content in Session Replay
  allowText={false}             // Prevents text in PA events
  allowInteraction={false}      // Prevents interaction tracking in PA events
>
  <TextInput placeholder="Password" />
</CSQMask>
```

**Important**: Only `isSessionReplayMasked` affects Session Replay visual masking. The `allow*` props control Product Analytics event data capture.

### CSQMask props

| Prop                      | Type       | Default | Purpose                                   | Feature               |
| ------------------------- | ---------- | ------- | ----------------------------------------- | --------------------- |
| `isSessionReplayMasked`   | `boolean?` | `true`  | Whether to mask visual content            | **Session Replay**    |
| `ignoreTextOnly`          | `boolean?` | `false` | Ignore text only (conflicts with allow\*) | **Product Analytics** |
| `allowInnerHierarchy`     | `boolean?` | `false` | Allow inner view hierarchy in events      | **Product Analytics** |
| `allowProps`              | `boolean?` | `false` | Allow view properties in events           | **Product Analytics** |
| `allowText`               | `boolean?` | `false` | Allow text content in events              | **Product Analytics** |
| `allowInteraction`        | `boolean?` | `false` | Allow interaction tracking in events      | **Product Analytics** |
| `allowAccessibilityLabel` | `boolean?` | `false` | Allow accessibility labels in events      | **Product Analytics** |

> **Important**: Only `isSessionReplayMasked` affects Session Replay visual masking. The `allow*` props control Product Analytics event data capture. When `ignoreTextOnly` is `true`, all `allow*` props are ignored.

### Higher-Order Component masking

```typescript
import { withCSQMask } from "@contentsquare/react-native-bridge";

const MaskedComponent = withCSQMask(SensitiveComponent, {
  isSessionReplayMasked: true, // SR visual masking
  allowText: false, // Optional: PA event data masking
});
```

## Screen Tracking Integration

### Manual tracking

```typescript
import { CSQ } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function ProductScreen() {
  useEffect(() => {
    CSQ.trackScreenview('ProductDetails', [
      { index: 1, key: 'product_id', value: '12345' }
    ]);
  }, []);

  return <ProductView />;
}
```

### React Navigation integration

Track screen views automatically using React Navigation's navigation state listener:

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  return (
    <NavigationContainer
      ref={navigationRef}
      onReady={() => {
        routeNameRef.current = navigationRef.current?.getCurrentRoute()?.name;
      }}
      onStateChange={() => {
        const previousRouteName = routeNameRef.current;
        const currentRouteName = navigationRef.current?.getCurrentRoute()?.name;

        if (previousRouteName !== currentRouteName) {
          CSQ.trackScreenview(currentRouteName);
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      <YourNavigator />
    </NavigationContainer>
  );
}
```

See [references/screen-tracking.md](references/screen-tracking.md) for more examples.

## WebView Tracking

WebViews are **not automatically tracked**. Wrap them with `CSQWebView` to enable session stitching between native and web content. The web pages must include the [Contentsquare Web Tracking Tag in WebView mode](https://docs.contentsquare.com/en/webview-tracking-tag/).

```typescript
import { CSQWebView } from '@contentsquare/react-native-bridge';
import { WebView } from 'react-native-webview';

<CSQWebView>
  <WebView source={{ uri: 'https://example.com' }} />
</CSQWebView>
```

Legacy wrapper (deprecated, use `CSQWebView`):

```typescript
import { CSWebView } from '@contentsquare/react-native-bridge';

<CSWebView>
  <WebView source={{ uri: 'https://example.com' }} />
</CSWebView>
```

## Important Rules

- **Ask for the environment ID first**: Before integrating, ask the user for their Contentsquare environment ID (or data source ID). Do not assume DXA-only mode, do not invent an ID, and do not skip this step.
- **Scan for WebViews**: During integration, search the codebase for any existing WebView usage (`react-native-webview`, `WebView` component). WebViews are not automatically tracked -- every WebView must be wrapped with `CSQWebView`.
- Call `start(config)` with appropriate configuration before any other CSQ method
- Always implement a consent flow before calling `optIn()` -- never auto-opt-in
- `optOut()` is permanent until `optIn()` is called or the app is reinstalled
- `identify()` is for Product Analytics only; `sendUserIdentifier()` is for DXA only
- Property values must be `string`, `number`, `boolean`, or `bigint` -- other types (arrays, objects) are silently ignored or may cause unexpected behavior
- `CustomVar` constraints: key max 50 chars; string value max 255 chars; number: 0 to 2^32-1
- `userIdentifier`: max 100 characters
- **React Native >= 0.71.0** required (bridge v6.2.0+ supports all versions from 0.71.0 onwards)
- Android and iOS only (no web, Expo Go, or desktop support)
- Never expose PII (emails, passwords, real names) in screen names, event names, or property values
- Never hardcode environment IDs -- use config or environment variables
- Check [Compatibility Guide](references/compatibility.md) for Expo, hybrid apps, and known limitations

## Autocapture (Product Analytics)

Autocapture enables automatic tracking of user interactions and screen navigation without manual instrumentation.

### Prerequisites

**Install the Babel plugin** in your `babel.config.js`:

```javascript
module.exports = {
  presets: ["module:@react-native/babel-preset"],
  plugins: ["@contentsquare/react-native-bridge/babel"],
};
```

The Babel plugin requires `@babel/plugin-transform-react-display-name` to include component names in events. This is typically provided by React Native's default preset.

**Monorepo setup**: If your project uses a monorepo structure (Yarn Workspaces, pnpm, Lerna, Nx, Turborepo, etc.), make sure to add the plugin to **all relevant `babel.config.js` files** in your project, including those in any packages that contain React Native code.

### Enable Autocapture

```typescript
import { CSQ, StartConfig } from "@contentsquare/react-native-bridge";

CSQ.start(
  StartConfig.withEnvironmentId("your-env-id", {
    enableRNAutocapture: true, // Enable autocapture
  }),
);
```

### Navigation Library Compatibility

The React Native Bridge's autocapture feature is compatible with the following navigation libraries:

- **React Navigation**: 5.0 and later
- **React Native Navigation**: 7.0 and later

### What Gets Autocaptured

Autocapture automatically tracks:

- Touch events (tap, long press, swipe)
- Change events (text input, switches, pickers, sliders)
- Component interactions with display names
- Screen navigation (when enabled)

### Combined with Experience Analytics

When using both Experience Analytics and Product Analytics, pass PA options via `StartConfig.withDataSourceId`:

```typescript
CSQ.start(
  StartConfig.withDataSourceId("YOUR_DATA_SOURCE_ID", {
    enableRNAutocapture: true,
    disablePageviewAutocapture: true, // Let Experience Analytics handle screens
  }),
);
```

## Source Maps and Crash Symbolication

For readable JavaScript crash stack traces in production, configure source map upload:

### Quick Setup

1. **Install the Contentsquare CLI**:

   ```bash
   yarn add @contentsquare/react-native-cli --dev
   ```

2. **Create `contentsquare-cli.json`** at project root with API credentials and source map paths

3. **Configure build scripts**:
   - **Android**: Add `apply from: "../../node_modules/@contentsquare/react-native-cli/scripts/contentsquare.gradle"` to `app/build.gradle`
   - **iOS**: Add Contentsquare CLI script to Xcode build phase

4. **Add to `.gitignore`**:
   ```
   contentsquare-cli.json
   contentsquare-sourcemap-info.json
   ```

See [Debugging and Tooling](references/debugging-and-tooling.md) for complete setup instructions and troubleshooting.

## Platform Support

- **Android**: Full support
- **iOS**: Full support (check [iOS compatibility requirements](https://docs.contentsquare.com/en/ios/compatibility/))
- **React Native**: >= 0.71.0 (version 6.2.0 supports all current and future versions from 0.71.0 onwards)
- **Expo**: Requires EAS (Expo Application Services) - see [Compatibility Guide](references/compatibility.md)
- **Not Supported**: Web, Windows, macOS, Expo Go

**Important**: Hybrid applications (React Native components in native apps) are not officially supported. For mixed codebases, use native SDKs for native screens and the CSQ bridge for React Native screens.

See [Compatibility Guide](references/compatibility.md) for detailed version matrices, Expo configuration, and known limitations.

## Reference Documentation

- [API Reference](references/api-reference.md) - Complete API documentation
- [Common Patterns](references/common-patterns.md) - Code examples and recipes
- [Screen Tracking](references/screen-tracking.md) - React Navigation integration patterns
- [Session Replay](references/session-replay.md) - Advanced masking strategies
- [Debugging and Tooling](references/debugging-and-tooling.md) - Autocapture setup, source maps, CLI tools
- [WebView Tracking](references/webview-tracking.md) - WebView integration and session stitching
- [In-App Features](references/in-app-features.md) - Debugging tools, logs, screenshot capture
- [Compatibility](references/compatibility.md) - React Native versions, Expo, known limitations
- [Migration Guide](references/migration.md) - Legacy API migration
- [React Native SDK docs](https://docs.contentsquare.com/react-native/)
- [Android SDK docs](https://docs.contentsquare.com/android/)
- [iOS compatibility](https://docs.contentsquare.com/en/ios/compatibility/)

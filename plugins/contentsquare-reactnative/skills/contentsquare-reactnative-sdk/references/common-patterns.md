# Common Patterns

## Quick Start - Minimal Setup

```typescript
import { CSQ, StartConfig } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function App() {
  useEffect(() => {
    CSQ.start(StartConfig.dxa());
    CSQ.optIn(); // TODO: implement consent flow first
  }, []);

  return <YourApp />;
}
```

---

## Product Analytics with Environment ID

```typescript
import { CSQ, StartConfig } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function App() {
  useEffect(() => {
    CSQ.start(
      StartConfig.withEnvironmentId('your-env-id', {
        enableRNAutocapture: true,
        sessionReplayAutoStart: true,
        uploadInterval: 10000,
      })
    );

    CSQ.optIn(); // TODO: implement consent flow
  }, []);

  return <YourApp />;
}
```

---

## CSQ with Data Source ID

```typescript
import { CSQ, StartConfig } from "@contentsquare/react-native-bridge";

CSQ.start(
  StartConfig.withDataSourceId("your-datasource-id", {
    sessionReplayAutoStart: true,
  }),
);
```

---

## GDPR Consent Flow

```typescript
import { CSQ } from '@contentsquare/react-native-bridge';
import { useState } from 'react';

function ConsentScreen() {
  const [hasConsented, setHasConsented] = useState(false);

  const handleConsent = async (accepted: boolean) => {
    if (accepted) {
      CSQ.optIn();
      setHasConsented(true);
    } else {
      CSQ.optOut();
    }
  };

  return (
    <View>
      <Text>We use analytics to improve your experience</Text>
      <Button title="Accept" onPress={() => handleConsent(true)} />
      <Button title="Decline" onPress={() => handleConsent(false)} />
    </View>
  );
}
```

---

## Track a Purchase / Transaction

```typescript
import { CSQ, Currency } from "@contentsquare/react-native-bridge";

function handlePurchase(amount: number, orderId: string) {
  CSQ.trackTransaction({
    price: amount,
    currency: Currency.USD,
    id: orderId,
  });

  // Also track as event with properties
  CSQ.trackEvent("purchase_completed", {
    order_id: orderId,
    amount: amount,
    payment_method: "credit_card",
  });
}
```

---

## Custom Event with Properties

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// Simple event
CSQ.trackEvent("button_clicked");

// Event with properties
CSQ.trackEvent("product_viewed", {
  product_id: "sku_123",
  product_name: "Wireless Mouse",
  price: 29.99,
  category: "electronics",
  in_stock: true,
});

// Search event
CSQ.trackEvent("search_performed", {
  query: "wireless keyboard",
  results_count: 42,
  category_filter: "electronics",
});
```

---

## User Identity Management

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// Product Analytics - Set user identity
function handleLogin(userId: string) {
  CSQ.identify(userId);

  CSQ.addUserProperties({
    subscription_tier: "premium",
    account_created_date: "2024-01-15",
    email_verified: true,
  });
}

// Product Analytics - Clear identity on logout
function handleLogout() {
  CSQ.resetIdentity();
}

// DXA - Send user identifier
function handleDXALogin(userId: string) {
  CSQ.sendUserIdentifier(userId);
}
```

---

## Dynamic Variables (DXA Only)

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// String dynamic var
CSQ.addDynamicVar("user_segment", "high_value");

// Number dynamic var
CSQ.addDynamicVar("ab_test_variant", 2);

// With error handling
CSQ.addDynamicVar("page_depth", 5, error => {
  console.error("Dynamic var error:", error.message);
});
```

---

## Screen Tracking with Custom Variables

```typescript
import { CSQ } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function ProductScreen({ productId, category }: Props) {
  useEffect(() => {
    CSQ.trackScreenview('ProductDetails', [
      { index: 1, key: 'product_id', value: productId },
      { index: 2, key: 'category', value: category },
      { index: 3, key: 'source', value: 'search' },
    ]);
  }, [productId, category]);

  return <ProductView />;
}
```

---

## React Navigation Screen Tracking

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';
import { useRef } from 'react';

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

        if (previousRouteName !== currentRouteName && currentRouteName) {
          // Track screen view
          CSQ.trackScreenview(currentRouteName);
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Profile" component={ProfileScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

---

## React Navigation with Custom Screen Names

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  const getScreenNameForRoute = (routeName: string) => {
    const screenNames = {
      Home: 'Main Dashboard',
      ProductDetails: 'Product View',
      Cart: 'Shopping Cart',
      Checkout: 'Checkout Flow',
    };
    return screenNames[routeName] || routeName;
  };

  return (
    <NavigationContainer
      ref={navigationRef}
      onReady={() => {
        routeNameRef.current = navigationRef.current?.getCurrentRoute()?.name;
      }}
      onStateChange={() => {
        const previousRouteName = routeNameRef.current;
        const currentRouteName = navigationRef.current?.getCurrentRoute()?.name;

        if (previousRouteName !== currentRouteName && currentRouteName) {
          const screenName = getScreenNameForRoute(currentRouteName);
          CSQ.trackScreenview(screenName);
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      {/* Your navigators */}
    </NavigationContainer>
  );
}
```

---

## Session Replay Masking - Basic

```typescript
import { CSQ, CSQMask } from '@contentsquare/react-native-bridge';

// Global masking (all-or-nothing) - must be called after CSQ.start(...)
CSQ.setDefaultMasking(true); // Mask everything
CSQ.setDefaultMasking(false); // Unmask everything

// Component-level masking
function SensitiveForm() {
  return (
    <CSQMask isSessionReplayMasked={true}>
      <TextInput placeholder="Credit Card Number" />
      <TextInput placeholder="CVV" />
    </CSQMask>
  );
}
```

---

## Session Replay Masking - Fine-Grained

````typescript
import { CSQMask } from '@contentsquare/react-native-bridge';

function PasswordField() {
  return (
## Session Replay Masking - Fine-Grained

```typescript
import { CSQMask } from '@contentsquare/react-native-bridge';

function PasswordField() {
  return (
    <CSQMask
      isSessionReplayMasked={true}  // Masks visual content in SR
      allowText={false}              // Prevents text in PA events
      allowInteraction={false}       // Prevents taps in PA events
    >
      <TextInput
        placeholder="Password"
        secureTextEntry
      />
    </CSQMask>
  );
}

function CreditCardForm() {
  return (
    <CSQMask
      isSessionReplayMasked={true}        // Masks visual content in SR
      allowInnerHierarchy={false}         // Prevents view structure in PA events
      allowProps={false}                  // Prevents view properties in PA events
    >
      <View>
        <TextInput placeholder="Card Number" />
        <TextInput placeholder="CVV" />
        <TextInput placeholder="Expiry Date" />
      </View>
    </CSQMask>
  );
}
````

**Note**: `isSessionReplayMasked` controls Session Replay visual masking. The `allow*` props control Product Analytics event data capture.

---

## WebView Integration

```typescript
import { CSQWebView } from '@contentsquare/react-native-bridge';
import { WebView } from 'react-native-webview';

function CheckoutWebView() {
  return (
    <CSQWebView>
      <WebView
        source={{ uri: 'https://example.com/checkout' }}
        style={{ flex: 1 }}
      />
    </CSQWebView>
  );
}

// Legacy wrapper (use CSQWebView instead)
import { CSWebView } from '@contentsquare/react-native-bridge';

function LegacyWebView() {
  return (
    <CSWebView>
      <WebView source={{ uri: 'https://example.com' }} />
    </CSWebView>
  );
}
```

---

## Higher-Order Component Masking

```typescript
import { withCSQMask } from '@contentsquare/react-native-bridge';

function SensitiveComponent({ data }: Props) {
  return (
    <View>
      <Text>{data.creditCard}</Text>
      <Text>{data.ssn}</Text>
    </View>
  );
}

// Wrap with masking
const MaskedSensitiveComponent = withCSQMask(SensitiveComponent, {
  isSessionReplayMasked: true,
  allowText: false,
  allowInteraction: false,
});

// Usage
<MaskedSensitiveComponent data={sensitiveData} />;
```

---

## Get Session Replay URL

`onMetadataChange` returns an **unsubscribe function** -- always clean it up on unmount:

```typescript
import { CSQ } from '@contentsquare/react-native-bridge';
import { useEffect, useState } from 'react';

function SessionReplayLink() {
  const [replayUrl, setReplayUrl] = useState<string | null>(null);

  useEffect(() => {
    const unsubscribe = CSQ.onMetadataChange(metadata => {
      if (metadata.sessionReplayUrl) {
        setReplayUrl(metadata.sessionReplayUrl);
        console.log('Session Replay URL:', metadata.sessionReplayUrl);
      }
    });

    return unsubscribe; // Cleanup on unmount
  }, []);

  return replayUrl ? <Text>Replay: {replayUrl}</Text> : null;
}
```

---

## On-Demand Session Replay

```typescript
import { CSQ, StartConfig } from "@contentsquare/react-native-bridge";

// Start SDK without auto-starting session replay
CSQ.start(
  StartConfig.withEnvironmentId("your-env-id", {
    sessionReplayAutoStart: false, // Don't start SR automatically
  }),
);

// Later, start session replay when needed (e.g., entering checkout)
function enterCheckout() {
  CSQ.startSessionReplay();
  // Navigate to checkout...
}

// Stop session replay (terminal - cannot restart)
function exitCheckout() {
  CSQ.stopSessionReplay();
}
```

---

## Event Properties (Global)

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// Add properties to all future events
CSQ.addEventProperties({
  app_version: "2.1.0",
  build_number: "456",
  environment: "production",
});

// Track events - properties are automatically included
CSQ.trackEvent("button_clicked");
CSQ.trackEvent("screen_viewed");

// Remove a specific property
CSQ.removeEventProperty("build_number");

// Clear all event properties
CSQ.clearEventProperties();
```

---

## Pause/Resume Tracking for Sensitive Screens

```typescript
import { CSQ } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function SensitiveScreen() {
  useEffect(() => {
    // Pause tracking when entering sensitive screen
    CSQ.pauseTracking();

    return () => {
      // Resume tracking when leaving
      CSQ.resumeTracking();
    };
  }, []);

  return <SensitiveContent />;
}
```

**Note**: Prefer using `CSQMask` for masking sensitive content instead of pausing tracking entirely.

---

## URL Masking for Error Tracking

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// Mask sensitive URL patterns in error tracking
CSQ.setUrlMaskingPatterns([
  "/api/user/*/private",
  "/admin/*",
  "/secure/*",
  "/payment/*/details",
]);
```

---

## Debug Logging

```typescript
import { CSQ, LogLevel, LogChannel } from "@contentsquare/react-native-bridge";

// Enable verbose logging for development
if (__DEV__) {
  CSQ.setLogLevel(LogLevel.VERBOSE);
  CSQ.setLogChannel(LogChannel.CONSOLE);

  // Or use shorthand
  CSQ.logToConsole();
}

// Disable logging in production
if (!__DEV__) {
  CSQ.setLogLevel(LogLevel.NONE);
}
```

---

## Complete Setup with Error Handling

```typescript
import { CSQ, StartConfig } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function App() {
  useEffect(() => {
    initializeSDK();
  }, []);

  const initializeSDK = async () => {
    try {
      // Start SDK
      CSQ.start(
        StartConfig.withEnvironmentId('your-env-id', {
          enableRNAutocapture: true,
          sessionReplayAutoStart: true,
          uploadInterval: 10000,
        })
      );

      // Enable debug logging in development
      if (__DEV__) {
        CSQ.logToConsole();
        CSQ.setLogLevel(LogLevel.VERBOSE);
      }

      // Check consent status (from AsyncStorage, SecureStore, etc.)
      const hasConsent = await checkConsentStatus();
      if (hasConsent) {
        CSQ.optIn();
      }

      // Set up session metadata listener (returns unsubscribe function)
      const unsubscribeMetadata = CSQ.onMetadataChange(metadata => {
        console.log('Session ID:', metadata.sessionID);
        console.log('Replay URL:', metadata.sessionReplayUrl);
      });
      // Store unsubscribeMetadata to call it during cleanup if needed

      // Mask sensitive URLs
      CSQ.setUrlMaskingPatterns(['/api/user/*/private', '/admin/*']);
    } catch (error) {
      console.error('Failed to initialize Contentsquare:', error);
    }
  };

  return <YourApp />;
}
```

---

## TypeScript Types

```typescript
import type {
  CSQConfig,
  AnalyticsOptions,
  Transaction,
  Currency,
  CustomVar,
  PropertyValue,
  CSQMetadata,
  CSQMaskProps,
  LogLevel,
  LogChannel,
} from "@contentsquare/react-native-bridge";

// Example usage
const options: AnalyticsOptions = {
  enableRNAutocapture: true,
  sessionReplayAutoStart: true,
};

const transaction: Transaction = {
  price: 99.99,
  currency: Currency.USD,
  id: "order_123",
};

const customVars: CustomVar[] = [
  { index: 1, key: "product_id", value: "12345" },
];
```

---

## Platform-Specific Code

```typescript
import { Platform } from "react-native";
import { CSQ } from "@contentsquare/react-native-bridge";

// iOS-specific configuration
if (Platform.OS === "ios") {
  CSQ.start(
    StartConfig.withEnvironmentId("your-env-id", {
      disableInteractionTextCapture: true,
      disablePageviewTitleAutocapture: true,
    }),
  );
}

// Android-specific configuration
if (Platform.OS === "android") {
  CSQ.start(
    StartConfig.withEnvironmentId("your-env-id", {
      uploadInterval: 5000,
    }),
  );
}
```

---

## Best Practices Summary

1. **Start early**: Call `CSQ.start(config)` with appropriate config in App component's useEffect
2. **Consent first**: Implement consent flow before `optIn()`
3. **Track screens**: Use React Navigation integration or manual tracking
4. **Wrap WebViews**: Every WebView needs `CSQWebView` wrapper
5. **Mask PII**: Use `CSQMask` for sensitive content
6. **Handle errors**: Wrap SDK calls in try-catch in production
7. **Test thoroughly**: Verify session replay and tracking before release
8. **Use TypeScript**: Leverage type definitions for better DX
9. **Debug in dev**: Enable verbose logging during development
10. **Monitor uploads**: Configure appropriate `uploadInterval`

# Session Replay Masking

Session Replay captures user interactions for analysis. Masking protects sensitive data (passwords, credit cards, PII) from being recorded.

---

## Masking Approaches

React Native SDK provides three masking levels:

1. **Global masking** - All-or-nothing for entire app
2. **Component masking** - Per-component with `CSQMask`
3. **Fine-grained control** - Selective masking with `allow*` props

---

## Global Masking

Use `setDefaultMasking()` for app-wide masking policy:

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// Mask everything by default (safest)
CSQ.setDefaultMasking(true);

// Unmask everything (use with caution - privacy risk)
CSQ.setDefaultMasking(false);
```

**Important**:

- `setDefaultMasking` is **boolean only**. It's all-or-nothing. For selective masking, use `CSQMask` component.
- `setDefaultMasking` must be called **after** `CSQ.start(...)`. Calling it before `start()` has no effect.

---

## Component-Level Masking

### Basic CSQMask

Mask sensitive components:

```typescript
import { CSQMask } from '@contentsquare/react-native-bridge';
import { TextInput } from 'react-native';

function PasswordField() {
  return (
    <CSQMask isSessionReplayMasked={true}>
      <TextInput placeholder="Password" secureTextEntry />
    </CSQMask>
  );
}
```

### Unmask within Masked Context

```typescript
<CSQMask isSessionReplayMasked={true}>
  <View>
    <TextInput placeholder="Credit Card" />

    {/* Unmask this specific component */}
    <CSQMask isSessionReplayMasked={false}>
      <Text>Card Type: Visa</Text>
    </CSQMask>
  </View>
</CSQMask>
```

---

## Fine-Grained Control

### Session Replay vs Product Analytics

**Important distinction:**

- `isSessionReplayMasked` - Controls **Session Replay** masking (visual recording)
- `allow*` props - Control **Product Analytics** autocapture features (event tracking)

### Allow Props (Product Analytics)

When using Product Analytics with autocapture enabled, control what data gets captured for interaction events:

```typescript
import { CSQMask } from '@contentsquare/react-native-bridge';

<CSQMask
  isSessionReplayMasked={true} // Masks visual content in Session Replay
  allowText={false} // Prevents text capture in PA events
  allowInteraction={false} // Prevents interaction tracking in PA events
>
  <TextInput placeholder="SSN" />
</CSQMask>;
```

### Available Props

| Prop                      | Type       | Default | Purpose                                   | Feature               |
| ------------------------- | ---------- | ------- | ----------------------------------------- | --------------------- |
| `isSessionReplayMasked`   | `boolean?` | `true`  | Whether to mask visual content            | **Session Replay**    |
| `ignoreTextOnly`          | `boolean?` | `false` | Ignore text only (conflicts with allow\*) | **Product Analytics** |
| `allowInnerHierarchy`     | `boolean?` | `false` | Allow inner view hierarchy in events      | **Product Analytics** |
| `allowProps`              | `boolean?` | `false` | Allow view properties in events           | **Product Analytics** |
| `allowText`               | `boolean?` | `false` | Allow text content in events              | **Product Analytics** |
| `allowInteraction`        | `boolean?` | `false` | Allow interaction tracking in events      | **Product Analytics** |
| `allowAccessibilityLabel` | `boolean?` | `false` | Allow accessibility labels in events      | **Product Analytics** |

**Important**:

- Only `isSessionReplayMasked` affects Session Replay visual masking
- The `allow*` props control Product Analytics event data capture
- When `ignoreTextOnly` is `true`, all `allow*` props are ignored

---

## Common Use Cases

### Credit Card Form

```typescript
import { CSQMask } from '@contentsquare/react-native-bridge';
import { View, TextInput, Text } from 'react-native';

function CreditCardForm() {
  return (
    <CSQMask isSessionReplayMasked={true}>
      <View>
        <Text>Card Number</Text>
        <TextInput placeholder="1234 5678 9012 3456" />

        <Text>CVV</Text>
        <TextInput placeholder="123" secureTextEntry />

        <Text>Expiry Date</Text>
        <TextInput placeholder="MM/YY" />
      </View>
    </CSQMask>
  );
}
```

**Note**: `isSessionReplayMasked={true}` masks the visual content in Session Replay. For Product Analytics event masking, add `allow*` props as needed.

### Password Fields

```typescript
function PasswordInput() {
  return (
    <CSQMask isSessionReplayMasked={true}>
      <TextInput placeholder="Password" secureTextEntry />
    </CSQMask>
  );
}
```

**Note**: Add `allowText={false}` and `allowInteraction={false}` if you also need to prevent Product Analytics event data capture.

### Personal Information

```typescript
function PersonalInfoForm() {
  return (
    <View>
      {/* Unmask labels */}
      <Text>Email</Text>

      {/* Mask input */}
      <CSQMask isSessionReplayMasked={true}>
        <TextInput placeholder="email@example.com" />
      </CSQMask>

      <Text>Phone</Text>

      <CSQMask isSessionReplayMasked={true}>
        <TextInput placeholder="+1 (555) 123-4567" />
      </CSQMask>
    </View>
  );
}
```

### Address Form (Partial Masking)

```typescript
function AddressForm() {
  return (
    <View>
      {/* Don't mask these */}
      <TextInput placeholder="Country" />
      <TextInput placeholder="City" />
      <TextInput placeholder="Zip Code" />

      {/* Mask street address */}
      <CSQMask isSessionReplayMasked={true}>
        <TextInput placeholder="Street Address" />
      </CSQMask>
    </View>
  );
}
```

### User Profile with Mixed Content

```typescript
function UserProfile() {
  return (
    <View>
      {/* Public info - not masked */}
      <Text>Username: {username}</Text>
      <Text>Member since: {joinDate}</Text>

      {/* Sensitive info - masked */}
      <CSQMask isSessionReplayMasked={true}>
        <Text>Email: {email}</Text>
        <Text>Phone: {phone}</Text>
        <Text>Address: {address}</Text>
      </CSQMask>
    </View>
  );
}
```

---

## Higher-Order Component

Use `withCSQMask` for reusable masked components:

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

// Create masked version
const MaskedSensitiveComponent = withCSQMask(SensitiveComponent, {
  isSessionReplayMasked: true,
  // Optional: Add PA event masking if needed
  allowText: false,
  allowInteraction: false,
});

// Usage
<MaskedSensitiveComponent data={sensitiveData} />;
```

---

## Masking Strategies

### Strategy 1: Mask Everything, Unmask Selectively

Safest approach for apps with lots of sensitive data:

```typescript
import { CSQ, StartConfig } from '@contentsquare/react-native-bridge';

// In App initialization (must be called after start)
// Use whichever StartConfig matches your setup (dxa, withEnvironmentId, or withDataSourceId)
CSQ.start(/* your StartConfig here */);
CSQ.setDefaultMasking(true); // Mask everything

// Then unmask specific safe components
function PublicContent() {
  return (
    <CSQMask isSessionReplayMasked={false}>
      <Text>This is safe public content</Text>
    </CSQMask>
  );
}
```

### Strategy 2: Unmask Everything, Mask Selectively

Better for apps with minimal sensitive data:

```typescript
import { CSQ, StartConfig } from '@contentsquare/react-native-bridge';

// In App initialization (must be called after start)
// Use whichever StartConfig matches your setup (dxa, withEnvironmentId, or withDataSourceId)
CSQ.start(/* your StartConfig here */);
CSQ.setDefaultMasking(false); // Don't mask by default

// Then mask specific sensitive components
function SensitiveContent() {
  return (
    <CSQMask isSessionReplayMasked={true}>
      <TextInput placeholder="Credit Card" />
    </CSQMask>
  );
}
```

### Strategy 3: Screen-Based Masking

Mask entire sensitive screens:

```typescript
function CheckoutScreen() {
  return (
    <CSQMask isSessionReplayMasked={true}>
      <View style={{ flex: 1 }}>
        {/* All content in checkout is masked */}
        <PaymentForm />
        <BillingAddress />
        <OrderSummary />
      </View>
    </CSQMask>
  );
}
```

---

## Best Practices

### 1. Mask PII by Default

Always mask in **Session Replay** using `isSessionReplayMasked={true}`:

- Passwords
- Credit card numbers
- CVV codes
- Social Security Numbers
- Bank account numbers
- Driver's license numbers
- Email addresses (in forms)
- Phone numbers (in forms)
- Full addresses (street level)

For **Product Analytics**, also use `allow*` props to control event data capture.

### 2. Consider Context

Some data is sensitive in some contexts but not others:

- **User profile edit**: Mask email/phone inputs
- **User profile view**: May not need masking (depends on app)
- **Search results**: Usually safe to unmask
- **Forms**: Mask input fields

### 3. Test Masking

Verify masking works:

```typescript
import { CSQ } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function App() {
  useEffect(() => {
    // Get session replay URL
    const unsubscribe = CSQ.onMetadataChange(metadata => {
      if (metadata.sessionReplayUrl) {
        console.log('Review session replay:', metadata.sessionReplayUrl);
        // Manually check if sensitive data is masked
      }
    });

    return unsubscribe; // Cleanup on unmount
  }, []);

  return <YourApp />;
}
```

### 4. Performance Considerations

- Masking has minimal performance impact
- Prefer component-level masking over screen-level when possible
- Don't nest too many `CSQMask` components (max 3-4 levels)

### 5. Documentation

Document your masking strategy:

```typescript
/**
 * Masking Strategy:
 * - Default: Unmask everything (setDefaultMasking(false))
 * - Mask: All payment forms, PII inputs, user credentials
 * - Unmask: Public content, product info, navigation
 */
```

---

## Masking Patterns

### Pattern: Mask Form, Unmask Labels

```typescript
function RegistrationForm() {
  return (
    <View>
      {/* Labels visible */}
      <Text>Email Address</Text>

      {/* Input masked */}
      <CSQMask isSessionReplayMasked={true}>
        <TextInput />
      </CSQMask>

      <Text>Password</Text>

      <CSQMask isSessionReplayMasked={true}>
        <TextInput secureTextEntry />
      </CSQMask>
    </View>
  );
}
```

### Pattern: Conditional Masking

```typescript
function UserDataDisplay({ isPublicProfile }: Props) {
  return (
    <CSQMask isSessionReplayMasked={!isPublicProfile}>
      <Text>{email}</Text>
      <Text>{phone}</Text>
    </CSQMask>
  );
}
```

### Pattern: Role-Based Masking

```typescript
function AdminPanel({ userRole }: Props) {
  const shouldMask = userRole !== 'admin';

  return (
    <CSQMask isSessionReplayMasked={shouldMask}>
      <SensitiveAdminData />
    </CSQMask>
  );
}
```

---

## On-Demand Session Replay

Start/stop session replay based on user actions:

```typescript
import { CSQ, StartConfig } from "@contentsquare/react-native-bridge";

// Start SDK without auto-starting session replay
CSQ.start(
  StartConfig.withEnvironmentId("your-env-id", {
    sessionReplayAutoStart: false,
  }),
);

// Start session replay when user enters checkout
function enterCheckout() {
  CSQ.startSessionReplay();
  navigation.navigate("Checkout");
}

// Stop when checkout complete (terminal - cannot restart)
function checkoutComplete() {
  CSQ.stopSessionReplay();
}
```

**Important**:

- `startSessionReplay()` is **one-shot** - not a toggle
- `stopSessionReplay()` is **terminal** - SR cannot restart in same SDK lifetime

---

## Debugging Masking

### Check What's Masked

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";
import { useEffect } from "react";

// Enable verbose logging
if (__DEV__) {
  CSQ.logToConsole();
  CSQ.setLogLevel(LogLevel.VERBOSE);
}

useEffect(() => {
  // Get session replay URL
  const unsubscribe = CSQ.onMetadataChange(metadata => {
    console.log("Session Replay URL:", metadata.sessionReplayUrl);
    // Open URL and verify masking
  });

  return unsubscribe;
}, []);
```

### Common Issues

**Problem**: Content not masked

**Solution**:

1. Verify `isSessionReplayMasked={true}` is set
2. Check if parent has `isSessionReplayMasked={false}` (overrides)
3. Ensure CSQMask wraps the sensitive component

**Problem**: Everything is masked

**Solution**:

1. Check if `CSQ.setDefaultMasking(true)` was called
2. Look for parent CSQMask with `isSessionReplayMasked={true}`

**Problem**: allow\* props not working

**Solution**:

1. Ensure `ignoreTextOnly` is not set to `true` (conflicts with allow\*)
2. Verify `isSessionReplayMasked={true}` is also set

---

## Advanced: Custom Masking Logic

### Mask Based on Environment

```typescript
function App() {
  const isDevelopment = __DEV__;

  return (
    <CSQMask isSessionReplayMasked={!isDevelopment}>
      <SensitiveContent />
    </CSQMask>
  );
}
```

### Mask Based on Feature Flag

```typescript
function SensitiveFeature() {
  const { maskingEnabled } = useFeatureFlags();

  return (
    <CSQMask isSessionReplayMasked={maskingEnabled}>
      <FeatureContent />
    </CSQMask>
  );
}
```

### Mask Based on User Consent

```typescript
function UserProfile() {
  const { hasAnalyticsConsent } = useConsent();

  return (
    <CSQMask isSessionReplayMasked={!hasAnalyticsConsent}>
      <ProfileData />
    </CSQMask>
  );
}
```

---

## Legal Compliance

### GDPR

- Mask all PII by default
- Get user consent before session replay
- Provide opt-out mechanism

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// Only opt-in after consent
function handleConsent(accepted: boolean) {
  if (accepted) {
    CSQ.optIn();
  } else {
    CSQ.optOut();
  }
}
```

### CCPA

- Similar to GDPR
- Provide "Do Not Sell" option
- Respect opt-out

### PCI-DSS (Payment Card Data)

Never capture:

- Full credit card numbers
- CVV/CVC codes
- Card expiration dates (if combined with card number)

```typescript
// ALWAYS mask payment forms
function PaymentForm() {
  return (
    <CSQMask
      isSessionReplayMasked={true}
      allowInnerHierarchy={false}
      allowProps={false}
    >
      <CreditCardInput />
      <CVVInput />
      <ExpiryInput />
    </CSQMask>
  );
}
```

---

## Checklist

Before releasing session replay:

- [ ] All password fields are masked
- [ ] All credit card inputs are masked
- [ ] All PII forms are masked (email, phone, address inputs)
- [ ] Tested session replay URL to verify masking
- [ ] Documented masking strategy
- [ ] User consent flow implemented
- [ ] Opt-out mechanism available
- [ ] Legal team has reviewed
- [ ] No hardcoded sensitive data in screen names
- [ ] WebViews are wrapped with CSQWebView

---

## Resources

- [Session Replay Overview](https://docs.contentsquare.com/session-replay/)
- [Privacy and Security](https://docs.contentsquare.com/privacy/)
- [React Native SDK](https://docs.contentsquare.com/react-native/)
- [WebView Tracking Tag](https://docs.contentsquare.com/en/webview-tracking-tag/)

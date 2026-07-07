# Contentsquare React Native SDK -- Migration Guide

This guide covers migrating from legacy APIs to the current SDK.

---

## Legacy `Contentsquare` to `CSQ`

If you're using the deprecated `Contentsquare` default export, migrate to `CSQ` for better TypeScript support and future compatibility.

### Import Changes

```typescript
// Before (deprecated)
import Contentsquare from "@contentsquare/react-native-bridge";

// After (recommended)
import { CSQ } from "@contentsquare/react-native-bridge";
```

### API Method Mapping

| Legacy `Contentsquare`                  | Current `CSQ`                 | Notes                           |
| --------------------------------------- | ----------------------------- | ------------------------------- |
| `Contentsquare.start()`                 | `CSQ.start(config)`           | Config parameter now required   |
| `Contentsquare.stop()`                  | `CSQ.stop()`                  | Same signature                  |
| `Contentsquare.optIn()`                 | `CSQ.optIn()`                 | Same signature                  |
| `Contentsquare.optOut()`                | `CSQ.optOut()`                | Same signature                  |
| `Contentsquare.identify()`              | `CSQ.identify()`              | Same signature                  |
| `Contentsquare.resetIdentity()`         | `CSQ.resetIdentity()`         | Same signature                  |
| `Contentsquare.sendUserIdentifier()`    | `CSQ.sendUserIdentifier()`    | Same signature                  |
| `Contentsquare.trackScreenview()`       | `CSQ.trackScreenview()`       | Same signature                  |
| `Contentsquare.trackTransaction()`      | `CSQ.trackTransaction()`      | Same signature                  |
| `Contentsquare.trackEvent()`            | `CSQ.trackEvent()`            | Same signature                  |
| `Contentsquare.addDynamicVar()`         | `CSQ.addDynamicVar()`         | Different signature - see below |
| `Contentsquare.addUserProperties()`     | `CSQ.addUserProperties()`     | Same signature                  |
| `Contentsquare.addEventProperties()`    | `CSQ.addEventProperties()`    | Same signature                  |
| `Contentsquare.removeEventProperty()`   | `CSQ.removeEventProperty()`   | Same signature                  |
| `Contentsquare.clearEventProperties()`  | `CSQ.clearEventProperties()`  | Same signature                  |
| `Contentsquare.startSessionReplay()`    | `CSQ.startSessionReplay()`    | Same signature                  |
| `Contentsquare.stopSessionReplay()`     | `CSQ.stopSessionReplay()`     | Same signature                  |
| `Contentsquare.setDefaultMasking()`     | `CSQ.setDefaultMasking()`     | Same signature                  |
| `Contentsquare.pauseTracking()`         | `CSQ.pauseTracking()`         | Same signature                  |
| `Contentsquare.resumeTracking()`        | `CSQ.resumeTracking()`        | Same signature                  |
| `Contentsquare.setLogLevel()`           | `CSQ.setLogLevel()`           | Same signature                  |
| `Contentsquare.setLogChannel()`         | `CSQ.setLogChannel()`         | Same signature                  |
| `Contentsquare.logToConsole()`          | `CSQ.logToConsole()`          | Same signature                  |
| `Contentsquare.onMetadataChange()`      | `CSQ.onMetadataChange()`      | Same signature                  |
| `Contentsquare.setUrlMaskingPatterns()` | `CSQ.setUrlMaskingPatterns()` | Same signature                  |

### addDynamicVar Signature Change

The signature changed from object parameter to separate parameters:

```typescript
// Before (legacy object syntax - may still work in some versions)
Contentsquare.sendDynamicVar(key, value);

// After (current API)
CSQ.addDynamicVar(key, value, onError?);
```

**Example:**

```typescript
// Before
Contentsquare.sendDynamicVar("user_segment", "premium");

// After
CSQ.addDynamicVar("user_segment", "premium");
CSQ.addDynamicVar("ab_test_variant", 2, error => {
  console.error("Error:", error);
});
```

---

## Component Migrations

### CSWebView → CSQWebView

The legacy `CSWebView` component is deprecated. Use `CSQWebView` instead.

```typescript
// Before (deprecated)
import { CSWebView } from '@contentsquare/react-native-bridge';

<CSWebView>
  <WebView source={{ uri: 'https://example.com' }} />
</CSWebView>

// After (recommended)
import { CSQWebView } from '@contentsquare/react-native-bridge';

<CSQWebView>
  <WebView source={{ uri: 'https://example.com' }} />
</CSQWebView>
```

**Why?** `CSQWebView` provides better TypeScript types and aligns with the CSQ naming convention.

### CSMask → CSQMask (if applicable)

If you're using the legacy `CSMask` component, migrate to `CSQMask`:

```typescript
// Before (if you have this)
import { CSMask } from '@contentsquare/react-native-bridge';

<CSMask isMasking={true}>
  <Text>Sensitive</Text>
</CSMask>

// After
import { CSQMask } from '@contentsquare/react-native-bridge';

<CSQMask isSessionReplayMasked={true}>
  <Text>Sensitive</Text>
</CSQMask>
```

**Prop changes:**

- `isMasking` → `isSessionReplayMasked`
- Additional props available: `allowText`, `allowInteraction`, etc.

---

## StartConfig Migration

### configureProductAnalytics (if used)

If you were using a legacy `configureProductAnalytics` method, migrate to `StartConfig.withEnvironmentId`:

```typescript
// Before (legacy - may not exist in all versions)
Contentsquare.configureProductAnalytics({
  environmentId: "your-env-id",
  options: { enableRNAutocapture: true },
});

// After
import { CSQ, StartConfig } from "@contentsquare/react-native-bridge";

CSQ.start(
  StartConfig.withEnvironmentId("your-env-id", {
    enableRNAutocapture: true,
  }),
);
```

---

## Migration Steps

### Step 1: Update Imports

Replace all `Contentsquare` imports:

```bash
# Find all occurrences
grep -r "import.*Contentsquare.*from '@contentsquare/react-native-bridge'" .

# Replace with CSQ import
# Before: import Contentsquare from '@contentsquare/react-native-bridge';
# After: import { CSQ } from '@contentsquare/react-native-bridge';
```

### Step 2: Replace Method Calls

Replace all `Contentsquare.` with `CSQ.`:

```bash
# Find all occurrences
grep -r "Contentsquare\." .

# Replace Contentsquare. with CSQ.
```

### Step 3: Update addDynamicVar Calls

Update any `addDynamicVar` calls to use the new signature:

```typescript
// Check all addDynamicVar calls and ensure they use:
CSQ.addDynamicVar(key, value, onError?);
```

### Step 4: Update Components

Replace deprecated component names:

```bash
# Find CSWebView usage
grep -r "CSWebView" .

# Replace with CSQWebView
```

### Step 5: Update StartConfig

If using legacy configuration:

```typescript
// Replace any legacy start configuration with:
CSQ.start(StartConfig.withEnvironmentId("your-env-id", options));
// or
CSQ.start(StartConfig.withDataSourceId("your-datasource-id", options));
// or
CSQ.start(StartConfig.dxa());
```

### Step 6: Test Thoroughly

1. **Build verification**: Ensure the app builds without errors
2. **Runtime testing**: Verify SDK starts correctly
3. **Screen tracking**: Confirm screens are tracked
4. **Session replay**: Check if session replay is working
5. **Masking**: Verify sensitive content is masked

---

## Common Migration Issues

### Issue: TypeScript errors after migration

**Problem**: TypeScript complains about types after switching to `CSQ`.

**Solution**: Ensure you're importing types correctly:

```typescript
import type {
  CSQConfig,
  AnalyticsOptions,
  Transaction,
  CustomVar,
  PropertyValue,
} from "@contentsquare/react-native-bridge";
```

### Issue: addDynamicVar not working

**Problem**: Dynamic variables not being tracked.

**Solution**: Check the signature - it's `(key, value, onError?)` not an object:

```typescript
// Correct
CSQ.addDynamicVar("key", "value");

// Incorrect (legacy)
CSQ.addDynamicVar({ key: "key", value: "value" });
```

### Issue: CSQWebView not found

**Problem**: Import error for `CSQWebView`.

**Solution**: Ensure you're using a recent version of the SDK:

```json
{
  "dependencies": {
    "@contentsquare/react-native-bridge": "^6.0.1"
  }
}
```

Then run:

```bash
npm install
cd ios && pod install && cd ..
```

### Issue: Masking not working after migration

**Problem**: Content not masked after switching to `CSQMask`.

**Solution**: Check prop names:

```typescript
// Old prop name
<CSMask isMasking={true}>

// New prop name
<CSQMask isSessionReplayMasked={true}>
```

---

## Gradual Migration

You can migrate gradually since the deprecated APIs still work (for now):

### Phase 1: New Code Only

Use `CSQ` in all new code while keeping existing `Contentsquare` calls:

```typescript
// Existing code - leave as is for now
Contentsquare.trackScreenview("Home");

// New code - use CSQ
CSQ.trackEvent("button_clicked");
```

### Phase 2: File-by-File

Migrate one file at a time:

1. Update imports in one file
2. Replace all method calls in that file
3. Test that file
4. Move to next file

### Phase 3: Complete Migration

Once all files are migrated:

1. Remove all `Contentsquare` imports
2. Verify no references to deprecated APIs
3. Run full test suite
4. Deploy

---

## Verification Checklist

After migration, verify:

- [ ] All imports use `CSQ` not `Contentsquare`
- [ ] All method calls use `CSQ.methodName()`
- [ ] `addDynamicVar` uses correct signature
- [ ] Components use `CSQWebView` not `CSWebView`
- [ ] Masking uses `CSQMask` with `isSessionReplayMasked` prop
- [ ] App builds without TypeScript errors
- [ ] SDK starts successfully
- [ ] Screen tracking works
- [ ] Session replay works
- [ ] Masking works
- [ ] No console warnings about deprecated APIs

---

## Future-Proofing

To avoid future migrations:

1. **Always use `CSQ`**: Never use `Contentsquare` even if available
2. **Use named imports**: Import specific items, not default exports
3. **Stay updated**: Keep SDK version current
4. **Check changelog**: Review breaking changes in release notes
5. **Use TypeScript**: Types will catch API changes early

---

## Migration Support

If you encounter issues during migration:

1. Check [React Native SDK docs](https://docs.contentsquare.com/react-native/)
2. Review [API Reference](api-reference.md)
3. Check [Common Patterns](common-patterns.md) for examples
4. Contact Contentsquare support

---

## Timeline

**Deprecation notices**: The legacy `Contentsquare` API is deprecated but still functional.

**Removal**: Future major version may remove deprecated APIs entirely.

**Recommendation**: Migrate as soon as possible to avoid breaking changes.

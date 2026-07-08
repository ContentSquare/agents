# React Native Compatibility

This document outlines React Native version requirements, platform support, and known limitations for the Contentsquare SDK.

## Table of Contents

- [Supported Platforms](#supported-platforms)
- [Version Compatibility Matrix](#version-compatibility-matrix)
- [Expo Configuration](#expo-configuration)
- [Hybrid Applications](#hybrid-applications)
- [Known Limitations](#known-limitations)
- [Best Practices](#best-practices)

## Supported Platforms

The CSQ React Native Bridge supports:

- **Android**: Full support
- **iOS**: Full support

**Not Supported**:

- Web (React Native Web)
- Windows
- macOS
- Other platforms

If you need support for additional platforms, contact the Contentsquare support team.

### Hybrid Applications

**Hybrid applications are not supported.** By "hybrid application," we mean [integrating React Native components into existing native applications](https://reactnative.dev/docs/integration-with-existing-apps).

**Important**: Never call the Bridge's NativeModule directly. Always use:

- The JavaScript `CSQ` module in React Native code
- Native SDKs in native code

## Version Compatibility Matrix

Each CSQ bridge version links to specific native SDK versions:

| Bridge Version | iOS SDK | Android SDK | Min React Native | Max React Native |
| -------------- | ------- | ----------- | ---------------- | ---------------- |
| 6.2.0          | 1.6.1   | 1.5.1       | 0.71.0           | latest\*         |
| 6.1.0          | 1.6.0   | 1.5.0       | 0.71.0           | 0.84.x           |
| 6.0.5          | 1.5.1   | 1.4.7       | 0.71.0           | 0.82.x           |
| 6.0.3          | 1.5.1   | 1.4.2       | 0.71.0           | 0.82.x           |
| 6.0.2          | 1.5.1   | 1.4.2       | 0.71.0           | 0.82.x           |
| 6.0.1          | 1.5.1   | 1.4.2       | 0.71.0           | 0.81.x           |

**\*Note**: Starting with version 6.2.0, there is no maximum React Native version restriction. The SDK supports all current and future React Native versions from 0.71.0 onwards.

### Minimum Version Requirement

**React Native >= 0.71.0** is required.

We support all React Native versions that are currently maintained and listed on the [official React Native documentation](https://reactnative.dev/versions).

### Checking Your Version

```bash
# Check React Native version
npx react-native --version

# Or check package.json
cat package.json | grep "react-native"
```

## Expo Configuration

To use the CSQ SDK with Expo, you need:

- **Expo project with EAS** (Expo Application Services)
- **Cannot use Expo Go** (native modules required)

### Configuration Steps

#### 1. Update app.json

Add the plugin and bundle identifiers:

**app.json**

```json
{
  "expo": {
    "name": "Your App",
    "slug": "your-app",
    "ios": {
      "bundleIdentifier": "com.yourcompany.yourapp"
    },
    "android": {
      "package": "com.yourcompany.yourapp"
    },
    "plugins": ["@contentsquare/react-native-bridge"]
  }
}
```

#### 2. Update Run Scripts

Modify **package.json** to use `expo run` instead of Expo Go:

**package.json**

```json
{
  "scripts": {
    "start": "expo start",
    "android": "expo run:android",
    "ios": "expo run:ios"
  }
}
```

#### 3. Build and Run

```bash
# iOS
npm run ios
# or
expo run:ios

# Android
npm run android
# or
expo run:android
```

**Important**: You cannot use `expo start` with Expo Go for this SDK. The SDK requires native modules that aren't available in Expo Go.

### EAS Build

For production builds with EAS:

**eas.json**

```json
{
  "build": {
    "production": {
      "ios": {
        "buildConfiguration": "Release"
      },
      "android": {
        "buildType": "apk"
      }
    }
  }
}
```

Build commands:

```bash
# Build for iOS
eas build --platform ios

# Build for Android
eas build --platform android
```

## Hybrid Applications

### Mixed Native and React Native Code

If your app combines native and React Native screens:

**Your Responsibility**:

- Track each screen with the appropriate SDK (native or bridge)
- Send events via the correct API (native SDK or CSQ bridge)
- Manage user consent across both environments

**Example Scenarios**:

| Screen Type               | Use This SDK |
| ------------------------- | ------------ |
| Native Android Activity   | Android SDK  |
| Native iOS ViewController | iOS SDK      |
| React Native Component    | CSQ Bridge   |

**Transaction Example**:

```typescript
// React Native checkout screen
import { CSQ, Currency } from "@contentsquare/react-native-bridge";

CSQ.trackTransaction({
  price: 29.99,
  currency: Currency.USD,
  id: "order_123",
});
```

```kotlin
// Native Android checkout activity
import com.contentsquare.android.Contentsquare
import com.contentsquare.android.model.Currency

Contentsquare.trackTransaction(
    price = 29.99,
    currency = Currency.USD,
    id = "order_123"
)
```

### Integration Resources

- [Android SDK Documentation](https://docs.contentsquare.com/en/android/)
- [iOS SDK Documentation](https://docs.contentsquare.com/en/ios/)

## Known Limitations

### 1. React Native WebView goBack() (iOS Only)

**Issue**: The `goBack()` method on React Native's WebView component may not be registered by Session Replay in some cases, causing incomplete webview replays.

**Affected Platform**: iOS only

**Impact**: Some webview navigation may not appear in Session Replay recordings.

**Workaround**: None currently available. If webview navigation is critical to your analysis, use alternative navigation patterns or track webview states manually.

### 2. PanResponder Conflicts

**Issue**: PanResponders may freeze after ~1 second due to a conflict with Contentsquare's swipe tracking.

**Affected Components**: Any component using `PanResponder`

**Workaround**: Pause tracking during pan gestures:

```javascript
import { useRef } from "react";
import { PanResponder } from "react-native";
import { CSQ } from "@contentsquare/react-native-bridge";

const panResponder = useRef(
  PanResponder.create({
    onPanResponderGrant: (evt, gestureState) => {
      CSQ.pauseTracking(); // Stop tracking when pan starts
      // Your pan logic
    },
    onPanResponderRelease: (evt, gestureState) => {
      CSQ.resumeTracking(); // Resume when pan ends
      // Your release logic
    },
  }),
).current;
```

**Trade-off**: Swipe events on PanResponder views won't be tracked by Contentsquare.

**Alternative**: If swipe tracking is critical, consider using alternative gesture libraries that don't conflict with the SDK.

### 3. Autocapture with Expo

**Issue**: Babel plugin configuration may require additional setup in Expo projects.

**Resolution**: Ensure the Babel plugin is included in your **babel.config.js** or **metro.config.js**:

```javascript
// babel.config.js
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ["babel-preset-expo"],
    plugins: ["@contentsquare/react-native-bridge/babel"],
  };
};
```

### 4. Hermes Compatibility

**Status**: Fully compatible with Hermes engine (React Native's default JavaScript engine).

**Source Maps**: Ensure Hermes flags are configured for crash symbolication:

```groovy
// android/app/build.gradle
react {
  hermesFlags = ['-O', '-output-source-map']
}
```

## Best Practices

### Version Management

1. **Pin versions**: Always specify exact versions in **package.json**:

   ```json
   {
     "dependencies": {
       "@contentsquare/react-native-bridge": "6.2.0"
     }
   }
   ```

2. **Review changelogs**: Check [React Native Bridge Changelog](https://docs.contentsquare.com/en/react-native/changelog/) before upgrading

3. **Test thoroughly**: Verify SDK functionality after React Native upgrades

### Platform-Specific Considerations

#### iOS

- **Swift Standard Libraries**: Ensure "Embedded Content Contains Swift Code" is set to YES in target Build Settings
- **CocoaPods**: Requires CocoaPods >= 1.10.0 for XCFramework support
  ```bash
  pod --version
  # If < 1.10.0:
  [sudo] gem install cocoapods
  ```

#### Android

- **Minimum SDK**: Android SDK 21+ (Android 5.0 Lollipop)
- **Gradle Plugin**: Add Contentsquare plugins for Error Analysis and Crash Reporting:
  ```groovy
  // app/build.gradle
  apply plugin: "com.contentsquare.error.analysis.network"
  apply plugin: "com.contentsquare.error.analysis.crash"
  ```

### Migration Strategy

When upgrading React Native versions:

1. **Check compatibility matrix**: Verify your target React Native version is supported
2. **Update bridge version**: Upgrade CSQ bridge if necessary
3. **Update native dependencies**:

   ```bash
   # iOS
   cd ios && pod install && cd ..

   # Android
   cd android && ./gradlew clean && cd ..
   ```

4. **Test core features**:
   - SDK initialization
   - Screen tracking
   - Session Replay
   - Consent flow
5. **Verify autocapture**: Test instrumented components
6. **Check source maps**: Ensure crash symbolication still works

### Debugging Compatibility Issues

#### Version Mismatch Errors

```bash
# Clear caches
npx react-native start --reset-cache

# Reinstall dependencies
rm -rf node_modules
npm install

# iOS: Reinstall pods
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# Android: Clean build
cd android
./gradlew clean
cd ..
```

#### Native Module Errors

```
NativeModule: ContentsquareModule is null
```

**Possible causes**:

1. iOS: CocoaPods not installed
2. Android: Gradle plugin not applied
3. Metro bundler cache issue

**Resolution**:

```bash
# iOS
cd ios && pod install && cd ..

# Android
cd android && ./gradlew clean && ./gradlew assembleDebug

# Restart Metro with clean cache
npx react-native start --reset-cache
```

## Testing Compatibility

### Verification Checklist

After installation, verify:

- [ ] SDK initializes without errors
- [ ] Console logs show SDK version: `[INFO] CSQ {version} is attempting to start`
- [ ] Screen tracking works (check logs for screen events)
- [ ] Session Replay captures views (test in-app features)
- [ ] Consent flow works (`optIn()` / `optOut()`)
- [ ] Autocapture instruments components (if enabled)
- [ ] Source maps upload successfully (if using Error Analysis)

### Platform-Specific Tests

**iOS**:

```bash
# Run iOS app
npx react-native run-ios

# Check logs
npx react-native log-ios | grep "CSLIB"
```

**Android**:

```bash
# Run Android app
npx react-native run-android

# Check logs
npx react-native log-android | grep "CSLIB"
```

## Additional Resources

- [React Native Versions](https://reactnative.dev/versions)
- [Expo EAS Documentation](https://docs.expo.dev/eas/)
- [Android SDK Docs](https://docs.contentsquare.com/en/android/)
- [iOS SDK Docs](https://docs.contentsquare.com/en/ios/)
- [React Native Bridge Changelog](https://docs.contentsquare.com/en/react-native/changelog/)

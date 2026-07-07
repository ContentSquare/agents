# In-App Features

This document covers debugging and testing capabilities embedded in the Contentsquare SDK for React Native apps.

## Table of Contents

- [Overview](#overview)
- [Android Setup](#android-setup)
- [iOS Setup](#ios-setup)
- [Enabling In-App Features](#enabling-in-app-features)
- [Debugging and Logging](#debugging-and-logging)
- [Screenshot Capture](#screenshot-capture)
- [Troubleshooting](#troubleshooting)

## Overview

The Contentsquare SDK includes in-app features for testing and debugging:

- **SDK Logs**: View event data and SDK activity
- **Screenshot Capture**: Capture app screens for Zoning Analysis
- **Log Visualizer**: View logs directly on the Contentsquare platform
- **Session Replay Testing**: Verify Session Replay captures

### Platform Differences

| Feature                 | Android                | iOS                                    |
| ----------------------- | ---------------------- | -------------------------------------- |
| **Setup Required**      | None                   | Custom URL scheme + deeplink handling  |
| **Activation Method**   | QR code or ADB command | QR code, deeplink, or Terminal command |
| **Background Launch**   | Required               | Not required                           |
| **Code Implementation** | Automatic              | Manual deeplink handler                |

## Android Setup

### Prerequisites

**Your app must be running in the background** before enabling in-app features:

1. Launch your app
2. Press the Android home button
3. Follow activation method below

### Activation Methods

#### Method 1: QR Code (Physical Device)

1. Access the Contentsquare platform
2. Open the in-app features modal from the menu
3. Scan the QR code with your phone

**QR Code Reader Options**:

- Built-in camera app QR reader (if supported)
- [QR & Barcode Reader by TeaCapps](https://play.google.com/store/apps/details?id=com.teacapps.barcodescanner)

#### Method 2: ADB Command (Emulator)

1. Access the Contentsquare platform
2. Open the in-app features modal
3. Select "Copy this ADB command"

```bash
adb shell am start -W -a android.intent.action.VIEW -d "cs-{{packageName}}://contentsquare.com?activationKey={{uniqueActivationKey}}&userId={{userId}}"
```

Replace placeholders:

- `{{packageName}}`: Your app's package name (e.g., `com.example.app`)
- `{{uniqueActivationKey}}`: Provided by Contentsquare
- `{{userId}}`: Your user ID

**If you don't have platform access**: Request the activation link from the Contentsquare team.

### Android Configuration

No code changes required - in-app features are handled automatically by the native Android SDK.

## iOS Setup

iOS requires manual setup to handle deeplinks for in-app features.

### Step 1: Add Custom URL Scheme

Add the custom URL scheme to your app's `Info.plist` file.

#### Option A: Using Xcode

1. Open your project settings in Xcode
2. Select your app target
3. Navigate to the **Info** tab
4. Scroll to **URL Types**
5. Add a new URL Type:
   - **URL Schemes**: `cs-$(PRODUCT_BUNDLE_IDENTIFIER)`

#### Option B: Using Text Editor

Open `ios/YourApp/Info.plist` and add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>cs-$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        </array>
    </dict>
</array>
```

**Example**: If your bundle ID is `com.example.app`, the URL scheme will be `cs-com.example.app://`

### Step 2: Handle Deeplinks in React Native

Use React Native's `Linking` API to handle deeplinks:

```typescript
import { useEffect } from 'react';
import { Linking } from 'react-native';
import { CSQ } from '@contentsquare/react-native-bridge';

function App() {
  useEffect(() => {
    // Handle deeplink when app is launched via deeplink
    const handleInitialUrl = async () => {
      const initialUrl = await Linking.getInitialURL();
      if (initialUrl) {
        CSQ.handleUrl(initialUrl);
      }
    };

    handleInitialUrl();

    // Listen for deeplinks while app is running
    const subscription = Linking.addEventListener('url', (event: { url: string }) => {
      CSQ.handleUrl(event.url);
    });

    return () => {
      subscription.remove();
    };
  }, []);

  return <YourApp />;
}

export default App;
```

**Key Points**:

- `getInitialURL()`: Handles deeplink when app is **launched** (cold start)
- `addEventListener('url', ...)`: Handles deeplink when app is **already running**
- `CSQ.handleUrl(url)`: Forwards the deeplink to the SDK

### Alternative: Native iOS Implementation

If you prefer native implementation, see the [iOS SDK documentation](https://docs.contentsquare.com/en/ios/) for AppDelegate setup.

## Enabling In-App Features

Once setup is complete, activate in-app features using one of these methods:

### Method 1: QR Code (Physical Device)

**Both Android and iOS**:

1. Access the Contentsquare platform
2. Open the in-app features modal from the menu
3. Scan the QR code with your device's camera

### Method 2: Deeplink (iOS Simulator)

**iOS Only**:

1. Access the Contentsquare platform
2. Open the in-app features modal
3. Select "Copy link" to copy the deeplink
4. Open Safari on your iOS Simulator
5. Paste and navigate to the link

**Deeplink Format**:

```
cs-com.example.app://contentsquare.com?activationKey=XXXXX&userId=XXXXX
```

### Method 3: Terminal Command (iOS Simulator)

**iOS Only**:

Open a terminal and run:

```bash
xcrun simctl openurl booted "cs-com.example.app://contentsquare.com?activationKey=XXXXX&userId=XXXXX"
```

Replace `CUSTOM_LINK` with your actual deeplink from the Contentsquare platform.

### Method 4: ADB Command (Android Emulator)

**Android Only**:

```bash
adb shell am start -W -a android.intent.action.VIEW -d "cs-com.example.app://contentsquare.com?activationKey=XXXXX&userId=XXXXX"
```

## Debugging and Logging

### Default Logging

By default, only the SDK start log is visible:

```text
[INFO] CSQ 6.1.0 is attempting to start Digital eXperience Analytics.
```

### Enabling Full Logs

**Logs are automatically enabled when in-app features are activated.**

- **Starts**: When in-app features are enabled
- **Stops**: When in-app features are disabled

### Viewing Local Logs

#### iOS (Xcode Console)

```bash
# Run your app from Xcode and view the console
# Look for logs prefixed with "CSLIB" or "CSQ"
```

**Example logs**:

```text
CSLIB ℹ️ Info: CSQ 6.1.0 is attempting to start Digital eXperience Analytics.
CSLIB ℹ️ Info: Screen tracked: HomeScreen
CSLIB ℹ️ Info: Transaction tracked: order_123
```

#### iOS (macOS Console App)

1. Open **Console.app** on macOS
2. Connect your device or simulator
3. Filter by your app name or "CSLIB"

#### Android (Logcat)

```bash
# View logs in Android Studio Logcat
# Or use adb logcat
adb logcat | grep "CSLIB"
```

**Example logs**:

```text
I/CSLIB: CSQ 6.1.0 is attempting to start Digital eXperience Analytics.
I/CSLIB: Screen tracked: HomeScreen
I/CSLIB: Transaction tracked: order_123
```

### Viewing Logs on Contentsquare Platform

**SDK Log Visualizer** allows viewing logs directly on the platform:

**Requirements**:

- Platform access for your project
- In-app features enabled on your device

**How to Use**:

1. Enable in-app features on your device
2. Navigate to the Log Visualizer on the Contentsquare platform
3. View real-time logs from your device

See [SDK Log Visualizer Help Center Article](https://support.contentsquare.com/hc/en-us/articles/37271699876625) for details.

### Log Types

| Log Type    | Purpose                 | Example                          |
| ----------- | ----------------------- | -------------------------------- |
| **Info**    | General SDK activity    | SDK start, screen tracking       |
| **Warning** | Non-critical issues     | Missing screen name              |
| **Error**   | Critical issues         | API errors, configuration errors |
| **Debug**   | Detailed debugging info | Event payloads, network requests |

### Filtering Logs

**iOS (Console App)**:

```
Subsystem: CSLIB
Category: Analytics, SessionReplay, etc.
```

**Android (Logcat)**:

```bash
# Filter by tag
adb logcat CSLIB:I *:S

# Filter by message
adb logcat | grep "Screen tracked"
```

## Screenshot Capture

Screenshot capture enables Zoning Analysis on the Contentsquare platform.

### Prerequisites

**Critical**: For screenshot capture to work:

1. ✅ Session must be tracked (user opted in)
2. ✅ At least one screenview event sent
3. ✅ In-app features enabled

```typescript
import { CSQ } from "@contentsquare/react-native-bridge";

// 1. User opts in
CSQ.optIn();

// 2. Track a screen
CSQ.trackScreenview("HomeScreen");

// 3. Enable in-app features (via QR code/deeplink)
// 4. Screenshots can now be captured
```

### How to Capture Screenshots

1. **Enable in-app features** on your device
2. **Navigate to the screen** you want to capture
3. **Open the in-app features menu** (appears after enabling)
4. **Tap "Capture Screenshot"**

The screenshot is uploaded to the Contentsquare platform and becomes available in **Zoning Analysis**.

### Using Screenshots in Zoning Analysis

Screenshots enable zone-level metrics:

- **Tap rate**: Where users tap on the screen
- **Swipe rate**: Where users swipe
- **Exposure rate**: Which zones are viewed
- **Attention time**: How long zones are viewed

### Screenshot Best Practices

1. **Capture representative screens**: Capture screens in their typical state (with real data, not placeholders)
2. **Capture all states**: Capture screens with different content (empty states, loaded states, error states)
3. **Use test accounts**: Never capture screens with real user PII (emails, names, addresses)
4. **Capture after UI changes**: Re-capture when screen layouts change
5. **Verify masking**: Ensure sensitive content is properly masked in Session Replay

### Screenshot Limitations

- **Manual process**: Screenshots are not captured automatically from end users
- **Device-specific**: Screenshots must be captured from a device/simulator with in-app features enabled
- **Requires screenview**: A screenview event must be sent before screenshots can be captured
- **Privacy**: Only capture screenshots with test accounts, never with real user data

## Troubleshooting

### In-App Features Not Activating

#### Android

**Issue**: QR code scan or ADB command doesn't activate in-app features

**Solutions**:

1. **Verify app is in background**:

   ```bash
   # Check if app is running
   adb shell ps | grep com.example.app
   ```

2. **Check package name**:

   ```bash
   # Verify package name matches
   adb shell pm list packages | grep com.example.app
   ```

3. **Test ADB command manually**:

   ```bash
   adb shell am start -W -a android.intent.action.VIEW -d "cs-com.example.app://contentsquare.com?activationKey=XXXXX&userId=XXXXX"
   ```

4. **Check SDK version**:
   ```typescript
   import { CSQ } from "@contentsquare/react-native-bridge";
   // Check logs for SDK version
   ```

#### iOS

**Issue**: Deeplink doesn't activate in-app features

**Solutions**:

1. **Verify URL scheme in Info.plist**:

   ```bash
   # Check Info.plist
   cat ios/YourApp/Info.plist | grep "CFBundleURLSchemes" -A 2
   ```

   Should show: `<string>cs-$(PRODUCT_BUNDLE_IDENTIFIER)</string>`

2. **Test deeplink handling**:

   ```typescript
   import { Linking } from "react-native";

   // Add debug logging
   Linking.addEventListener("url", event => {
     console.log("Received URL:", event.url);
     CSQ.handleUrl(event.url);
   });
   ```

3. **Verify bundle identifier**:

   ```bash
   # Check bundle ID in Xcode project settings
   # Should match URL scheme (cs-com.example.app)
   ```

4. **Test with xcrun (simulator)**:
   ```bash
   xcrun simctl openurl booted "cs-com.example.app://contentsquare.com?activationKey=test&userId=test"
   ```

### Logs Not Appearing

**Issue**: No logs visible after enabling in-app features

**Solutions**:

1. **Verify in-app features are enabled**:
   - Check for confirmation message on device
   - Verify in-app features menu appears

2. **Check log filtering**:

   ```bash
   # iOS
   xcrun simctl spawn booted log stream --predicate 'subsystem == "CSLIB"'

   # Android
   adb logcat | grep -i "cslib\|contentsquare"
   ```

3. **Restart app after enabling**:
   - Some logs may only appear after app restart

4. **Check SDK initialization**:
   ```typescript
   CSQ.start(StartConfig.dxa());
   CSQ.optIn();
   ```

### Screenshots Not Capturing

**Issue**: Screenshot capture fails or is unavailable

**Solutions**:

1. **Verify prerequisites**:

   ```typescript
   // Ensure all prerequisites are met
   CSQ.optIn(); // 1. Opt in
   CSQ.trackScreenview("TestScreen"); // 2. Track screen
   // 3. Enable in-app features
   ```

2. **Check session tracking**:

   ```typescript
   // Verify user is not opted out
   CSQ.optIn();
   ```

3. **Send screenview event**:

   ```typescript
   // Ensure screen is tracked before capture
   CSQ.trackScreenview("CurrentScreen");
   ```

4. **Check network connectivity**:
   - Screenshots require network to upload
   - Verify device has internet access

### Deeplink Handler Not Called (iOS)

**Issue**: `CSQ.handleUrl()` is never called

**Solutions**:

1. **Check Linking setup**:

   ```typescript
   import { Linking } from "react-native";

   useEffect(() => {
     // Log all deeplinks for debugging
     const subscription = Linking.addEventListener("url", event => {
       console.log("Deeplink received:", event.url);
       CSQ.handleUrl(event.url);
     });

     return () => subscription.remove();
   }, []);
   ```

2. **Test initial URL handling**:

   ```typescript
   useEffect(() => {
     Linking.getInitialURL().then(url => {
       console.log("Initial URL:", url);
       if (url) CSQ.handleUrl(url);
     });
   }, []);
   ```

3. **Verify URL scheme registration**:
   - Open Safari on simulator
   - Enter: `cs-com.example.app://test`
   - Should prompt to open your app

### Platform-Specific Issues

#### Android: ADB "Activity not started"

```bash
Error: Activity not started, unable to resolve Intent
```

**Solution**: Verify package name and ensure app is installed:

```bash
adb shell pm list packages | grep com.example.app
```

#### iOS: "No app registered for URL scheme"

**Solution**: Clean and rebuild the app:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
npx react-native run-ios
```

## Additional Resources

- [React Native Linking Documentation](https://reactnative.dev/docs/linking)
- [Contentsquare WebView Tracking](https://docs.contentsquare.com/en/webview-tracking-tag/)
- [SDK Log Visualizer Help Center](https://support.contentsquare.com/hc/en-us/articles/37271699876625)
- [iOS SDK Documentation](https://docs.contentsquare.com/en/ios/)
- [Android SDK Documentation](https://docs.contentsquare.com/en/android/)

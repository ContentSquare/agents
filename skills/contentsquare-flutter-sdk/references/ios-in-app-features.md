# iOS In-App Features Setup

To use Contentsquare in-app features on iOS (screenshot capture, SDK logs, Log Visualizer, Zoning Analysis), **native iOS configuration** is required. This is one of the few cases where editing native files is necessary and allowed.

## What in-app features enable

- **Screenshot capture**: Allows Contentsquare users to capture screenshots for Zoning Analysis (zone-level metrics like tap rate, swipe rate)
- **SDK Logs**: View raw event data in Xcode, macOS Console, or the Contentsquare platform for validation during instrumentation
- **Log Visualizer**: View logs directly on the Contentsquare platform without external tools

## Step 1: Add the custom URL scheme in Info.plist

The app must be opened via a custom URL scheme.

**Using Xcode:**

1. Open the project settings
2. Select the app target
3. Select the `Info` settings
4. Scroll to `URL Types`
5. Set the URL scheme to `cs-$(PRODUCT_BUNDLE_IDENTIFIER)`

**Using a text editor (add to `ios/Runner/Info.plist`):**

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

**Important**: Insert this before the closing `</dict>` tag at the end of the plist. If `CFBundleURLTypes` already exists, add the new `<dict>` entry to the existing `<array>`.

## Step 2: Handle the deeplink in AppDelegate

Call the SDK when the app is opened via deeplink. The implementation depends on the app's architecture:

### For AppDelegate-based apps (most Flutter apps)

Add or update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import ContentsquareSDK

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Add this method for Contentsquare in-app features
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    CSQ.handle(url: url)
    return super.application(app, open: url, options: options)
  }
}
```

### For SceneDelegate-based apps

If the app uses scenes (check for `SceneDelegate.swift`), add to `ios/Runner/SceneDelegate.swift`:

```swift
import UIKit
import ContentsquareSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    if let url = URLContexts.first?.url {
      CSQ.handle(url: url)
    }
  }
}
```

### For SwiftUI apps (iOS 14+)

If the app uses pure SwiftUI with `@main` App struct:

```swift
import SwiftUI
import ContentsquareSDK

@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .onOpenURL { url in
          CSQ.handle(url: url)
        }
    }
  }
}
```

## Enabling in-app features

Once configured, in-app features can be enabled by:

### 1. Scanning QR code (physical device)

From the Contentsquare platform menu, scan the displayed QR code with the device.

### 2. Custom link (simulator)

Copy the deeplink from the Contentsquare platform and paste it in Safari on the Simulator.

### 3. Terminal command (simulator)

```bash
xcrun simctl openurl booted "CUSTOM_LINK"
```

Replace `CUSTOM_LINK` with the actual deeplink from the Contentsquare platform.

## Debugging with logs

By default, only one startup log is visible:

```
CSLIB ℹ️ Info: Contentsquare SDK vX.X.X starting in app: {{bundleID}}
```

To enable all logs, activate in-app features. Logs appear when in-app features are enabled and stop when disabled.

**To view logs:**

1. Connect the device to Mac (or use same Wi-Fi for wireless debugging)
2. Open macOS Console app (enable Info messages via Action > Include Info Messages) or Xcode
3. Filter logs on `CSLIB`

## Verifying the setup

After completing the setup:

1. Build and run the app on a device or simulator
2. Enable in-app features using one of the methods above
3. You should see a Contentsquare overlay appear in the app
4. Check the console for `CSLIB` logs to verify the SDK is receiving events

## Troubleshooting

| Issue                           | Solution                                                                                                           |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| Deeplink doesn't open the app   | Verify the URL scheme in `Info.plist` matches `cs-$(PRODUCT_BUNDLE_IDENTIFIER)`. Check bundle identifier in Xcode. |
| No overlay appears              | Ensure `CSQ.handle(url:)` is called in the correct lifecycle method. Check console for errors.                     |
| `ContentsquareModule` not found | Run `pod install` in the `ios/` directory. Ensure the Contentsquare Flutter plugin is properly installed.          |
| Logs not appearing              | Ensure in-app features are enabled. Check Console app filter settings (include Info messages).                     |

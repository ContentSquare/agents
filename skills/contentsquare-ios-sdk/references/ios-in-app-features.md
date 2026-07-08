# iOS In-App Features

Alongside its tracking capabilities, the SDK embeds features aimed at Contentsquare users such as Screenshot Capture and SDK Logs.

## What in-app features enable

- **Screenshot capture**: Allows Contentsquare users to capture screenshots for Zoning Analysis (zone-level metrics like tap rate, swipe rate). Screenshots are only taken by Contentsquare users on their device — not from end-user devices.
- **SDK Logs**: View raw event data in Xcode, macOS Console, or the Contentsquare platform for validation during the instrumentation phase.
- **Log Visualizer**: View logs directly on the Contentsquare platform without external logging tools.

## Implement in-app features

To allow Contentsquare users to enable in-app features, two implementation tasks are required:

1. Add the custom URL scheme in your app Info
2. Call the SDK when the app is launched via a deeplink

### Step 1: Add the custom URL scheme in your app Info

The app must be opened via a custom URL scheme.

**Using Xcode:**

1. Open the project settings
2. Select the app target
3. Select the `Info` settings
4. Scroll to `URL Types`
5. Set the URL scheme to `cs-$(PRODUCT_BUNDLE_IDENTIFIER)`

**Using a text editor (add to `Info.plist`):**

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

If `CFBundleURLTypes` already exists, add the new `<dict>` entry to the existing `<array>`.

### Step 2: Call the SDK when the app is launched via a deeplink

Depending on the project structure, there are multiple ways to handle the deeplink opening. Choose the method matching your project:

#### AppDelegate

In your `AppDelegate` class, complete or implement `application(_:open:options:)` with `CSQ.handle(url: url)`:

```swift
import UIKit
import ContentsquareSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    CSQ.handle(url: url)
    return true
  }
}
```

#### SceneDelegate

In your `SceneDelegate` class, implement `scene(_:openURLContexts:)`:

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

#### SwiftUI

In your `App` struct, use the `.onOpenURL` modifier:

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

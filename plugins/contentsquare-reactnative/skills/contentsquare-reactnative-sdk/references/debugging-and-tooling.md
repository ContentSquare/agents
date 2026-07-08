# React Native Debugging and Tooling

This document covers React Native-specific development tools and debugging workflows for the Contentsquare SDK.

## Table of Contents

- [Autocapture Setup](#autocapture-setup)
- [Source Maps and Crash Symbolication](#source-maps-and-crash-symbolication)
- [CLI Configuration](#cli-configuration)
- [Build Integration](#build-integration)
- [Troubleshooting](#troubleshooting)

## Autocapture Setup

### Overview

Autocapture enables automatic tracking of user interactions and screenviews without manual instrumentation. It requires the Contentsquare Babel plugin to instrument your React Native code.

### Babel Plugin Configuration

Add the Autocapture plugin to your Babel configuration:

**babel.config.js**

```javascript
module.exports = {
  presets: ["module:@react-native/babel-preset"],
  plugins: ["@contentsquare/react-native-bridge/babel"],
};
```

**Monorepo setup**: If your project uses a monorepo structure (Yarn Workspaces, pnpm, Lerna, Nx, Turborepo, etc.), make sure to add the plugin to **all relevant `babel.config.js` files** in your project, including those in any packages that contain React Native code.

**Important**: The Autocapture Babel plugin depends on `@babel/plugin-transform-react-display-name` to include component names in interaction events. This is typically provided by:

- `module:metro-react-native-babel-preset`
- `babel-preset-expo`
- `@react-native/babel-preset`

If you're not using any of these presets, add `@babel/plugin-transform-react-display-name` alongside the Contentsquare plugin:

```javascript
module.exports = {
  presets: ["@babel/preset-react"],
  plugins: [
    "@babel/plugin-transform-react-display-name",
    "@contentsquare/react-native-bridge/babel",
  ],
};
```

### Enable Autocapture

Enable autocapture when configuring Product Analytics:

```typescript
import { CSQ, StartConfig } from "@contentsquare/react-native-bridge";

useEffect(() => {
  CSQ.start(
    StartConfig.withEnvironmentId("YOUR_ENVIRONMENT_ID", {
      enableRNAutocapture: true,
    }),
  );
}, []);
```

### What Gets Autocaptured

With autocapture enabled, the SDK automatically tracks:

#### Interaction Events

- **Touch events**: Tap, long press, double tap
- **Gesture handling**: Swipes, pinches (see PanResponder limitations in [compatibility guide](compatibility.md))
- **Button presses**: All Touchable components (TouchableOpacity, TouchableHighlight, Pressable, Button)
- **Custom components**: Components with display names instrumented by the Babel plugin

#### Change Events

- **Text input**: TextInput value changes
- **Switches**: Switch/Toggle component state changes
- **Pickers**: Picker/Select value changes
- **Sliders**: Slider value changes
- **Checkboxes**: Checkbox state changes

#### Screen Events

- **Navigation events**: Screen transitions in React Navigation
- **Modal appearances**: Modal component visibility changes
- **Tab changes**: Tab navigator tab switches

#### Captured Properties

For each autocaptured event, the SDK collects:

- **Component name**: Display name from `@babel/plugin-transform-react-display-name`
- **Component hierarchy**: Parent component chain
- **Interaction type**: tap, change, swipe, etc.
- **Target element**: Text, accessibility label, or component type
- **Timestamp**: Event occurrence time
- **Screen context**: Current screen/route name

#### Text Capture

By default, text content is captured for interactions. To mask sensitive text:

```typescript
// Disable text capture globally
CSQ.start(StartConfig.withEnvironmentId('YOUR_ENVIRONMENT_ID', {
  enableRNAutocapture: true,
  disableInteractionTextCapture: true, // iOS only
}));

// Or mask specific components
import { CSQMask } from '@contentsquare/react-native-bridge';

<CSQMask isSessionReplayMasked={true} allowText={false}>
  <TextInput placeholder="Password" secureTextEntry />
</CSQMask>;
```

### Autocapture Compatibility

**Supported React Native Versions**: >= 0.71.0

**Navigation Library Compatibility**:

- ✅ React Navigation: 5.0 and later
- ✅ React Native Navigation: 7.0 and later

**Platform Support**:

- ✅ Android: Full support
- ✅ iOS: Full support
- ❌ Web: Not supported
- ❌ Expo Go: Not supported (use `expo run:android` or `expo run:ios`)

**Expo Configuration**:

For Expo projects, ensure the plugin is configured in **app.json**:

```json
{
  "expo": {
    "plugins": ["@contentsquare/react-native-bridge"]
  }
}
```

And use Expo-compatible Babel config in **babel.config.js**:

```javascript
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ["babel-preset-expo"],
    plugins: ["@contentsquare/react-native-bridge/babel"],
  };
};
```

### Verifying Autocapture

After enabling autocapture, verify it's working:

1. **Check console logs**:

   ```
   [INFO] CSQ 1.4.1 is attempting to start Product Analytics.
   ```

2. **Test interactions**:

   - Tap buttons and verify events in Contentsquare dashboard
   - Fill form fields and check change events
   - Navigate screens and verify screen events

3. **Enable verbose logging**:

   ```typescript
   import { CSQ, LogLevel } from "@contentsquare/react-native-bridge";

   CSQ.setLogLevel(LogLevel.verbose);
   CSQ.logToConsole();
   ```

### Experience Analytics + Product Analytics

When using both Experience Analytics and Product Analytics, pass PA options via `StartConfig.withDataSourceId`:

```typescript
CSQ.start(
  StartConfig.withDataSourceId("YOUR_DATA_SOURCE_ID", {
    enableRNAutocapture: true,
    disablePageviewAutocapture: true, // Screen tracking handled by Experience Analytics
  }),
);
```

## Source Maps and Crash Symbolication

### Overview

Source maps enable readable stack traces for JavaScript crashes in production builds. The Contentsquare CLI automates source map generation and upload.

### Prerequisites

**Install the Contentsquare CLI**:

The CLI is available as an npm package:

```bash
# Using Yarn
yarn add @contentsquare/react-native-cli --dev

# Using npm
npm install @contentsquare/react-native-cli --save-dev
```

### Android Source Map Configuration

#### 1. Enable Hermes Source Maps

Configure Hermes to generate source maps in **android/app/build.gradle**:

```groovy
apply plugin: "com.contentsquare.error.analysis.crash"
apply from: "../../node_modules/@contentsquare/react-native-cli/scripts/contentsquare.gradle"

react {
  // Ensure the following hermesFlags are present
  hermesFlags = ['-O', '-output-source-map']
}

ext {
  contentsquareConfigPath = "../contentsquare-cli.json" // default
}
```

#### 2. Source Map Path

The default source map path for Android is:

```
./android/app/build/generated/sourcemaps/react/release/index.android.bundle.map
```

Use this path in your CLI configuration's `sourcemapPath` field for Android.

### iOS Source Map Configuration

#### 1. Update Build Phase Script

Modify the "Bundle React Native code and images" build phase in Xcode:

```bash
export SOURCEMAP_FILE="$SRCROOT/main.jsbundle.map"
WITH_ENVIRONMENT="$REACT_NATIVE_PATH/scripts/xcode/with-environment.sh"
REACT_NATIVE_XCODE="$REACT_NATIVE_PATH/scripts/react-native-xcode.sh";
export CONTENTSQUARE_CONFIG_PATH="$SRCROOT/../contentsquare-cli.json"
CONTENTSQUARE_XCODE="$SRCROOT/../node_modules/@contentsquare/react-native-cli/scripts/contentsquare-xcode.sh"

/bin/sh -c "$WITH_ENVIRONMENT $REACT_NATIVE_XCODE"
/bin/sh -c "$WITH_ENVIRONMENT $CONTENTSQUARE_XCODE"
```

#### 2. Source Map Path

The default source map path for iOS is:

```
./ios/main.jsbundle.map
```

Use this path in your CLI configuration's `sourcemapPath` field for iOS.

## CLI Configuration

### Configuration File

Create a **contentsquare-cli.json** file at your project root:

```json
{
  "android": {
    "clientId": "YOUR_ANDROID_CLIENT_ID",
    "clientSecret": "YOUR_ANDROID_CLIENT_SECRET",
    "projectId": "YOUR_ANDROID_PROJECT_ID",
    "sourcemapPath": "./android/app/build/generated/sourcemaps/react/release/index.android.bundle.map"
  },
  "ios": {
    "clientId": "YOUR_IOS_CLIENT_ID",
    "clientSecret": "YOUR_IOS_CLIENT_SECRET",
    "projectId": "YOUR_IOS_PROJECT_ID",
    "sourcemapPath": "./ios/main.jsbundle.map"
  }
}
```

**Add to .gitignore**:

```bash
echo "contentsquare-cli.json" >> .gitignore
echo "contentsquare-sourcemap-info.json" >> .gitignore
```

### Finding Your Credentials

**Project ID**:

1. Log in to [https://app.contentsquare.com](https://app.contentsquare.com)
2. Select your project
3. Find the project ID in the URL: `https://app.contentsquare.com/#/{MODULE}?project={PROJECT_ID}&hash={HASH}`

**API Credentials (Client ID and Secret)**:

Follow the Help Center guide: [How to create API credentials](https://support.contentsquare.com/hc/en-us/articles/37271728104593)

### CLI Commands

The Contentsquare CLI provides two main commands:

#### Update Source Map ID

Generates or updates the source map ID file:

```bash
npx contentsquare-cli update-sourcemap-id
```

This creates or updates **contentsquare-sourcemap-info.json** with source map IDs for both platforms.

#### Upload Source Maps

Uploads source maps to Contentsquare servers:

```bash
npx contentsquare-cli upload-sourcemaps
```

### Command Line Options

Override configuration file settings with command line arguments:

| Option             | Description                                                    |
| ------------------ | -------------------------------------------------------------- |
| `--client-id`      | API client ID                                                  |
| `--client-secret`  | API client secret                                              |
| `--config`         | Path to configuration file (default: `contentsquare-cli.json`) |
| `--help`           | Display help message                                           |
| `--platform`       | Target platform: `ios` or `android`                            |
| `--project-id`     | Contentsquare project ID                                       |
| `--sourcemap-path` | Path to source map file                                        |
| `--uploadUrl`      | Contentsquare platform URL (default: `https://api.csq.io`)     |
| `--verbose`        | Display verbose output                                         |

**Example**:

```bash
npx contentsquare-cli upload-sourcemaps \
  --platform ios \
  --project-id YOUR_PROJECT_ID \
  --client-id YOUR_CLIENT_ID \
  --client-secret YOUR_CLIENT_SECRET \
  --sourcemap-path ./ios/main.jsbundle.map
```

Command line arguments override configuration file values.

## Build Integration

### Automatic Source Map Upload

The build scripts automatically trigger the CLI during compilation:

**Android**: The `contentsquare.gradle` script runs `update-sourcemap-id` during the build process.

**iOS**: The `contentsquare-xcode.sh` script runs `update-sourcemap-id` during the Xcode build phase.

### Manual Upload Workflow

For CI/CD or manual upload scenarios:

1. **Generate Source Map ID**:

   ```bash
   npx contentsquare-cli update-sourcemap-id
   ```

2. **Build Your Release**:

   ```bash
   # Android
   cd android && ./gradlew assembleRelease

   # iOS
   xcodebuild -workspace ios/YourApp.xcworkspace -scheme YourApp -configuration Release
   ```

3. **Upload Source Maps**:
   ```bash
   npx contentsquare-cli upload-sourcemaps
   ```

**Critical**: Execute these steps in order to ensure correct crash symbolication.

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: Build and Upload Source Maps

on:
  push:
    branches: [main, release/*]

jobs:
  build:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install dependencies
        run: yarn install

      - name: Generate Source Map ID
        run: npx contentsquare-cli update-sourcemap-id

      - name: Build iOS
        run: |
          cd ios && pod install
          xcodebuild -workspace YourApp.xcworkspace -scheme YourApp -configuration Release

      - name: Upload Source Maps
        env:
          CSQ_CLIENT_ID: ${{ secrets.CSQ_CLIENT_ID }}
          CSQ_CLIENT_SECRET: ${{ secrets.CSQ_CLIENT_SECRET }}
        run: |
          npx contentsquare-cli upload-sourcemaps \
            --platform ios \
            --client-id $CSQ_CLIENT_ID \
            --client-secret $CSQ_CLIENT_SECRET
```

## Troubleshooting

### Autocapture Not Working

**Check Babel Plugin**:

Verify the plugin is listed in your Babel configuration:

```bash
# Test Babel transformation
npx babel src/MyComponent.js
```

**Check Console Logs**:

Look for Autocapture initialization messages:

```
[INFO] CSQ 1.4.1 is attempting to start Product Analytics.
```

**Verify Configuration**:

Ensure `enableRNAutocapture: true` is set:

```typescript
CSQ.start(
  StartConfig.withEnvironmentId("ENV_ID", {
    enableRNAutocapture: true,
  }),
);
```

### Source Map Upload Failures

**Verify CLI Installation**:

```bash
npx contentsquare-cli --help
```

**Check Configuration**:

Validate your **contentsquare-cli.json** syntax:

```bash
cat contentsquare-cli.json | python -m json.tool
```

**Verify Source Map Exists**:

```bash
# Android
ls -lh android/app/build/generated/sourcemaps/react/release/

# iOS
ls -lh ios/main.jsbundle.map
```

**Enable Verbose Output**:

```bash
npx contentsquare-cli upload-sourcemaps --verbose
```

**Check API Credentials**:

Verify your client ID and secret are correct by testing authentication:

```bash
curl -X POST https://api.csq.io/v1/auth \
  -H "Content-Type: application/json" \
  -d '{"clientId":"YOUR_CLIENT_ID","clientSecret":"YOUR_CLIENT_SECRET"}'
```

### JavaScript Crashes Not Symbolicated

**Verify Upload Timing**:

Source maps must be uploaded BEFORE crashes are reported. Follow the manual workflow:

1. Generate source map ID
2. Build release
3. Upload source maps
4. Deploy app

**Check Source Map ID**:

Inspect **contentsquare-sourcemap-info.json** to verify IDs are generated:

```bash
cat contentsquare-sourcemap-info.json
```

**Verify Platform Match**:

Ensure the source map path and platform match your build configuration:

- Android: `index.android.bundle.map`
- iOS: `main.jsbundle.map`

### Build Script Issues

**Android Gradle Error**:

If the Contentsquare Gradle script fails:

```bash
cd android
./gradlew clean
./gradlew assembleRelease --stacktrace
```

**iOS Xcode Build Phase Error**:

Check the "Bundle React Native code and images" build phase:

1. Open Xcode
2. Select your target
3. Navigate to Build Phases
4. Expand "Bundle React Native code and images"
5. Verify script paths are correct

**Metro Bundler Conflicts**:

If source maps aren't generated:

```bash
# Clear Metro cache
npx react-native start --reset-cache

# Rebuild
cd android && ./gradlew clean assembleRelease
```

### EU Region Configuration

If your Product Analytics environment is hosted in the EU, configure the base URL:

```typescript
CSQ.start(
  StartConfig.withEnvironmentId("YOUR_ENVIRONMENT_ID", {
    enableRNAutocapture: true,
    baseUrl: "https://mh.ba.contentsquare.net",
  }),
);
```

And in **contentsquare-cli.json**:

```json
{
  "android": {
    "uploadUrl": "https://api.eu.csq.io",
    ...
  }
}
```

## Additional Resources

- [React Native Debugging Documentation](https://reactnative.dev/docs/debugging-release-builds)
- [Contentsquare Error Analysis Guide](https://docs.contentsquare.com/en/csq-sdk-react-native/experience-analytics/error-analysis/)
- [API Credentials Setup](https://support.contentsquare.com/hc/en-us/articles/37271728104593)
- [Product Analytics Getting Started](https://docs.contentsquare.com/en/csq-sdk-react-native/product-analytics/)

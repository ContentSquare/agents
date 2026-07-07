# WebView Tracking

This document covers WebView integration with the Contentsquare SDK for React Native apps.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Web Page Configuration](#web-page-configuration)
- [Migration from Legacy API](#migration-from-legacy-api)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)

## Overview

WebView tracking enables session stitching between native React Native content and web content displayed in WebViews. This creates a unified session across both native and web experiences.

### What Gets Tracked

With WebView tracking enabled:

- ✅ **Web interactions**: Clicks, scrolls, form inputs on web pages
- ✅ **Web page views**: Page navigation within the WebView
- ✅ **Session continuity**: Unified session ID across native and web
- ✅ **Session Replay**: Combined replay of native and web content
- ✅ **User journey**: Complete path across native and web screens

### Supported Libraries

**Only `react-native-webview` is supported**:

- ✅ [`react-native-webview`](https://github.com/react-native-webview/react-native-webview)
- ❌ Other WebView implementations (not compatible)

Contentsquare's implementation relies on `react-native-webview` internals and is not compatible with alternative WebView libraries.

## Prerequisites

### 1. Install react-native-webview

```bash
# Using Yarn
yarn add react-native-webview

# Using npm
npm install react-native-webview
```

### 2. Install iOS Pods

```bash
cd ios && pod install && cd ..
```

### 3. Verify Contentsquare SDK

Ensure the Contentsquare SDK is installed and initialized:

```typescript
import { CSQ, StartConfig } from "@contentsquare/react-native-bridge";

CSQ.start(StartConfig.dxa());
CSQ.optIn();
```

## Quick Start

### Basic WebView Tracking

Wrap your `WebView` component with `CSQWebView`:

**Before (without tracking)**:

```typescript
import React from 'react';
import { WebView } from 'react-native-webview';

const MyWebViewScreen = () => {
  return (
    <WebView source={{ uri: 'https://www.example.com' }} />
  );
};

export default MyWebViewScreen;
```

**After (with tracking)**:

```typescript
import React from 'react';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';

const MyWebViewScreen = () => {
  return (
    <CSQWebView>
      <WebView source={{ uri: 'https://www.example.com' }} />
    </CSQWebView>
  );
};

export default MyWebViewScreen;
```

That's it! The `CSQWebView` wrapper handles JavaScript injection automatically.

### Multiple WebViews

Each WebView must be wrapped individually:

```typescript
import React from 'react';
import { View } from 'react-native';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';

const MultiWebViewScreen = () => {
  return (
    <View style={{ flex: 1 }}>
      <CSQWebView>
        <WebView
          source={{ uri: 'https://www.example.com/page1' }}
          style={{ flex: 1 }}
        />
      </CSQWebView>

      <CSQWebView>
        <WebView
          source={{ uri: 'https://www.example.com/page2' }}
          style={{ flex: 1 }}
        />
      </CSQWebView>
    </View>
  );
};

export default MultiWebViewScreen;
```

### With WebView Props

`CSQWebView` passes through all WebView props:

```typescript
import React, { useRef } from 'react';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';

const ConfiguredWebView = () => {
  const webViewRef = useRef(null);

  return (
    <CSQWebView>
      <WebView
        ref={webViewRef}
        source={{ uri: 'https://www.example.com' }}
        javaScriptEnabled={true}
        domStorageEnabled={true}
        startInLoadingState={true}
        scalesPageToFit={true}
        onLoad={() => console.log('WebView loaded')}
        onError={(syntheticEvent) => {
          const { nativeEvent } = syntheticEvent;
          console.error('WebView error: ', nativeEvent);
        }}
      />
    </CSQWebView>
  );
};

export default ConfiguredWebView;
```

## Web Page Configuration

### Step 1: Install Contentsquare Web Tracking Tag

Your web pages **must include the Contentsquare Web Tracking Tag in WebView mode**.

**Add to your HTML pages**:

```html
<!DOCTYPE html>
<html>
  <head>
    <title>My Web Page</title>

    <!-- Contentsquare Web Tracking Tag (WebView Mode) -->
    <script type="text/javascript">
      window._uxa = window._uxa || [];
      (function () {
        var cs = document.createElement("script");
        cs.type = "text/javascript";
        cs.async = true;
        cs.src = "//t.contentsquare.net/uxa/YOUR_PROJECT_ID.js";

        // WebView mode configuration
        window._uxa.push([
          "setPath",
          window.location.pathname + window.location.search,
        ]);
        window._uxa.push(["setWebViewMode", true]);

        var s = document.getElementsByTagName("script")[0];
        s.parentNode.insertBefore(cs, s);
      })();
    </script>
  </head>
  <body>
    <!-- Your content -->
  </body>
</html>
```

**Key Configuration**:

- `setWebViewMode`: **Must be set to `true`** for WebView tracking
- `YOUR_PROJECT_ID`: Replace with your Contentsquare project ID

### Step 2: Verify Web Tag Installation

Test your web page:

1. Open the web page in a desktop browser
2. Open browser DevTools Console
3. Look for Contentsquare initialization logs:
   ```javascript
   // Console should show:
   Contentsquare: WebView mode enabled
   ```

### WebView Mode vs Normal Mode

| Feature            | Normal Web Tag       | WebView Mode Tag             |
| ------------------ | -------------------- | ---------------------------- |
| **Session ID**     | Generated by web tag | Inherited from native SDK    |
| **User ID**        | Web-only             | Shared with native           |
| **Session Replay** | Web-only             | Combined native + web        |
| **Page Views**     | Web navigation       | Combined with native screens |

## Migration from Legacy API

If you're upgrading from SDK version 4.x to 6.x, migrate from `CSWebView` to `CSQWebView`.

### Legacy API (Deprecated)

**Old approach with `CSWebView`**:

```typescript
import React from 'react';
import { WebView } from 'react-native-webview';
import { CSWebView } from '@contentsquare/react-native-bridge';

const OldWebViewScreen = () => {
  return (
    <CSWebView
      url="https://www.example.com"
      renderWebView={(onLayout, webViewUrl) => {
        return (
          <WebView
            onLayout={onLayout}
            source={{ uri: webViewUrl }}
          />
        );
      }}
    />
  );
};

export default OldWebViewScreen;
```

### New API (Recommended)

**New approach with `CSQWebView`**:

```typescript
import React from 'react';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';

const NewWebViewScreen = () => {
  return (
    <CSQWebView>
      <WebView source={{ uri: 'https://www.example.com' }} />
    </CSQWebView>
  );
};

export default NewWebViewScreen;
```

### Migration Checklist

- [ ] Replace `CSWebView` imports with `CSQWebView`
- [ ] Remove `renderWebView` callback pattern
- [ ] Remove manual `onLayout` handling
- [ ] Simplify to direct `WebView` child pattern
- [ ] Test WebView tracking still works
- [ ] Verify Session Replay captures WebView content

## Advanced Configuration

### Handling WebView Navigation

Track WebView navigation events:

```typescript
import React, { useState } from 'react';
import { View, Text } from 'react-native';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';
import { CSQ } from '@contentsquare/react-native-bridge';

const NavigationTrackingWebView = () => {
  const [currentUrl, setCurrentUrl] = useState('');

  return (
    <View style={{ flex: 1 }}>
      <Text>Current URL: {currentUrl}</Text>

      <CSQWebView>
        <WebView
          source={{ uri: 'https://www.example.com' }}
          onNavigationStateChange={(navState) => {
            setCurrentUrl(navState.url);

            // Optionally track as a screen view
            if (navState.url) {
              CSQ.trackScreenview(`WebView: ${navState.title || navState.url}`);
            }
          }}
        />
      </CSQWebView>
    </View>
  );
};

export default NavigationTrackingWebView;
```

### Handling WebView Messages

Send messages between WebView and React Native:

```typescript
import React, { useRef } from 'react';
import { Button } from 'react-native';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';

const MessageHandlingWebView = () => {
  const webViewRef = useRef(null);

  // Receive messages from WebView
  const handleMessage = (event) => {
    const message = event.nativeEvent.data;
    console.log('Message from WebView:', message);

    // Process message (e.g., track custom event)
    if (message === 'checkout_completed') {
      CSQ.trackTransaction({
        price: 29.99,
        currency: Currency.USD,
        id: 'order_123'
      });
    }
  };

  // Send message to WebView
  const sendMessage = () => {
    webViewRef.current?.postMessage('Hello from React Native!');
  };

  return (
    <>
      <Button title="Send Message" onPress={sendMessage} />

      <CSQWebView>
        <WebView
          ref={webViewRef}
          source={{ uri: 'https://www.example.com' }}
          onMessage={handleMessage}
        />
      </CSQWebView>
    </>
  );
};

export default MessageHandlingWebView;
```

### Local HTML Files

Load local HTML files with Contentsquare tracking:

```typescript
import React from 'react';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';

const LocalHtmlWebView = () => {
  const html = `
    <!DOCTYPE html>
    <html>
    <head>
      <script type="text/javascript">
        window._uxa = window._uxa || [];
        (function() {
          var cs = document.createElement('script');
          cs.type = 'text/javascript';
          cs.async = true;
          cs.src = '//t.contentsquare.net/uxa/YOUR_PROJECT_ID.js';
          window._uxa.push(['setWebViewMode', true]);
          var s = document.getElementsByTagName('script')[0];
          s.parentNode.insertBefore(cs, s);
        })();
      </script>
    </head>
    <body>
      <h1>Local HTML Content</h1>
      <p>This content is tracked by Contentsquare</p>
    </body>
    </html>
  `;

  return (
    <CSQWebView>
      <WebView source={{ html }} />
    </CSQWebView>
  );
};

export default LocalHtmlWebView;
```

### Conditional Tracking

Enable/disable WebView tracking conditionally:

```typescript
import React from 'react';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';

const ConditionalTrackingWebView = ({ enableTracking = true }) => {
  if (enableTracking) {
    return (
      <CSQWebView>
        <WebView source={{ uri: 'https://www.example.com' }} />
      </CSQWebView>
    );
  }

  // Without CSQWebView wrapper - no tracking
  return <WebView source={{ uri: 'https://www.example.com' }} />;
};

export default ConditionalTrackingWebView;
```

## Troubleshooting

### WebView Content Not Tracked

**Issue**: WebView interactions don't appear in Contentsquare

**Solutions**:

1. **Verify CSQWebView wrapper**:

   ```typescript
   // ❌ Wrong - missing wrapper
   <WebView source={{ uri: 'https://example.com' }} />

   // ✅ Correct - wrapped with CSQWebView
   <CSQWebView>
     <WebView source={{ uri: 'https://example.com' }} />
   </CSQWebView>
   ```

2. **Check web tag installation**:
   - Open WebView URL in desktop browser
   - Verify Contentsquare web tag loads
   - Check Console for `setWebViewMode` confirmation

3. **Verify WebView mode enabled**:

   ```javascript
   // In your web page JavaScript
   window._uxa.push(["setWebViewMode", true]);
   ```

4. **Check JavaScript enabled**:
   ```typescript
   <WebView
     source={{ uri: 'https://example.com' }}
     javaScriptEnabled={true} // Must be true
   />
   ```

### Session Not Stitched

**Issue**: Native and web sessions are separate

**Solutions**:

1. **Ensure SDK is started before WebView loads**:

   ```typescript
   useEffect(() => {
     CSQ.start(StartConfig.dxa());
     CSQ.optIn();
   }, []);
   ```

2. **Check native SDK is opted in**:

   ```typescript
   CSQ.optIn(); // Must be called before WebView loads
   ```

3. **Verify web tag project ID matches**:
   - Native SDK project ID
   - Web tag project ID
   - Should be the same project

4. **Test session ID**:
   ```typescript
   CSQ.onMetadataChange(metadata => {
     console.log("Session ID:", metadata.sessionID);
   });
   ```

### iOS: goBack() Not Recorded (Known Limitation)

**Issue**: Calling `WebView.goBack()` on iOS may not be captured in Session Replay

**Workaround**: Use alternative navigation patterns:

```typescript
import React, { useState } from 'react';
import { Button } from 'react-native';
import { WebView } from 'react-native-webview';
import { CSQWebView } from '@contentsquare/react-native-bridge';

const WorkaroundWebView = () => {
  const [url, setUrl] = useState('https://www.example.com/page1');

  // Instead of goBack(), change the URL directly
  const navigateBack = () => {
    setUrl('https://www.example.com/previous-page');
  };

  return (
    <>
      <Button title="Go Back" onPress={navigateBack} />

      <CSQWebView>
        <WebView source={{ uri: url }} />
      </CSQWebView>
    </>
  );
};
```

This is a known limitation on iOS only - see [compatibility guide](compatibility.md#webview-goback-ios).

### WebView Not Rendering

**Issue**: WebView shows blank screen with CSQWebView

**Solutions**:

1. **Check WebView props**:

   ```typescript
   <CSQWebView>
     <WebView
       source={{ uri: 'https://example.com' }}
       style={{ flex: 1 }} // Required for visibility
     />
   </CSQWebView>
   ```

2. **Verify URL is accessible**:

   ```bash
   # Test URL in browser
   curl -I https://example.com
   ```

3. **Check for CORS issues** (local HTML):

   ```typescript
   <WebView
     source={{ html: myHtml }}
     originWhitelist={['*']} // Allow all origins
   />
   ```

4. **Enable debugging**:
   ```typescript
   <WebView
     source={{ uri: 'https://example.com' }}
     onError={(error) => console.error('WebView error:', error)}
     onHttpError={(error) => console.error('HTTP error:', error)}
   />
   ```

### Web Tag Not Loading

**Issue**: Contentsquare web tag fails to load in WebView

**Solutions**:

1. **Check network access**:

   ```typescript
   <WebView
     source={{ uri: 'https://example.com' }}
     onLoad={() => console.log('WebView loaded')}
     onError={(e) => console.error('Load error:', e)}
   />
   ```

2. **Verify HTTPS**:
   - iOS requires HTTPS by default
   - For HTTP, configure App Transport Security (iOS)

3. **Test tag in desktop browser**:
   - Open same URL in Chrome/Safari
   - Check Network tab for Contentsquare script load
   - Verify no CORS or security errors

4. **Check Content Security Policy**:
   ```html
   <!-- In your web page -->
   <meta
     http-equiv="Content-Security-Policy"
     content="script-src 'self' t.contentsquare.net;"
   />
   ```

### TypeScript Errors

**Issue**: TypeScript compilation errors with CSQWebView

**Solution**: Ensure types are imported:

```typescript
import { CSQWebView } from "@contentsquare/react-native-bridge";
import type { WebView as WebViewType } from "react-native-webview";
```

## Best Practices

### 1. Always Wrap WebViews

Every WebView should be wrapped, even temporary or debugging WebViews:

```typescript
// ❌ Easy to miss during development
<WebView source={{ uri: testUrl }} />

// ✅ Consistent tracking
<CSQWebView>
  <WebView source={{ uri: testUrl }} />
</CSQWebView>
```

### 2. Track WebView Screens

Track WebView screens as native screens for complete user journeys:

```typescript
<CSQWebView>
  <WebView
    source={{ uri: 'https://example.com/checkout' }}
    onLoadEnd={() => {
      CSQ.trackScreenview('WebView: Checkout');
    }}
  />
</CSQWebView>
```

### 3. Handle Errors Gracefully

Provide fallbacks for WebView errors:

```typescript
const [hasError, setHasError] = useState(false);

if (hasError) {
  return <ErrorScreen />;
}

return (
  <CSQWebView>
    <WebView
      source={{ uri: 'https://example.com' }}
      onError={() => setHasError(true)}
    />
  </CSQWebView>
);
```

### 4. Test Cross-Platform

WebView behavior differs between iOS and Android:

```typescript
import { Platform } from 'react-native';

<CSQWebView>
  <WebView
    source={{ uri: 'https://example.com' }}
    // iOS-specific config
    {...(Platform.OS === 'ios' && {
      allowsInlineMediaPlayback: true,
    })}
    // Android-specific config
    {...(Platform.OS === 'android' && {
      domStorageEnabled: true,
    })}
  />
</CSQWebView>
```

### 5. Document WebView Usage

Add comments when WebViews are used:

```typescript
// WebView for Terms & Conditions
// Tracked with Contentsquare for engagement metrics
<CSQWebView>
  <WebView source={{ uri: 'https://example.com/terms' }} />
</CSQWebView>
```

## Additional Resources

- [react-native-webview Documentation](https://github.com/react-native-webview/react-native-webview/blob/master/docs/Reference.md)
- [Contentsquare WebView Tracking Tag Guide](https://docs.contentsquare.com/en/webview-tracking-tag/)
- [React Native Linking Documentation](https://reactnative.dev/docs/linking)
- [Session Replay Guide](session-replay.md)
- [Compatibility Guide](compatibility.md)

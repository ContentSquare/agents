# Screen Tracking Integration

Screen tracking is **critical** for Session Replay to function properly. This guide covers manual tracking and automatic tracking with React Navigation.

---

## Manual Screen Tracking

Use `trackScreenview()` to manually track screen views:

```typescript
import { CSQ } from '@contentsquare/react-native-bridge';
import { useEffect } from 'react';

function HomeScreen() {
  useEffect(() => {
    CSQ.trackScreenview('Home');
  }, []);

  return <HomeView />;
}
```

### With Custom Variables

```typescript
function ProductScreen({ productId, category }: Props) {
  useEffect(() => {
    CSQ.trackScreenview('ProductDetails', [
      { index: 1, key: 'product_id', value: productId },
      { index: 2, key: 'category', value: category },
      { index: 3, key: 'source', value: 'search' }
    ]);
  }, [productId, category]);

  return <ProductView />;
}
```

### CustomVar Constraints

```typescript
type CustomVar = {
  index: number; // Must be 1-20
  key: string; // Max 50 characters
  value: string; // Max 255 characters
};
```

---

## React Navigation Integration

### Basic Screen Tracking

Track every screen change automatically:

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { CSQ } from '@contentsquare/react-native-bridge';
import { useRef } from 'react';

const Stack = createNativeStackNavigator();

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  return (
    <NavigationContainer
      ref={navigationRef}
      onReady={() => {
        // Store initial route name
        routeNameRef.current = navigationRef.current?.getCurrentRoute()?.name;
      }}
      onStateChange={() => {
        const previousRouteName = routeNameRef.current;
        const currentRouteName = navigationRef.current?.getCurrentRoute()?.name;

        // Track screen change
        if (previousRouteName !== currentRouteName && currentRouteName) {
          CSQ.trackScreenview(currentRouteName);
        }

        // Update ref for next change
        routeNameRef.current = currentRouteName;
      }}
    >
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Profile" component={ProfileScreen} />
        <Stack.Screen name="Settings" component={SettingsScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

---

## Custom Screen Names

Map route names to human-readable screen names:

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';
import { useRef } from 'react';

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  // Define screen name mapping
  const getScreenNameForRoute = (routeName: string): string => {
    const screenNames: Record<string, string> = {
      'Home': 'Main Dashboard',
      'ProductDetails': 'Product View',
      'ProductList': 'Product Catalog',
      'Cart': 'Shopping Cart',
      'Checkout': 'Checkout Flow',
      'OrderConfirmation': 'Order Success',
      'Profile': 'User Profile',
      'Settings': 'App Settings'
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
      <Stack.Navigator>
        {/* Your screens */}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

---

## Track with Route Params

Include route parameters as custom variables:

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';
import { useRef } from 'react';

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  const trackScreen = (route: any) => {
    if (!route) return;

    const screenName = route.name;
    const params = route.params || {};

    // Build custom variables from route params
    const customVars = Object.entries(params)
      .slice(0, 20) // Max 20 custom vars
      .map(([key, value], index) => ({
        index: index + 1,
        key: key,
        value: String(value).substring(0, 255) // Max 255 chars
      }));

    if (customVars.length > 0) {
      CSQ.trackScreenview(screenName, customVars);
    } else {
      CSQ.trackScreenview(screenName);
    }
  };

  return (
    <NavigationContainer
      ref={navigationRef}
      onReady={() => {
        routeNameRef.current = navigationRef.current?.getCurrentRoute()?.name;
      }}
      onStateChange={() => {
        const previousRouteName = routeNameRef.current;
        const currentRoute = navigationRef.current?.getCurrentRoute();

        if (previousRouteName !== currentRoute?.name) {
          trackScreen(currentRoute);
        }

        routeNameRef.current = currentRoute?.name;
      }}
    >
      <Stack.Navigator>
        <Stack.Screen name="ProductDetails" component={ProductScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

// Usage: Navigate with params
navigation.navigate('ProductDetails', {
  productId: '12345',
  category: 'electronics',
  source: 'search'
});
// Tracked as: ProductDetails with custom vars
```

---

## Exclude Specific Routes

Skip tracking for certain screens (modals, debug screens, etc.):

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';
import { useRef } from 'react';

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  // Routes to exclude from tracking
  const excludedRoutes = new Set([
    'Modal',
    'Debug',
    'DevTools',
    'Splash'
  ]);

  const shouldTrackRoute = (routeName: string): boolean => {
    return !excludedRoutes.has(routeName);
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

        if (previousRouteName !== currentRouteName &&
            currentRouteName &&
            shouldTrackRoute(currentRouteName)) {
          CSQ.trackScreenview(currentRouteName);
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      <Stack.Navigator>
        {/* Your screens */}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

---

## React Navigation v5+ Stack Navigator

```typescript
import { createStackNavigator } from '@react-navigation/stack';
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';

const Stack = createStackNavigator();

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
          CSQ.trackScreenview(currentRouteName);
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      <Stack.Navigator>
        <Stack.Screen name="Home" component={HomeScreen} />
        <Stack.Screen name="Details" component={DetailsScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

---

## Bottom Tab Navigator

Track tab switches:

```typescript
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';

const Tab = createBottomTabNavigator();

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  return (
    <NavigationContainer
      ref={navigationRef}
      onReady={() => {
        routeNameRef.current = navigationRef.current?.getCurrentRoute()?.name;
        // Track initial tab
        if (routeNameRef.current) {
          CSQ.trackScreenview(routeNameRef.current);
        }
      }}
      onStateChange={() => {
        const previousRouteName = routeNameRef.current;
        const currentRouteName = navigationRef.current?.getCurrentRoute()?.name;

        // Track tab change
        if (previousRouteName !== currentRouteName && currentRouteName) {
          CSQ.trackScreenview(currentRouteName);
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      <Tab.Navigator>
        <Tab.Screen name="Home" component={HomeScreen} />
        <Tab.Screen name="Search" component={SearchScreen} />
        <Tab.Screen name="Profile" component={ProfileScreen} />
      </Tab.Navigator>
    </NavigationContainer>
  );
}
```

---

## Drawer Navigator

Track drawer screen switches:

```typescript
import { createDrawerNavigator } from '@react-navigation/drawer';
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';

const Drawer = createDrawerNavigator();

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
          CSQ.trackScreenview(currentRouteName);
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      <Drawer.Navigator>
        <Drawer.Screen name="Home" component={HomeScreen} />
        <Drawer.Screen name="Settings" component={SettingsScreen} />
      </Drawer.Navigator>
    </NavigationContainer>
  );
}
```

---

## Nested Navigators

Track screens in nested navigator structures:

```typescript
import { createStackNavigator } from '@react-navigation/stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';

const Stack = createStackNavigator();
const Tab = createBottomTabNavigator();

function TabNavigator() {
  return (
    <Tab.Navigator>
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Search" component={SearchScreen} />
    </Tab.Navigator>
  );
}

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  // Get leaf route (deepest nested route)
  const getActiveRouteName = (state: any): string | undefined => {
    if (!state || typeof state.index !== 'number') {
      return state?.name;
    }

    const route = state.routes[state.index];

    if (route.state) {
      return getActiveRouteName(route.state);
    }

    return route.name;
  };

  return (
    <NavigationContainer
      ref={navigationRef}
      onReady={() => {
        const state = navigationRef.current?.getRootState();
        routeNameRef.current = getActiveRouteName(state);
      }}
      onStateChange={() => {
        const previousRouteName = routeNameRef.current;
        const state = navigationRef.current?.getRootState();
        const currentRouteName = getActiveRouteName(state);

        if (previousRouteName !== currentRouteName && currentRouteName) {
          CSQ.trackScreenview(currentRouteName);
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      <Stack.Navigator>
        <Stack.Screen name="MainTabs" component={TabNavigator} />
        <Stack.Screen name="Details" component={DetailsScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

---

## Track Modal Screens

Include or exclude modals from tracking:

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { CSQ } from '@contentsquare/react-native-bridge';

function App() {
  const navigationRef = useRef();
  const routeNameRef = useRef();

  const isModal = (routeName: string): boolean => {
    const modalRoutes = ['FilterModal', 'SortModal', 'ConfirmModal'];
    return modalRoutes.includes(routeName);
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
          // Option 1: Track modals with a prefix
          if (isModal(currentRouteName)) {
            CSQ.trackScreenview(`Modal: ${currentRouteName}`);
          } else {
            CSQ.trackScreenview(currentRouteName);
          }

          // Option 2: Skip modals entirely
          // if (!isModal(currentRouteName)) {
          //   CSQ.trackScreenview(currentRouteName);
          // }
        }

        routeNameRef.current = currentRouteName;
      }}
    >
      <Stack.Navigator>
        {/* Your screens */}
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

---

## Custom Hook for Screen Tracking

Reusable hook for consistent screen tracking:

```typescript
import { useEffect } from 'react';
import { CSQ } from '@contentsquare/react-native-bridge';
import type { CustomVar } from '@contentsquare/react-native-bridge';

export function useScreenTracking(
  screenName: string,
  customVars?: CustomVar[]
) {
  useEffect(() => {
    CSQ.trackScreenview(screenName, customVars);
  }, [screenName, customVars]);
}

// Usage
function ProductScreen({ productId }: Props) {
  useScreenTracking('ProductDetails', [
    { index: 1, key: 'product_id', value: productId }
  ]);

  return <ProductView />;
}
```

---

## Best Practices

1. **Track every screen**: Session Replay requires screen tracking
2. **Use meaningful names**: Screen names should be human-readable
3. **Be consistent**: Use a naming convention across all screens
4. **Avoid PII**: Never include emails, names, or sensitive data in screen names
5. **Custom variables**: Use for context (product IDs, categories, sources)
6. **Modals**: Decide if you want to track or exclude modal screens
7. **Nested navigators**: Track the deepest/leaf route
8. **Tab switches**: Track tab changes as separate screens
9. **Test thoroughly**: Verify all screens are tracked correctly
10. **Monitor**: Check analytics to ensure screens are being tracked

---

## Common Issues

### Screens not tracked

**Problem**: Some screens are not being tracked.

**Solution**: Verify `onStateChange` is called. Add console logs to debug:

```typescript
onStateChange={() => {
  const currentRoute = navigationRef.current?.getCurrentRoute();
  console.log('Navigation changed to:', currentRoute?.name);
  CSQ.trackScreenview(currentRoute?.name || 'Unknown');
}
```

### Duplicate tracking

**Problem**: Same screen tracked multiple times.

**Solution**: Check if `previousRouteName !== currentRouteName` before tracking.

### Missing custom vars

**Problem**: Custom variables not appearing.

**Solution**: Ensure CustomVar structure is correct (index, key, value) and constraints are met.

---

## TypeScript Types

```typescript
import type { CustomVar } from "@contentsquare/react-native-bridge";

// Screen tracking function signature
declare function trackScreenview(
  screenName: string,
  customVars?: CustomVar[],
): void;

// CustomVar type
type CustomVar = {
  index: number; // 1-20
  key: string; // max 50 chars
  value: string; // max 255 chars
};
```

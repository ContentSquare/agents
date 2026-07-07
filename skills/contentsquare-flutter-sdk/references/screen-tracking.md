# Screen Tracking — Navigator Setups & Edge Cases

This file covers every navigation pattern the SDK must handle. Read it before adding or modifying screen tracking in a customer app.

---

## Decision tree: which observer to use?

```
Does pubspec.yaml contain auto_route?
├── YES → use CSQNavigatorAutoRouteObserver (install csq_navigator_auto_route_observer)
│         Place it on: _appRouter.config(navigatorObservers: () => [...])
└── NO  → use CSQNavigatorObserver (already in contentsquare package)
          Does pubspec.yaml contain go_router?
          ├── YES → place on: GoRouter(observers: [CSQNavigatorObserver()])
          └── NO  → place on: MaterialApp(navigatorObservers: [CSQNavigatorObserver()])
```

Also scan for `PageView` and `TabBar` widgets — those require **manual** `trackScreenview` calls regardless of which observer is used (see the relevant sections below).
But ask the developer before if they want to consider those as seperate screens or not .It's not the case often so no further actions are needed in this case

---

## Standard Flutter Navigator (MaterialApp / CupertinoApp)

```dart
import 'package:contentsquare/csq.dart';

MaterialApp(
  navigatorObservers: [CSQNavigatorObserver()],
);
```

No extra package needed.

---

## GoRouter

`CSQNavigatorObserver` works with GoRouter. Pass it via the `observers` parameter on the `GoRouter` constructor — **not** via `MaterialApp.router`.

```dart
import 'package:contentsquare/csq.dart';
import 'package:go_router/go_router.dart';

final _router = GoRouter(
  observers: [CSQNavigatorObserver()],
  routes: [...],
);

MaterialApp.router(
  routerConfig: _router,
);
```

### GoRoute pageBuilder — must set page name

When using `pageBuilder` instead of `builder`, you must explicitly set `name` on the `MaterialPage` (or `CupertinoPage`). Otherwise the observer receives a route with no name and tracks an empty screen name.

```dart
import 'package:contentsquare/csq.dart';

GoRoute(
  path: '/checkout',
  name: 'Checkout Screen',
  pageBuilder: (context, state) => MaterialPage(
    name: 'Checkout Screen', // required — must match the route name
    key: ValueKey(state.pathParameters),
    child: const CheckoutScreen(),
  ),
),
```

---

## AutoRoute

AutoRoute's navigation system is not compatible with the standard `CSQNavigatorObserver`. Use the dedicated `CSQNavigatorAutoRouteObserver` from the `csq_navigator_auto_route_observer` package instead.

This observer extends `AutoRouteObserver` and adds automatic **tab navigation** support (`didInitTabRoute` / `didChangeTabRoute`).

### Install

```yaml
# pubspec.yaml
dependencies:
  contentsquare: ^4.4.0
  csq_navigator_auto_route_observer: ^1.1.0
```

Run `flutter pub get`.

### Basic usage

```dart
import 'package:csq_navigator_auto_route_observer/csq_navigator_auto_route_observer.dart';

MaterialApp.router(
  routerConfig: _appRouter.config(
    navigatorObservers: () => [
      CSQNavigatorAutoRouteObserver(),
    ],
  ),
);
```

### Optional callbacks

All three callbacks are identical to those on `CSQNavigatorObserver`.

#### screenNameProvider

Customize the screen name for a route. Use this when dart code obfuscation is enabled in release builds to avoid obfuscated names being tracked.

```dart
CSQNavigatorAutoRouteObserver(
  screenNameProvider: (route) {
    if (route.settings.name == '/profile') return 'User Profile';
    return route.settings.name;
  },
)
```

#### customVarsProvider

Attach Contentsquare custom variables to specific routes.

```dart
CSQNavigatorAutoRouteObserver(
  customVarsProvider: (route) {
    if (route.settings.name == '/product') {
      return [CustomVar(index: 1, name: 'section', value: 'shop')];
    }
    return null;
  },
)
```

#### excludeRouteFromTracking

By default **all routes are tracked**, including modals and dialogs. Use this callback to skip routes you do not want as separate screen views.

```dart
CSQNavigatorAutoRouteObserver(
  excludeRouteFromTracking: (route) {
    // Exclude a specific route
    if (route.settings.name == '/myRoute') return true;

    // Exclude popup routes (menus, popups)
    if (route is PopupRoute) return true;

    // Exclude dialog routes (AlertDialog, showDialog)
    if (route.runtimeType.toString().contains('DialogRoute')) return true;

    // Exclude full-screen dialogs
    if (route is PageRoute && route.fullscreenDialog == true) return true;

    return false;
  },
)
```

---

## PageView widget

Before proceeding to this, ask the developer if they want to consider PageViews as a seperate screen or not. if no, no further actions are needed and the following part is ignored

`PageView` does **not** push routes onto the navigation stack, so navigator observers are never triggered on page swipes. You must call `trackScreenview` manually via the `onPageChanged` callback.

```dart
import 'package:contentsquare/csq.dart';

final _pageNames = const ['onboarding_step_1', 'onboarding_step_2', 'onboarding_step_3'];

PageView.builder(
  itemCount: _pageNames.length,
  onPageChanged: (index) {
    CSQ().trackScreenview(screenName: _pageNames[index]);
  },
  itemBuilder: (_, index) => OnboardingPage(step: index),
)
```

---

## TabBar widget

Before proceeding to this, ask the developer if they want to consider TabBars as a seperate screen or not. if no, no further actions are needed and the following part is ignored

Standard Flutter `TabBar` only pushes a route on initialization. Tab switches do not trigger navigator observers. Track them manually via `TabController.addListener`.

```dart
import 'package:contentsquare/csq.dart';

class _MyTabState extends State<MyTabWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabNames = const ['home_tab', 'search_tab', 'profile_tab'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);

    // Track the initial tab on load
    CSQ().trackScreenview(screenName: _tabNames[_tabController.index]);

    // Track subsequent tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        CSQ().trackScreenview(screenName: _tabNames[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
```

> **AutoRoute tabs are handled automatically** — `CSQNavigatorAutoRouteObserver` hooks into `didInitTabRoute` and `didChangeTabRoute`, so no manual tracking is needed for AutoRoute-managed tab bars.

---

## Modal routes and dialogs

Both `CSQNavigatorObserver` and `CSQNavigatorAutoRouteObserver` track modal routes (`showDialog`, `showModalBottomSheet`, etc.) as separate screen views by default.

If you do not want modals tracked as screens, use `excludeRouteFromTracking` to filter them out (see the AutoRoute callbacks section above — same pattern applies to `CSQNavigatorObserver`):

```dart
CSQNavigatorObserver(
  excludeRouteFromTracking: (route) {
    if (route is PopupRoute) return true;
    if (route.runtimeType.toString().contains('DialogRoute')) return true;
    return false;
  },
)
```

---

## Screen naming guidelines

- Keep distinct screen names under **100 characters**
- Screen names are **case-insensitive** on the platform (stored in lowercase)
- Use descriptive template/layout names, not data values: prefer `Product Detail` over a product ID
- Separate words with spaces, dashes, or underscores: `Home and Living - Home Furnishings`
- Never include PII (emails, user names, IDs) in screen names
- If dart obfuscation is enabled in release builds, always provide a `screenNameProvider` to avoid obfuscated class names being sent as screen names
- When using `CSQNavigatorObserver` / `CSQNavigatorAutoRouteObserver`, back navigation (pop) is tracked automatically (the observer hooks `didPop`, `didReplace`, `didRemove`). Manual `trackScreenview` on back is only needed when **not** using the observer

---

## Manual back navigation tracking (no observer)

When the customer is **not** using `CSQNavigatorObserver` or `CSQNavigatorAutoRouteObserver`, back navigation (`pop`) is not auto-tracked. Send the previous screen name explicitly from a custom `NavigatorObserver`:

```dart
import 'package:contentsquare/csq.dart';
import 'package:flutter/widgets.dart';

class CustomNavigationObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    final previousScreenName = previousRoute?.settings.name;
    if (previousScreenName != null) {
      CSQ().trackScreenview(screenName: previousScreenName);
    }
  }
}
```

> The SDK already triggers a screenview when the app is foregrounded after being in background, **provided** at least one screenview was sent before. The last screen name is reused.

---

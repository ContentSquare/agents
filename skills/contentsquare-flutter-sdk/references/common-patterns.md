# Common Patterns

## Alternative Quick Start — without `runZonedGuarded`

Use only when the customer architecture makes `runZonedGuarded` impractical.

```dart
import 'package:contentsquare/csq.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    // Collects Flutter errors
    CSQ().collectFlutterError(details: details);
  };
  WidgetsBinding.instance.platformDispatcher.onError = (exception, stackTrace) {
    // Collects all unhandled errors from the root isolate, including platform-level errors
    CSQ().collectError(error: exception, stackTrace: stackTrace);
    return false;
  };

  await CSQ().start();
  await CSQ().optIn(); // TODO: manage consent — call only after user accepts
  runApp(MyApp());
}
```

> Prefer the `runZonedGuarded` pattern in the Quick Start of SKILL.md. Use this only when the app's architecture makes it necessary.

---

## Product Analytics with environment ID

```dart
await CSQ().start(
  startConfig: StartConfig.withEnvironmentId(
    id: 'your-env-id',
    options: AnalyticsOptions(enableInteractionsAutocapture: true),
  ),
);
```

---

## Track a purchase / transaction

```dart
await CSQ().trackTransaction(
  Transaction(price: 49.99, currency: Currency.EUR, id: 'txn_abc'),
);
```

`Currency` is an ISO 4217 enum (e.g., `Currency.USD`, `Currency.EUR`).

---

## GDPR consent flow

```dart
Future<void> handleConsent({required bool userAccepted}) async {
  if (userAccepted) {
    await CSQ().optIn();
  } else {
    await CSQ().optOut();
  }
}
```

---

## Custom event with properties

```dart
await CSQ().trackEvent(
  eventName: 'add_to_cart',
  properties: {'product_id': 'sku_123', 'quantity': 2, 'is_promo': true},
);
```

Property values must be `String`, `num`, or `bool`.

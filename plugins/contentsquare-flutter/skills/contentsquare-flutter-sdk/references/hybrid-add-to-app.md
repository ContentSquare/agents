# Hybrid Apps -- Flutter Add-to-App Integration

Use this guide when Flutter screens are embedded in an existing **native iOS (Swift) or Android (Kotlin) app that already runs the native Contentsquare SDK**. For a regular Flutter app, follow the Quick Start in `SKILL.md` instead.

The native SDK stays in charge of the app lifecycle; the Flutter SDK attaches to it.

## Requirements

- Flutter **>= 3.35**.
- The native Contentsquare SDK is already integrated and started in the host app as described [here of iOS](https://docs.contentsquare.com/en/csq-sdk-ios/experience-analytics/) and [here for Android.](https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/)
- The Contentsquare project is well configured to support Flutter hybrid application.
- The Flutter project is using the `CSQ` instead of `Contentsquare`. If not, it should be migrated following the [migration skill](./migration.md).

## 1. Flutter module (Dart)

Call `CSQ().init()` before `runApp`. Do not call `CSQ().start(...)` with a new config: the native SDK's configuration is used.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CSQ().init(); // Or unawaited(CSQ().init());
  runApp(const MyApp());
}
```

Screen tracking and WebView wrapping inside the Flutter module work as described in `SKILL.md`.

## 2. iOS host app (Swift)

Order matters. Missing either step silently disables Session Replay and WebView tracking for the Flutter screen, with no error.

1. Once at application startup, and always **before** `GeneratedPluginRegistrant.register(with:)`:

   ```swift
   CSQ.enableFlutterModuleSupport(enable: true)
   ```
2. Start the native SDK as usual described [here for Android](https://docs.contentsquare.com/en/csq-sdk-android/experience-analytics/#start-the-sdk) and [here for iOS](https://docs.contentsquare.com/en/csq-sdk-ios/experience-analytics/#start-the-sdk).
3. Create the `FlutterEngine` and register plugins as usual.
4. **Before presenting each** `FlutterViewController` (push, present, embed, or inside `makeUIViewController` for SwiftUI):

   ```swift
   let vc = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
   CSQ.register(flutterViewController: vc)   // must come before presentation
   present(vc, animated: true)
   ```

   The plugin must already be registered on the engine, otherwise the call does nothing.

5. When Flutter is dismissed, re-track the native screen in the dismissal callback.

## 3. Android host app (Kotlin)

1. Start the native SDK with `CSQ.optIn()` or `CSQ.start(context, StartConfig.dxa())`.
2. Host Flutter with the standard APIs (`FlutterActivity`, `FlutterFragment` or `FlutterView`, cached `FlutterEngine` or `FlutterEngineGroup`).
3. No Contentsquare registration call is needed.
4. When Flutter is closed, re-track the native screen.

## Checklist

- [ ] Flutter >= 3.35
- [ ] Both feature flags enabled on the project
- [ ] `await CSQ().init()` before `runApp`
- [ ] iOS: `enableFlutterModuleSupport(enable: true)` before plugin registration
- [ ] iOS: `register(flutterViewController:)` before presenting every Flutter view controller
- [ ] Native screen re-tracked after Flutter is dismissed (iOS and Android)
- [ ] WebViews inside Flutter wrapped with `CSQWebViewWrapper`

## Limitations

- **Fullscreen Flutter only.** Embedded / non-fullscreen Flutter and several Flutter views in one native screen are not supported and may give incorrect Session Replay, touch targeting or screenview attribution.
- Each Flutter engine is tracked separately, including its WebViews.

## Troubleshooting

| Symptom                                           | Likely cause                                                                                              |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| iOS: no Session Replay / events on a Flutter screen | Step order wrong or skipped (see section 2)                                                               |
| No Session Replay for Flutter screens on any platform | Contentsquare project is not well configured.                                                                 |
| `CSQ().start()` seems to do nothing               | Expected: the native SDK is already running. Configure through the native SDK                              |
| Wrong screen after closing Flutter                | Native screen not re-tracked on dismissal                                                                 |

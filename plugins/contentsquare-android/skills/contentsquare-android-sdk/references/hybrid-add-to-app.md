# Flutter CSQ in Android Add-to-App

Use this reference when integrating the CSQ Flutter SDK into a Flutter module embedded in an Android application. This is not a guide to creating or embedding a Flutter module.

## Follow the Flutter SDK Hybrid Guide

Load and follow the dedicated [Contentsquare Flutter SDK hybrid add-to-app guide](https://github.com/ContentSquare/agents/tree/main/skills/contentsquare-flutter-sdk/references/hybrid-add-to-app.md) before making Flutter CSQ changes. That guide is the source of truth for the hybrid integration; do not duplicate its implementation instructions here.

1. Reuse the Android skill's healthcheck result. If it has not run yet, run it once using the Android host's application ID, not the Flutter module wrapper's package.
2. Read the linked guide, using authenticated repository access if required. If the Flutter SDK skill is installed locally, its `references/hybrid-add-to-app.md` can be loaded directly.
3. Follow that guide for Flutter CSQ dependencies, configuration, initialization, and interaction with the native Android CSQ integration. Load any supporting Flutter SDK references it requires.
4. Keep changes scoped to CSQ integration in the existing host and Flutter module. Do not rebuild the Flutter embedding or change its AAR/source distribution unless the CSQ changes require it.
5. Run the guide's verification steps for both native and Flutter surfaces. Do not treat native SDK startup alone as proof that Flutter CSQ is integrated.

If the guide cannot be retrieved, report the access failure and ask for access or its contents before implementing Flutter CSQ changes. Do not substitute native-only instructions or invent hybrid SDK APIs.
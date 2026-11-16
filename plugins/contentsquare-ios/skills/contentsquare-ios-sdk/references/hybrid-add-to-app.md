# Contentsquare Flutter Add-To-App

Use this reference when a client wants to integrate Contentsquare into a Flutter module embedded in a native iOS application (Flutter Add-To-App).

## Authoritative Guidance

Load and follow the Contentsquare Flutter SDK's [hybrid Add-To-App reference](https://github.com/ContentSquare/agents/blob/main/skills/contentsquare-flutter-sdk/references/hybrid-add-to-app.md).

If the `contentsquare-flutter-sdk` skill is available locally, load its `SKILL.md` and `references/hybrid-add-to-app.md`. Otherwise, retrieve the linked reference and any prerequisite Flutter SDK guidance it explicitly requires.

Keep the integration instructions in that Flutter reference as the source of truth rather than duplicating them here.

## Agent Workflow

1. Confirm the native host platform and locate the existing Flutter module and Contentsquare integration, if any.
2. Follow the Flutter reference for Contentsquare dependency setup, native/Flutter initialization, and any required bridge or lifecycle handling. Use the APIs and versions it specifies for the client's platform.
3. Limit changes to Contentsquare integration. Do not scaffold a Flutter module or provide a general Flutter Add-To-App tutorial unless the client explicitly asks.
4. Apply the reference's consent, screen tracking, and Session Replay requirements across native and Flutter screens, preserving the client's existing consent flow.
5. Validate the integration using the reference's checks, including transitions between native and Flutter screens. Report any checks that could not be run.

If the upstream reference cannot be retrieved, ask the client to provide it or make the Flutter skill available locally before making integration changes that depend on it. Do not guess hybrid-specific APIs or configuration.
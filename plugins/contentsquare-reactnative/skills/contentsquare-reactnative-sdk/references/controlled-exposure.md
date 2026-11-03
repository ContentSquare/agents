# Controlled Exposure (CSQEncrypt)

`CSQEncrypt` marks a piece of text for **controlled exposure**: Session Replay still collects it masked, as usual, and additionally collects it **unmasked but encrypted**. Use it for values that must stay hidden in a normal replay but that an authorized party may need to read later (for example a card number or an order reference).

> `CSQEncrypt` only works with the `CSQ` API (not the legacy `Contentsquare` API), and needs the native SDK versions the bridge pins: Android library 4.53.0 / sdk 1.13.0 and iOS SDK 1.13.1 or later. The bridge release that ships `CSQEncrypt` already depends on them.

---

## Usage

```typescript
import { CSQEncrypt } from '@contentsquare/react-native-bridge';
import { Text, TextInput } from 'react-native';

// A Text
<CSQEncrypt>
  <Text>4111 1111 1111 1111</Text>
</CSQEncrypt>

// A TextInput
<CSQEncrypt>
  <TextInput value={cardNumber} onChangeText={setCardNumber} />
</CSQEncrypt>
```

`CSQEncrypt` accepts the usual `ViewProps` (for example `style`), which are applied to the native container it renders around the child.

## Rules the component enforces

| Rule | What happens otherwise |
|---|---|
| **Exactly one child.** | TypeScript rejects several children. At runtime more than one child logs the error `CSQEncrypt component expects exactly 1 child` and **renders nothing**, so the content disappears from the screen. |
| **The child must be a text component**: `Text` or `TextInput`. | Any other child (`View`, `Image`, ...) is rendered normally but **not encrypted**; the native SDK logs that it was ignored (`CSLIB` tag on Android, the Contentsquare log on iOS). |
| **Only the first child is considered.** | Further children never reach the component through the supported API. |
| **Encryption is applied when the child is mounted.** | There is no re-trigger on prop changes and no un-encrypt API. A `TextInput` is encrypted once; editing its value does not call it again. |

## Where to put it

- Wrap the **smallest** text element that holds the value, not a whole screen or form.
- Do not combine it with `CSQMask` on the same element expecting different results: `CSQEncrypt` is an addition to masking (the text is still masked in the normal replay), not a replacement for `CSQMask` or `CSQ.setDefaultMasking`.
- Call it only for data the product owner has agreed may be exposed to authorized readers. Encrypting a value does not remove the need for consent: keep the normal `optIn()` flow.

## Integration checklist for agents

1. Confirm the app uses the `CSQ` API and `CSQ.start(...)` runs at startup. If it still uses the legacy `Contentsquare` API, migrate first (see [migration.md](migration.md)).
2. Confirm the installed bridge version exports `CSQEncrypt`. If not, ask the user to upgrade before changing code.
3. Identify the values to expose (ask the user; never decide which data to encrypt).
4. Wrap each one as `<CSQEncrypt><Text>...</Text></CSQEncrypt>` with a single text child.
5. Make sure the app is rebuilt natively (iOS: `pod install`; Android: Gradle sync), because the component is native.
6. Verify in a debug build: the native log shows an "Encrypting ..." line for each wrapped value and no "ignoring ..." line.

## Common mistakes

```typescript
// Wrong: two children, nothing is rendered
<CSQEncrypt>
  <Text>Card</Text>
  <Text>4111 1111 1111 1111</Text>
</CSQEncrypt>

// Right: one CSQEncrypt per value
<>
  <Text>Card</Text>
  <CSQEncrypt>
    <Text>4111 1111 1111 1111</Text>
  </CSQEncrypt>
</>

// Wrong: a View is not a text component, so nothing inside it is encrypted
// (same on Android and iOS, even when the View only wraps TextInputs)
<CSQEncrypt>
  <View><TextInput /><TextInput /></View>
</CSQEncrypt>

// Right: wrap the Text itself
<View>
  <CSQEncrypt>
    <Text>secret</Text>
  </CSQEncrypt>
</View>
```

## Platform support

- **Android** and **iOS**, both backed by a native view. There is no web or desktop implementation.
- Not available in Expo Go (it needs the native module); use a development build or EAS, as for the rest of the SDK.

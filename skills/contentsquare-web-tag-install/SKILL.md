---
name: contentsquare-web-tag-install
description: Install and verify the Contentsquare tracking tag in any web project. Use when asked to "add Contentsquare", "install CS tag", "set up Contentsquare analytics", or configure Contentsquare tracking for a web application. Verification runs through `npx @contentsquare/wizard verify`, which drives an embedded Playwright browser — no browser automation MCP required.
metadata:
  author: Contentsquare
  version: "2.2.0"
---

# Install Contentsquare Tag

You are helping a developer install and verify the Contentsquare tracking tag in their web project.
Follow this document top to bottom. Do not skip sections.

**All runtime verification is done by one command:**

```bash
npx --yes @contentsquare/wizard@2 verify
```

That command launches a real browser, lets the developer click through their app, and reports the
tag load, first pageview, pageviews on navigation, and CSP issues in a single session. It is resolved
on demand by `npx` (cached after the first run) — nothing to install globally, and you never drive a
browser yourself. The `@2` pin tracks the current major line so verification stays reproducible while
still picking up patch and minor fixes. `--yes` skips npx's first-run "Ok to proceed?" install
prompt, which would otherwise block a non-interactive agent on a machine that hasn't cached the
package yet.

---

<rules>

## Rules (read first, apply throughout)

- The package is exactly `@contentsquare/tag-sdk`. The function is exactly
  `injectContentsquareScript`. The only required option is `clientId`. Do not substitute, rename, or
  invent alternatives.
- `injectContentsquareScript` **must run in a browser context only** — never during SSR. If you're
  placing it in a file that runs on the server (Next.js Server Component, Nuxt server route, SvelteKit
  `+page.server.ts`, etc.), it is wrong.
- The **tag ID** (a.k.a. hashed project ID) is a **lowercase hex string, ~13 characters**
  (e.g. `81c677ba742d7`). If what you have looks like a plain decimal number, an email, a URL, or
  anything else — stop and ask for the **hashed** project ID. **Never hash, transform, generate, or
  guess the ID yourself.**
- Base framework detection only on actual command output. If detection is ambiguous or `package.json`
  is missing, **ask the developer**.
- Never start, restart, or kill the dev server. Always ask the developer to do it.
- Never modify CSP unless `verify` reports a violation, or you find an existing CSP missing
  Contentsquare domains. Do not preventively add CSP headers to a project that has none.
- Run `npm install` (or equivalent) only after confirming the package manager and that you are in the
  project root.
- After **2 failed verification attempts**, stop modifying code and ask the developer for guidance.
- If the project has no `tsconfig.json`, use `.js`/`.jsx` extensions instead of `.ts`/`.tsx` in all
  file paths and templates below.

**Completion criteria — done only when ALL are true (these come straight from `verify`):**

1. `tagScriptLoaded: true` — the tag script `t.contentsquare.net/uxa/<tagId>.js` loaded.
2. `initialPageview: true` — at least one further request to `t.contentsquare.net` fired.
3. `cspViolations: []` — no CSP violations referencing Contentsquare domains.

Do not declare success based on "the code looks right." Only the `verify` report counts.

</rules>

---

## Before You Start — get the tag ID

1. Look for the tag ID in the developer's original instruction (e.g. "Install Contentsquare, tag ID
   `81c677ba742d7`"). If provided, use it directly — do not ask again.
2. If `.cs-wizard/state.json` exists in the project, read `tagId` from it and use that.
3. If you still don't have it, ask:
   > "What is your Contentsquare tag ID? It's the hex string (e.g. `81c677ba742d7`) used as
   > `clientId`. You can find it in your tag snippet or in Settings."

You will pass this value to `verify` as `--tag-id <tagId>`.

---

## Flow

1. **Install** — detect the framework, install the SDK, add the init code.
2. **Verify** — run `npx @contentsquare/wizard verify` once; the developer browses their app.
3. **Fix CSP** — only if `verify` reports `cspViolations`.
4. **Re-verify** — re-run `verify` to confirm everything is green.

---

## Step 1 — Install the tag

### 1.1 Detect the framework

Inspect the project — do not guess:

```bash
cat package.json | grep -E '"next"|"nuxt"|"vue"|"react"|"@angular/core"|"svelte"|"@sveltejs/kit"|"vite"|"@contentsquare/'
ls package-lock.json yarn.lock pnpm-lock.yaml bun.lockb 2>/dev/null
ls tsconfig.json 2>/dev/null
ls src/app app src/pages pages 2>/dev/null
ls src/main.ts src/main.tsx src/index.ts src/index.tsx app/layout.tsx app/layout.jsx src/app/layout.tsx src/app/layout.jsx pages/_app.tsx pages/_app.jsx 2>/dev/null
grep -r "contentsquare\|injectContentsquareScript\|_uxa" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.html" -l 2>/dev/null | grep -v node_modules
```

**Determine:**
- Framework (priority: Next.js > React, Nuxt > Vue, SvelteKit > Svelte, Angular, Vite)
- App Router or Pages Router (Next.js only) — check if `app/` or `src/app/` exists
- TypeScript (tsconfig.json present) or JavaScript
- Package manager (npm/yarn/pnpm/bun)
- Already installed? → Skip to Step 2

### 1.2 Confirm with the developer

> "I detected **[framework]** using **[TS/JS]** with **[package manager]**. The entry point is
> `[file]`. Correct?"

Do not proceed until confirmed. If you don't have the tag ID yet, ask now.

### 1.3 Install the package and add the init code

```bash
npm install @contentsquare/tag-sdk
# or: yarn add / pnpm add / bun add — match the detected package manager
```

Replace `<TAG_ID>` below with the developer's actual tag ID.

---

**Next.js — App Router** — create a client component at the path where `layout` lives (`app/contentsquare.tsx` or `src/app/contentsquare.tsx`):

```typescript
'use client';
import { useEffect } from 'react';
import { injectContentsquareScript } from '@contentsquare/tag-sdk';

export function Contentsquare() {
  useEffect(() => {
    injectContentsquareScript({ clientId: '<TAG_ID>' });
  }, []);
  return null;
}
```

Then add `<Contentsquare />` to the root layout (same directory):

```typescript
import { Contentsquare } from './contentsquare';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <Contentsquare />
        {children}
      </body>
    </html>
  );
}
```

---

**Next.js — Pages Router** — in `pages/_app.tsx`:

```typescript
import { useEffect } from 'react';
import { injectContentsquareScript } from '@contentsquare/tag-sdk';
import type { AppProps } from 'next/app';

export default function App({ Component, pageProps }: AppProps) {
  useEffect(() => {
    injectContentsquareScript({ clientId: '<TAG_ID>' });
  }, []);
  return <Component {...pageProps} />;
}
```

---

**React (Vite / CRA)** — in `src/main.tsx` (or `src/index.tsx`), before `ReactDOM.createRoot`:

```typescript
import { injectContentsquareScript } from '@contentsquare/tag-sdk';
injectContentsquareScript({ clientId: '<TAG_ID>' });
```

---

**Vue (Vite)** — in `src/main.ts`:

```typescript
import { injectContentsquareScript } from '@contentsquare/tag-sdk';
injectContentsquareScript({ clientId: '<TAG_ID>' });
```

---

**Nuxt 3** — create `plugins/contentsquare.client.ts` (the `.client` suffix keeps it browser-only):

```typescript
import { injectContentsquareScript } from '@contentsquare/tag-sdk';

export default defineNuxtPlugin(() => {
  injectContentsquareScript({ clientId: '<TAG_ID>' });
});
```

---

**Angular** — in `src/main.ts`, before `bootstrapApplication` / `platformBrowserDynamic().bootstrapModule(...)`:

```typescript
import { injectContentsquareScript } from '@contentsquare/tag-sdk';
injectContentsquareScript({ clientId: '<TAG_ID>' });
```

---

**SvelteKit** — in `src/routes/+layout.svelte`:

```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { injectContentsquareScript } from '@contentsquare/tag-sdk';

  onMount(() => {
    injectContentsquareScript({ clientId: '<TAG_ID>' });
  });
</script>

<slot />
```

---

**Static HTML / server-rendered** (Django, Rails, Laravel, PHP, WordPress, or no JS framework) — add inside `<head>`:

```html
<script src="https://t.contentsquare.net/uxa/<TAG_ID>.js" defer></script>
```

Common locations: Django → `templates/base.html`, Rails → `app/views/layouts/application.html.erb`, Laravel → `resources/views/layouts/app.blade.php`, WordPress → `header.php`.

> If you use the `_uxa` API for custom variables or virtual pageviews, use the IIFE loader pattern instead so commands are buffered before the script loads:

```html
 <script>
 (function(c,s,q,u,a,r,e){
   c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
   e=s.createElement(q);e.async=1;e.src=u;
   r=s.getElementsByTagName(q)[0];r.parentNode.insertBefore(e,r);
 })(window,document,'script','https://t.contentsquare.net/uxa/<TAG_ID>.js','_uxa');
 </script>
```

---

### 1.4 Prepare for verification

Ask the developer to **start their dev server**. Never start it yourself. Then proceed to Step 2.

---

## Step 2 — Verify with the wizard CLI

Before the first run, ensure `.cs-wizard/` is in the project's `.gitignore` — the verifier writes
reports there (`last-report.json`, `last-browser-error.json`) and those should not be committed. Add
the entry if it's missing.

Run the verifier from the project root. Pass the URL and tag ID so it doesn't prompt, and `--json` so
you get a clean, machine-readable report on stdout (this is the agent mode):

```bash
npx --yes @contentsquare/wizard@2 verify --url http://localhost:3000 --tag-id <TAG_ID> --json
```

URL defaults by framework: Next.js / Nuxt / CRA → `http://localhost:3000`,
Vite → `http://localhost:5173`, Angular → `http://localhost:4200`.

> **This command is interactive and blocks until the developer finishes.** It opens a real browser and
> waits. **Do not assume it hung, and do not cancel or time it out.** Run it in the foreground and wait
> for it to exit on its own.

What happens:

1. A real browser window opens at the URL with a Contentsquare banner overlaid on the page.
2. **Tell the developer:** "A browser opened. Browse your app — let the first page load, click through
   a few in-app routes, and log in if needed. When you're finished, click **Done** in the banner (or
   just close the window)."
3. Only when the developer clicks **Done** / closes the window does the command finish and print the
   report.

Read the result from the JSON printed on stdout, or from `.cs-wizard/last-report.json` (written in
every run). Exit codes:

| Code | Meaning                                                                                                              |
| ---- | ------------------------------------------------------------------------------------------------------------------- |
| `0`  | `pass` or `pass-with-recommendation`                                                                                |
| `1`  | `fail` (the report ran), or the browser failed to launch for an unknown reason (`{"error":"BROWSER_LAUNCH_FAILED"}`) |
| `2`  | no browser engine found (`{"error":"NO_BROWSER"}`)                                                                  |
| `3`  | a browser is installed but is missing system libraries (`{"error":"MISSING_LIBS"}`)                                |
| `4`  | a browser is installed but refused to launch, e.g. enterprise policy or a profile already in use (`{"error":"BLOCKED_LAUNCH"}`) |
| `5`  | no graphical display (headless Linux box); `verify` needs a visible window (`{"error":"NO_DISPLAY"}`)               |

Treat any of these as a normal report or environment outcome, **not** a crash. For every non-zero
browser-environment failure (`2`–`5`), `--json` mode prints a `{"error":"<CODE>"}` object on stdout,
writes a `.cs-wizard/last-browser-error.json` breadcrumb, and prints human guidance on stderr. See
**If the browser can't be acquired** below.

### If the browser can't be acquired

If `verify` exits with code `2`–`5`, it could not get a working browser. In `--json` mode stdout
carries `{"error":"<CODE>"}` and stderr prints the matching fix. Route on the code:

| Exit / error         | What it means                                                                                          | What to do                                                                                                                       |
| -------------------- | ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `2` `NO_BROWSER`     | No browser engine is installed.                                                                        | Ask the developer for consent, then re-run with `--install-browser` (see below).                                                 |
| `3` `MISSING_LIBS`   | A browser is installed but is missing OS libraries (common on minimal Linux). A download won't fix it. | Ask the developer to run `sudo npx playwright-core install-deps chromium`, then re-run Step 2.                                   |
| `4` `BLOCKED_LAUNCH` | A browser exists but refused to launch (enterprise policy, or a profile already in use).               | Ask the developer to close all Chrome/Edge windows and retry; or install the bundled engine and re-run with `--install-browser`. |
| `5` `NO_DISPLAY`     | Running on a headless Linux box with no display; `verify` needs a visible window.                      | The developer must run `verify` on a machine with a graphical display (their own desktop). It cannot run headless.               |

For `NO_BROWSER` (`2`), ask the developer for consent:

> "The verifier needs a browser engine and none was found. May I download Chromium (~150 MB,
> one-time)?"

On a **yes**, re-run with the install flag:

```bash
npx --yes @contentsquare/wizard@2 verify --url <url> --tag-id <TAG_ID> --json --install-browser
```

If the download itself fails behind a corporate proxy, the CLI prints the proxy env vars to set
(`HTTPS_PROXY`, `NODE_EXTRA_CA_CERTS`, `PLAYWRIGHT_DOWNLOAD_HOST`); relay those to the developer and
re-run.

### Route based on the report

| Report                                   | Action                                                                                                                                               |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `result: "pass"`                         | Done — go to the success message.                                                                                                                    |
| `result: "pass-with-recommendation"`     | Tag works; SPA route changes missed pageviews. Surface the `recommendation` (enable **Tracking URL Changes** in the Contentsquare app). Then finish. |
| `tagScriptLoaded: false`                 | Tag never loaded. Ensure `injectContentsquareScript` runs client-side (useEffect/onMount/`.client.ts`) and the package is installed. Re-run Step 2.  |
| `initialPageview: false` (script loaded) | Confirm the tag ID is correct and the project is active. Re-run Step 2.                                                                              |
| `tagIdMismatch: true`                    | The tag URL uses a different ID than `--tag-id`. Fix the `clientId` in code. Re-run Step 2.                                                          |
| `cspViolations` non-empty                | Go to Step 3.                                                                                                                                        |

---

## Step 3 — Fix CSP (only if `verify` reported violations)

### 3.1 Find the existing CSP

```bash
grep -rn "Content-Security-Policy\|contentSecurityPolicy" next.config.* middleware.* 2>/dev/null
grep -rln "Content-Security-Policy" --include="*.html" --include="*.ejs" --include="*.hbs" --include="*.blade.php" --include="*.erb" . 2>/dev/null | grep -v node_modules
cat package.json | grep -E '"helmet"|"csp-header"|"content-security-policy"' 2>/dev/null
```

### 3.2 Append the Contentsquare domains

Add to the project's **existing** directives — append, never replace:

```
script-src:  'unsafe-inline' *.contentsquare.net app.contentsquare.com
connect-src: *.contentsquare.net *.contentsquare.com
img-src:     *.contentsquare.net
child-src:   blob:
worker-src:  blob:
```

Apply them in whatever format the project already uses (Next.js `headers()`, middleware, `<meta>` tag,
nginx, helmet). Preserve all existing values.

**Example** (Next.js `next.config.ts` headers):
```typescript
"script-src 'self' 'unsafe-inline' *.contentsquare.net app.contentsquare.com",
"connect-src 'self' *.contentsquare.net *.contentsquare.com",
"img-src 'self' *.contentsquare.net",
"child-src 'self' blob:",
"worker-src 'self' blob:",
```

### 3.3 Re-verify

Ask the developer to **restart the dev server** so new headers take effect, then return to **Step 2**
and run `verify` again. Confirm `cspViolations` is now empty.

---

## Success

When `verify` returns `result: "pass"` (or `pass-with-recommendation`), report:

```
✅ Contentsquare setup complete!

- Tag installed: <framework> via @contentsquare/tag-sdk
- Tag script loading: ✓
- First pageview sent: ✓
- In-app routes tracked: <navigationsWithPageview>/<navigations.length> routes
- CSP: <no issues / fixed>
```

If the report was `pass-with-recommendation`, add the recommendation verbatim (enabling **Tracking URL
Changes** in the Contentsquare app for SPA route changes).

### How to phrase the route-tracking line (avoid misleading the developer)

The `<n>/<n>` figure is **distinct in-app routes that fired a pageview**, not the number of beacons
sent or the number of times the developer navigated. `verify` collapses the trace before grading:

- The **initial landing page** is excluded (it's covered by "First pageview sent").
- **Repeat visits to the same route are counted once.** If the developer browsed
  `/` → `/products` → `/cart` → `/`, that is **2** distinct in-app routes (`/products`, `/cart`),
  so a clean result reads `2/2 routes` — even though more than two navigations happened.

Therefore:

- Phrase it as routes **covered**, e.g. "both in-app routes you visited fired a pageview". Do **not**
  say "2 pageviews were sent" — that conflates routes with beacons and will confuse the developer.
- List the route paths from `navigations[].url`, not a count of network requests.
- If `navigations` is empty, say no in-app route changes were exercised (so SPA tracking wasn't
  tested), rather than reporting `0/0` as a pass signal.

---

## Troubleshooting

| Issue                                         | Solution                                                                                         |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Tag not loading                               | Ensure `injectContentsquareScript` runs client-side only (`useEffect`, `onMount`, `.client.ts`). |
| `injectContentsquareScript is not a function` | Confirm `@contentsquare/tag-sdk` is installed and imported correctly.                            |
| `verify` records no navigations               | The developer must actually click through in-app routes before clicking Done.                    |
| Browser won't launch                          | Re-run with `--install-browser`, or install Google Chrome.                                       |
| CSP errors persist after fix                  | The dev server must be restarted so new headers are served.                                      |
| Violations from `.contentsquare.com`          | Add both `*.contentsquare.net` and `*.contentsquare.com` to `connect-src`.                       |
</content>

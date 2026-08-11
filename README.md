# X-DREAMER — Android app

Flutter client for **X-DREAMER** (https://ai.xman4289.com), the AI image and
video generation platform. Same account, same credits, same gallery as the web
app — this talks to the same backend.

- **Backend:** [`xjanova/aixman`](https://github.com/xjanova/aixman) (Next.js 16)
- **Accounts & payments:** [`xjanova/xmanstudio`](https://github.com/xjanova/xmanstudio) (Laravel) — it owns `users`, so registration and checkout happen there
- **Design source:** `design/design_handoff_xdreamer_mobile/` (the hi-fi handoff this was built from)

## Requirements

Flutter 3.41+ / Dart 3.11+, JDK 17, Android SDK with `minSdk 24`.

## Run

```bash
flutter pub get
flutter run
```

Against a local backend (`10.0.2.2` is the host machine from the Android emulator):

```bash
flutter run --dart-define=XDR_API_BASE=http://10.0.2.2:3000
```

| define | default | what it points at |
|---|---|---|
| `XDR_API_BASE` | `https://ai.xman4289.com` | the aixman API |
| `XDR_XMAN_BASE` | `https://xman4289.com` | registration, password reset, credit checkout |

A release build refuses to start if `XDR_API_BASE` is not `https://` — bearer
tokens must never travel in the clear. Debug builds allow cleartext so a
`next dev` server on the LAN is reachable.

## How it talks to the backend

The web app authenticates with a NextAuth session cookie, which a native client
cannot hold. `aixman` was extended with bearer-token auth for this app:

| endpoint | purpose |
|---|---|
| `POST /api/mobile/auth/login` | email + password → access + refresh token |
| `POST /api/mobile/auth/refresh` | rotate the pair |
| `GET /api/mobile/me` | profile + credit balance in one call |
| `GET /api/mobile/app-version` | latest release, for self-update |

**Every other endpoint is the one the web app already used** — `/api/generate`,
`/api/gallery`, `/api/credits`, `/api/upscale`, `/api/favorites`,
`/api/referral`. Nothing was duplicated for mobile; `getCurrentUserId()` on the
server accepts either credential. See `docs/mobile-api.md` in the aixman repo.

Tokens live in keystore-backed secure storage. An expired access token is
refreshed once, in a single flight shared by every request that hit a 401 at the
same moment; a failed refresh signs out and returns to the login screen.

## Self-update

The app is sideloaded, not published to Play Store, so it updates itself:

1. `GET /api/mobile/app-version` — the **server** reads the newest GitHub
   Release of this repo. The token stays on the server, so a private repo works
   and nothing sensitive is compiled into the APK.
2. If a newer version exists, the update sheet shows the changelog and the size.
3. The APK downloads, its SHA-256 is checked against `SHA256SUMS.txt` from the
   release, and only then is Android's installer opened.
4. Set `ai_settings.mobile_min_supported_version` on the backend to make an
   update mandatory without cutting a new release.

Releasing is a tag push:

```bash
git tag v0.2.0 && git push origin v0.2.0
```

`.github/workflows/release.yml` builds, signs, and publishes the APK plus
`SHA256SUMS.txt`. It needs these repo secrets:

`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
`ANDROID_KEY_PASSWORD`.

**The signing key can never change.** Android refuses an update signed with a
different key than the installed app, which would strand every existing install.

## Layout

```
lib/
  core/
    config/       base URLs, transport safety check
    net/          Dio client, token store, error mapping, media saving
    theme/        colours, type, motion, the Metal recipes
    widgets/      MetalSurface, PressSink, FiberThreads, shared UI
  data/
    models/       hand-written fromJson — no build_runner
    repositories/ auth, catalog, generation, gallery, credits, referral, update
  state/          Riverpod controllers
  features/       one folder per screen
```

Models are parsed defensively: a malformed row renders as an empty card rather
than throwing. See `test/widget_test.dart`.

## Deviations from the design handoff

Deliberate, and each for a reason:

- **"ยกเลิก" during generation is "ทำงานเบื้องหลัง".** There is no endpoint that
  stops a job once a provider has it, and the credits are already spent. The
  original label promised a refund that would never arrive.
- **The progress ring is an estimate and stops at 95%.** The API reports no
  percentage for provider-backed jobs. GPU-backed jobs *do* report a real stage
  and ETA, and when they do that copy takes over.
- **No "ปรับ prompt ด้วย AI" button.** There is no prompt-enhancement endpoint;
  it would have been a dead control.
- **Community shows your own work, ranked.** `/api/gallery` is scoped to the
  signed-in user server-side and there is no public feed endpoint yet, so the
  screen says so rather than implying otherwise. `ai_generations.is_public`
  exists, so when the endpoint lands only `GalleryRepository` changes.
- **Login's second button is a password reset link**, not "continue with XMAN
  Studio" — the accounts are the same row in the same table, so there is no
  handoff to perform.
- **Credit usage is lifetime, not monthly.** The API exposes running totals, not
  a monthly window.
- **No free-credit number on the signup link.** The welcome grant comes from
  `ai_settings.new_user_free_credits` and the app must not hardcode it.
- **The fiber-threads background has no accumulation buffer.** The web version
  fakes a trail by refilling the canvas each frame; on a phone that means an
  offscreen texture round-trip per frame. A blur per stroke gives the same bloom
  for a fraction of the battery. It runs at 26fps, stops when the app is
  backgrounded, and freezes under reduced-motion.

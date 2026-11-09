# Release setup: replace the mocks

Everything below is either a placeholder in code or a console/account step
that code can't do. The app builds and runs with all of it untouched (local
data + anonymous Firebase, free tier, no Apple sign-in, no App Check, no crash
reports). Search the repo for `REPLACE_ME` to find each placeholder.

Feature flags are compile-time `--dart-define`s (see `lib/config.dart`):

```
flutter build appbundle --release \
  --dart-define=APPLE_SIGN_IN=true \
  --dart-define=APP_CHECK=true \
  --dart-define=PRIVACY_URL=https://… \
  --dart-define=TERMS_URL=https://…
```

## 1. App ID decision (do this first)

Android `applicationId` and the iOS bundle id are both `com.gaman.gaman`, and
the Firebase apps in project `gaman1` are registered under that id. Changing
it later means new Firebase apps, a new `google-services.json` /
`GoogleService-Info.plist`, new OAuth clients and new SHA fingerprints, and a
store listing can never change its id once published. Decide before the first
upload; if it changes, redo sections 2–4 for the new id.

## 2. Firebase console (project `gaman1`)

- Authentication → Sign-in method: enable **Anonymous**, **Google**, and
  (once section 4 is done) **Apple**.
- Firestore rules: `firebase deploy --only firestore:rules --project gaman1`
  (from `gaman/`). See `docs/cloud-sync-firebase-setup.md`.
- Restrict the API keys in `lib/firebase_options.dart` (Google Cloud console →
  Credentials): Android key to the package + SHA-1, iOS key to the bundle id,
  web key to `egecanozcakar.github.io`.

## 3. Google Sign-In

**Android**
1. Create the upload keystore and `android/key.properties` (gitignored):
   ```
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/absolute/path/upload-keystore.jks
   ```
   Without this file, release builds fall back to the debug key (fine
   locally, rejected by Play).
2. Get the fingerprints: `keytool -list -v -keystore upload-keystore.jks
   -alias upload`, plus the **Play App Signing** key's SHA-1/SHA-256 from Play
   Console → Setup → App integrity, plus your debug key's.
3. Firebase console → Project settings → Android app → add every SHA-1 and
   SHA-256. Firebase creates the Android OAuth client.
4. Download the new `google-services.json` into `android/app/` (it must
   now contain an `oauth_client` entry of `client_type: 1`).

**iOS**
1. Download `GoogleService-Info.plist` for the iOS app and add it to
   `ios/Runner/` in Xcode (Runner target).
2. `ios/Runner/Info.plist` already has the Google URL scheme
   `com.googleusercontent.apps.215059104741-duv3g0skumq9otjinf78kbcv4r2qv3be`,
   which is the `iosClientId` in `lib/firebase_options.dart`, reversed.
   **Verify** it matches `REVERSED_CLIENT_ID` in the downloaded plist and
   update it if the iOS OAuth client ever changes (e.g. a new bundle id).

## 4. Sign in with Apple (`APPLE_SIGN_IN`)

1. Apple Developer → Identifiers → the app id → enable **Sign in with Apple**.
2. Xcode → Runner → Signing & Capabilities → **+ Sign in with Apple** (adds
   `Runner.entitlements`).
3. Firebase → Authentication → Apple → enable. For iOS-only native sign-in no
   Services ID is needed. Add one (plus key, team id) only if you later
   support Apple sign-in on Android or web.
4. Build with `--dart-define=APPLE_SIGN_IN=true`. The button only shows on
   iOS/macOS. App Store rule 4.8: since Google sign-in is offered on iOS,
   Apple sign-in must ship there too.

## 5. App Check (`APP_CHECK`)

1. Firebase → App Check → register Android with **Play Integrity** (needs the
   app linked in Play Console and the SHA-256 from section 3) and iOS with
   **App Attest** (DeviceCheck fallback).
2. Xcode → Signing & Capabilities → **+ App Attest** (set the environment to
   `production` for release).
3. Debug builds use the debug provider: run once, copy the debug token from the
   log, and add it under App Check → Manage debug tokens.
4. Build with `--dart-define=APP_CHECK=true`, watch App Check metrics for a
   week, **then** turn on enforcement for Firestore. Enforcing before that
   locks out every unregistered client.

## 6. Crashlytics (opt-in)

- Firebase → Crashlytics → enable.
- The Android Gradle plugin is already applied. On iOS, add the
  `upload-symbols` run script for dSYMs (FlutterFire docs, "Crashlytics →
  iOS").
- Collection is off in the manifest and Info.plist and is only turned on by
  the Settings toggle (`CrashReporting`). Keep it that way: it's what the
  privacy policy says.
- Verify with a test crash on a release build with the toggle on.

## 7. Billing (`EntitlementService`)

`lib/services/entitlement_service.dart` is a mock: everyone is free. Debug
builds have a "pretend Premium" switch in Settings.

1. Choose `in_app_purchase` or RevenueCat (still open).
2. Create the products in Play Console and App Store Connect; ids are
   placeholders in `premiumPlans`: `gaman_premium_yearly`,
   `gaman_premium_monthly` (auto-renewing subscriptions) and
   `gaman_premium_lifetime` (a one-time **non-consumable** in-app product,
   placeholder $49.99). The lifetime purchase must grant the same
   entitlement as the subscriptions.
3. Implement the `BILLING HOOK`s: seed `_premium` from active entitlements,
   then `purchase()`/`restore()`. Replace the placeholder prices with
   store-localised ones and flip `billingAvailable`.
4. Paywall copy is in `lib/l10n/app_en.arb` (`paywall*`). Remove
   "Placeholder prices" from `paywallFinePrint`.

## 8. Icon and splash

- **Icon**: still a placeholder in `assets/branding/` (it literally says
  "PLACEHOLDER"). Replace `icon_placeholder.png` and
  `icon_foreground_placeholder.png` with the real mark, then run
  `dart run flutter_launcher_icons` and commit the regenerated `android/`,
  `ios/` and `web/` resources.
- **Splash**: no art needed. The native splash is plain water green
  (`#5F8F8C`) and the Flutter splash draws the ensō in code
  (`lib/widgets/enso.dart`), so there's no flash between them. If you later
  want the mark on the native splash too, add `image:` under
  `flutter_native_splash` in `pubspec.yaml` and run
  `dart run flutter_native_splash:create`.
- **Store art**: `store/screenshots/` (1290×2796) and
  `store/feature-graphic.png` (1024×500) are generated from the web build by
  `tool/store_art/make.js` (instructions at the top of the file). Re-run it
  after UI changes or once the real icon exists.

## 9. Privacy policy, terms and store labels

- Host the policy (draft: `docs/privacy-policy-draft.md`) and terms, then set
  `PRIVACY_URL` / `TERMS_URL`. Use the same URL in both store listings.
- Fill Play **Data safety** and Apple **App Privacy** from the notes at the
  end of the draft.
- In-app account deletion exists (Settings → Delete account). Play also wants
  a web URL for deletion requests. Add a page or a mailto in the policy.

## 10. Asset provenance (confirm before release)

- Fonts: EB Garamond, Manrope and a two-glyph subset of Noto Serif JP (for
  我慢) are bundled from Google Fonts under the OFL (licences in
  `assets/google_fonts/`, shown on the in-app licences page).
- Audio is all made in-house, so there's no third-party licence:
  `assets/audio/chime.mp3` by `tool/make_chime.py`, and the five binaural
  tracks by `tool/make_binaural.py` (pure sine pairs around 440 Hz).
- Quotes: `assets/quotes/stoic_quotes.json` uses only pre-1929 translations
  (George Long; Richard Mott Gummere). Spot-check the wording against the
  public-domain texts (e.g. Project Gutenberg, Wikisource) before release.

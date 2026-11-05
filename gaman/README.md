# Gaman

A Stoic practice app: a daily quote from Marcus Aurelius, Epictetus or
Seneca, guided journalling, an "eat the frog" daily task list, meditation and
focus timers, and ambient binaural tracks. Free core, with an optional Premium
tier (currently mocked).

Flutter app for Android, iOS and web (web deploys to GitHub Pages from `main`).

## Run

```
flutter pub get
flutter run
flutter analyze && flutter test
```

## How it fits together

- **Data**: one `Repository` interface (`lib/data/`). `ActiveRepository`
  follows the signed-in user. It starts on `LocalRepository`
  (SharedPreferences) and switches to `FirestoreRepository`
  (`users/{uid}/…`) once Firebase sign-in lands. `LocalToFirestoreMigration`
  moves any device-only data up.
- **Auth**: anonymous-first Firebase Auth. Users can link Google (and Apple,
  behind a flag). Settings has export and account deletion.
- **Content**: quotes are bundled offline (`assets/quotes/`, public-domain
  translations only). Fonts are bundled (`assets/google_fonts/`, OFL).
- **Strings**: `lib/l10n/app_en.arb` (`flutter gen-l10n`). Older screens
  still have inline strings to move over.

## Before a store release

Placeholders and console steps are listed in **[SETUP.md](SETUP.md)**.
Firebase project bootstrap is in `docs/cloud-sync-firebase-setup.md`, the
privacy policy draft in `docs/privacy-policy-draft.md`, and the web deploy in
`DEPLOYMENT.md`. Gaps between this and a sellable product: `docs/market-readiness-audit.md`.

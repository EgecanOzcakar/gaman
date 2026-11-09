# Gaman

我慢: bearing what is hard, with patience and dignity. Calm apps help you feel
better; Gaman helps you get better at hard things. A Stoic practice of chosen
discomfort:

- **Endure**: an "I have an urge" button. Name the urge, ride it out for ten
  minutes, log whether you held.
- **Trials**: one small hard thing chosen each day (gentle, firm, hard), with
  safety notes. **Programs** (Premium) sequence them over 14 to 30 days.
- **The daily loop** on Today: morning *premeditatio*, today's trial, the one
  task that matters, evening review.
- **Never miss twice**: one missed day is mended in gold on the kintsugi
  chain instead of breaking a streak.
- **Insights** measure endurance (urges held, trials by level, triggers,
  hardest time of day), not activity counts.
- Breathing, ambient tracks and a focus timer support the practice.

No AI and no ads. Free core, with an optional Premium tier (currently mocked).
See `docs/store-listing.md` for positioning and store copy.

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
- **Practice data**: urges and trials are `ActivityEvent`s (`urge`, `trial`
  types) in the same append-only log, so they sync and export with
  everything else. Catalogue and pure stats live in `lib/endurance.dart`; the
  active program is in `AppSettings`.
- **Content**: quotes are bundled offline (`assets/quotes/`, public-domain
  translations only). Fonts are bundled (`assets/google_fonts/`, OFL).
- **Strings**: `lib/l10n/app_en.arb` (`flutter gen-l10n`). Older screens
  still have inline strings to move over.

## Before a store release

Placeholders and console steps are listed in **[SETUP.md](SETUP.md)**.
Firebase project bootstrap is in `docs/cloud-sync-firebase-setup.md`, the
privacy policy draft in `docs/privacy-policy-draft.md`, and the web deploy in
`DEPLOYMENT.md`.

# Gaman: market-readiness audit

_Audited 2026-11-05 against `main` @ 32f96e2._

## Verdict

The engineering base is solid. It has a clean repository layer, offline-first
sync, anonymous-first auth with account linking, in-app export and deletion,
opt-in crash reports, bundled public-domain content, a privacy draft that
matches the code, and CI with tests. `SETUP.md` already lists most of the
console work.

As a product, though, it isn't ready to sell. Three gaps matter more than
any bug:

1. **Nobody can pay.** Billing is a mock. What Premium unlocks (a single
   sentence of week-over-week summary plus three looping sine-wave tracks)
   isn't worth $24.99/yr, even once billing works.
2. **There's not much content.** 73 quotes means a repeat every 10 weeks,
   and there are 5 audio loops and a handful of journal templates. Paid
   Stoic apps sell depth: courses, a daily lesson, guided audio.
3. **It does five things and isn't known for any of them.** Quote, journal,
   to-do, meditation, Pomodoro and binaural beats each compete with a
   category leader (Daily Stoic / Stoic., Day One, Todoist, Headspace,
   Forest). The Stoic angle is the only differentiator, but outside the
   quote card none of the features are Stoic.

Expect about 2 weeks to clear the store blockers and 4–6 weeks to have a
product worth charging for.

---

## 1. Launch blockers (rejection or broken build)

| # | Issue | Where | Fix |
|---|---|---|---|
| B1 | **iOS hasn't been built since Firebase was added.** `Podfile.lock` has no Firebase pods but does list plugins that are no longer used (workmanager, sqflite, permission_handler). The deployment target is iOS 12.0, but current FlutterFire (firebase_core 4.x / Firebase iOS SDK 12) needs iOS 15, so `pod install` should fail. | `ios/Podfile`, `project.pbxproj` | Set `platform :ios, '15.0'` and `IPHONEOS_DEPLOYMENT_TARGET = 15.0`, delete `Podfile.lock`, run `pod install`, and do a real device build. |
| B2 | **Google Sign-In on iOS fails.** There's no `GoogleService-Info.plist` or `GIDClientID`, so `GoogleSignIn().signIn()` throws and the user sees a generic failure. | `ios/Runner/` | SETUP §3. |
| B3 | **Sign in with Apple is off by default.** Shipping Google sign-in on iOS without Apple sign-in breaks Guideline 4.8. | `APPLE_SIGN_IN` | SETUP §4. Make the release build script fail if the flag is missing. |
| B4 | **The paywall will be rejected (Guideline 3.1.2).** Auto-renewing subscriptions must show the subscription length, the localized price, and **links to Terms (EULA) and Privacy** on the purchase screen. The paywall has no links, and its prices are hard-coded USD strings. | `paywall_screen.dart`, `entitlement_service.dart` | Add the links, use store prices, add a free-trial line if you offer one. |
| B5 | **No billing.** Every `purchase()` call no-ops. | `entitlement_service.dart` | Use RevenueCat. It's the fastest path to receipts, a restore that works, cross-platform entitlements and paywall A/B tests, and it's free under $2.5k MTR. |
| B6 | **Placeholder URLs ship by default.** Privacy and Terms point to `example.com/REPLACE_ME`. Both stores check the privacy URL. | `config.dart` | Host the policy (GitHub Pages already works) and remove the defaults so a release build fails without them. |
| B7 | **The icon and splash literally say "PLACEHOLDER".** | `assets/branding/` | Commission or make real art. |
| B8 | **Asset provenance is unconfirmed:** the Pixabay splash image and the five MP3s. | SETUP §10 | Regenerate the beats with `sox` (pure tones, nothing to license). |
| B9 | **No iOS privacy manifest.** There's no app-level `PrivacyInfo.xcprivacy`. The app uses UserDefaults (shared_preferences), a required-reason API. | `ios/Runner/` | Add the manifest with `NSPrivacyAccessedAPICategoryUserDefaults` (CA92.1) and `NSPrivacyTracking=false`. |
| B10 | **The web manifest is still the Flutter default:** "A new Flutter project.", name `gaman`, colour `#0175C2`. | `web/manifest.json` | Fix the name, description and colours. |
| B11 | **CI never builds Android or iOS**, which is why B1 went unnoticed. | `.github/workflows/deploy.yml` | Add `flutter build apk --debug` (Ubuntu) and `flutter build ios --no-codesign` (macOS runner). |

## 2. Bugs that cost trust or retention

| # | Bug | Where | Impact |
|---|---|---|---|
| R1 | **Toggling a task logs `taskDone` every time.** Check, uncheck, check gives 2 done. Unchecking never removes the event. | `todo_screen.dart` `_toggleTask` | Inflates "Tasks done" and lets users fake a streak. Insights stop being honest. |
| R2 | **The reminder isn't rescheduled when synced settings arrive.** First launch schedules a random time locally. After sign-in on a new phone, the stored time loads into the UI but the OS notification stays at the old random time. Nothing is ever scheduled on later launches either. | `notification_provider.dart` | The reminder is the main retention loop, and it can silently fire at the wrong time or not at all. Call `_scheduleNotification()` from the settings listener when the time or the enabled flag changes. |
| R3 | **The meditation timer has no wakelock, no lifecycle handling and no end bell.** The screen locks, the Dart timer suspends, the session overruns, and nothing tells the user it ended. (Focus already handles this with `endsAt`.) | `meditation_screen.dart` | A meditation timer without a closing bell is broken for its core use, eyes closed. Reuse the focus timer's `endsAt` pattern and schedule a local notification with a sound for the end time. |
| R4 | **Abandoned focus sessions count as "Focus sessions".** | `insights_screen.dart` `count(ActivityType.focus…)` | Filter `meta.abandoned`. |
| R5 | **The splash takes 3.4 s on every cold start**, after the native splash. | `splash_screen.dart` | Show it on first launch only (or cap it at about 1 s). Repeat users notice the delay every time. |
| R6 | **There's no media session on Android.** Without `just_audio_background` and a foreground service, the beats can be killed in the background and have no lock-screen controls. | `audio_provider.dart` | Add `just_audio_background`. |
| R7 | **The whole activity collection streams on every launch.** It grows without limit (about 5 events a day, so roughly 2k a year). | `firestore_repository.dart` `watchActivity` | Firestore read costs and startup time grow per user. Query the last 400 days and keep a lifetime summary doc for the streak. |
| R8 | **The notification copy is generic and hard-coded in English** ("Time for Reflection"). | `notification_provider.dart` | Put today's quote in the notification body. It's the cheapest engagement win available. |
| R9 | **Many screens still hard-code English strings** (Today, Insights, Settings, Focus, Binaural). The mood picker uses bare emoji with no semantic labels. | `lib/screens/*` | Blocks localization and screen-reader use. |

## 3. Product viability

### Positioning: pick one job

Lead with a **Stoic daily practice** made of three steps:

- **Morning:** a quote with a short commentary, then a premeditatio malorum
  prompt ("What could go wrong today, and how will I respond?") and the frog.
- **Day:** focus sessions tied to the frog.
- **Evening:** Seneca's evening review (what did I do well, badly, and what
  will I do differently), plus a mood check-in.

Everything else should hang off that loop. Meditation and binaural beats are
commodity features, so keep them as tools rather than headline features.
Settings already has a "Practices on home" switch, so they can be hidden.

The name is worth one line in onboarding. *Gaman* (我慢) is Japanese
endurance, while the content is Greco-Roman. Present that as a deliberate
bridge ("enduring with dignity, East and West") or it will read as a
mismatch. Before you lock in the store listing, check the stores and
trademark registers for name and ASO collisions.

### Monetization: make Premium worth paying for

The current Premium gives a weekly summary sentence and three tones. A
credible Premium would include:

- **Courses or programmes:** for example "30 days with Epictetus", one short
  lesson and one exercise a day. This is what the category leaders sell.
- **Full library and commentary:** hundreds of passages from the public-domain
  Long, Gummere and Higginson translations, searchable and favouritable,
  each with a two-line modern gloss.
- **Guided audio:** voiced morning and evening practices.
- **Real insights:** mood vs. practice correlation, monthly review, and a
  "your year in Stoicism" export.
- **Journal lock** (Face ID / biometrics) and themes. Cheap to build and
  people expect them.

Keep the free tier generous: the daily quote, the journal, a basic streak,
and the focus timer. Put a 7-day trial on the yearly plan and show the
paywall at the end of onboarding, which is where most subscription revenue
in this category comes from, plus at the natural upsell points.

### Retention loops that are missing

- **Home-screen widget** with today's quote. For a quote app this is the
  biggest driver of daily opens. Use `home_widget`.
- **A reminder with content** (R8), plus an optional evening review reminder.
- **Streak protection:** one freeze a week. A broken streak is a common
  reason people quit.
- **Shareable quote cards** (`share_plus` is already a dependency). This is
  free acquisition.
- **Onboarding that personalizes:** ask for a goal (anxiety, discipline,
  focus) and reminder times, then show the first quote. Right now it's three
  static pages.
- **Sign-in prompt at the right moment:** after 3 journal entries, suggest
  backing up. Today the option is buried at the top of Settings, and an
  Android reinstall loses anonymous data.

### Measurement

There are no analytics, so you can't tell which of these work. That's a
deliberate privacy choice, and the policy says so. Add privacy-preserving,
opt-in or aggregate-only product analytics (a few events: onboarding
complete, first journal, D1/D7 return, paywall view and purchase), and
update the policy and store labels to match. Without it you're pricing and
iterating blind.

## 4. Store listing checklist

- [ ] Screenshots: 6.9" and 6.5" iPhone, 13" iPad (iPad support is declared
  in `UISupportedInterfaceOrientations~ipad`, so either test it or set
  `TARGETED_DEVICE_FAMILY = 1`), and Play phone screenshots.
- [ ] Subtitle, keywords, and a short and full description built around
  "Stoic", "journal", "daily stoic quote", "Marcus Aurelius".
- [ ] Play Data safety and Apple App Privacy, filled from
  `docs/privacy-policy-draft.md`.
- [ ] Play account-deletion web URL.
- [ ] Content rating questionnaire.
- [ ] Health disclaimer for binaural beats. It's in the app; keep any
  medical claims out of the listing (Guideline 1.4.1).
- [ ] Play closed testing: new personal developer accounts need 12 testers
  for 14 days before production. Start this early, because it gates launch.
- [ ] Target SDK meets Play's current requirement (check `flutter.targetSdkVersion`).

## 5. Plan

**Weeks 1–2: shippable.** B1–B11, R1–R5.
Ship free-only first if billing slips. The app is a fine free 1.0, and an
earlier launch starts the Play 14-day testing clock and the reviews.

**Weeks 3–6: sellable.** RevenueCat with the real paywall, the
morning/evening Stoic loop, the expanded quote library with commentary, the
home-screen widget, journal lock, a first 30-day course, and minimal
analytics.

**Afterwards:** guided audio, localization (Spanish, German, Portuguese and
Turkish are large self-improvement markets), and streak freezes.

# Gaman privacy policy (DRAFT)

> Draft written to match what the code does as of this commit. Have it
> reviewed before publishing. Fill in every `REPLACE_ME`. Host it at the URL
> passed as `PRIVACY_URL`.

_Last updated: REPLACE_ME_

Gaman ("the app") is made by REPLACE_ME (the developer), contact
REPLACE_ME@example.com.

## What we store

| Data | Why | Where |
|---|---|---|
| Journal entries, daily tasks, practice history (meditation, focus, journal, tasks done), app settings | They are the app | On your device, and in your private Cloud Firestore space (Google Firebase) under a random user id |
| Account id; email address and name if you sign in with Google or Apple | Keeps your data with you across reinstalls and devices | Firebase Authentication |
| Crash reports (only if you turn them on in Settings): device model, OS version, app version, stack trace, a random installation id | Fixing bugs | Firebase Crashlytics |
| Device attestation tokens (App Check) | Stops other apps abusing our backend | Firebase App Check. No personal data |

On first launch the app signs you in anonymously, so your data is synced to
the cloud under an anonymous id even before you choose to sign in.

We **don't** collect location, contacts, photos, advertising ids or analytics.
We show no ads and don't sell or share your data. Quotes, fonts and audio
are bundled in the app. Reminders are scheduled on your device.

## Who can see it

Only you. Firestore security rules allow a signed-in user to read and write
only their own data. Google (Firebase) processes data on our behalf as a
service provider. See https://firebase.google.com/support/privacy.

## Your choices

- **Export**: Settings → Your data → Export all data.
- **Delete**: Settings → Delete account permanently deletes your cloud data,
  your account, and the app's data on this device. You can also email
  REPLACE_ME to request deletion.
- **Crash reports** are off unless you turn them on, and you can turn them
  off at any time.
- **Reminders** can be turned off in Settings or in your phone's settings.

## Retention

Data stays until you delete it or your account. Crash reports are kept for 90
days by Crashlytics.

## Children

Gaman isn't directed at children under 13 (or the minimum age in your
country).

## Changes

We'll update this page and the date above. REPLACE_ME: say how material
changes are announced.

---

## Store label notes (not part of the published policy)

### Google Play: Data safety

- Data collected: **Personal info → Email address, Name** (optional, only when
  signing in with Google/Apple; purpose: account management).
  **App activity → Other user-generated content** (journal, tasks; purpose:
  app functionality). **App activity → Other actions** (practice history;
  app functionality). **App info and performance → Crash logs, Diagnostics**
  (optional, opt-in; purpose: analytics/diagnostics).
  **Device or other IDs** (Firebase installation id, Crashlytics only).
- Shared with third parties: **No** (Firebase is a service provider).
- Encrypted in transit: **Yes**.
- Users can request deletion: **Yes** (in-app, plus the web/email route
  required by Play).

### Apple: App Privacy

- **Data linked to you**: Contact Info → Email Address, Name (if signed in);
  User Content → Other User Content (journal, tasks); Usage Data → Product
  Interaction (practice history). Purpose: App Functionality.
- **Data not linked to you**: Diagnostics → Crash Data (opt-in). Purpose:
  App Functionality.
- **Tracking**: No.

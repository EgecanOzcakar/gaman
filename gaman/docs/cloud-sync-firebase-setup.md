# Cloud sync — Firebase setup (one-time, maintainer)

Until this is done, `AuthService.uid` is null at startup and the app runs
entirely on `LocalRepository` — every cloud-sync PR is inert.

1. **Create the project** — console.firebase.google.com → *Add project* "gaman"
   (skip Google Analytics).
2. **Auth providers** — Build → Authentication → Get started → enable
   **Anonymous** and **Google**.
3. **Firestore** — Build → Firestore Database → *Create database* → production
   mode → pick a region.
4. **Generate config** —
   ```
   dart pub global activate flutterfire_cli
   cd gaman && flutterfire configure
   ```
   Select the `gaman` project and the **android** + **web** platforms. This
   writes `lib/firebase_options.dart` and `android/app/google-services.json`.
5. **Use the config** — in `lib/main.dart`, change
   `Firebase.initializeApp()` → `Firebase.initializeApp(options:
   DefaultFirebaseOptions.currentPlatform)` (the `TODO(cloud-sync)` marker).
6. **Authorised domains** — Authentication → Settings → Authorized domains →
   add `egecanozcakar.github.io` (the GitHub Pages deploy).
7. **Deploy the rules** —
   ```
   npm i -g firebase-tools
   firebase login
   firebase deploy --only firestore:rules --project gaman
   ```
   Re-run step 7 whenever `firestore.rules` changes.

/// Switches for features whose console/account setup isn't done yet. Each
/// defaults to off/placeholder so a fresh checkout runs; flip them with
/// `--dart-define=NAME=value` once the matching step in SETUP.md is done.
class AppConfig {
  /// Sign in with Apple (iOS/macOS only). Needs the Apple Developer
  /// capability + Firebase Apple provider.
  static const appleSignIn = bool.fromEnvironment('APPLE_SIGN_IN');

  /// Firebase App Check. Needs the providers registered in the console;
  /// with enforcement on and no registration, every request would fail.
  static const appCheck = bool.fromEnvironment('APP_CHECK');

  // REPLACE_ME: host the policy (draft in docs/privacy-policy-draft.md).
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL',
      defaultValue: 'https://example.com/REPLACE_ME/privacy');
  static const termsUrl = String.fromEnvironment('TERMS_URL',
      defaultValue: 'https://example.com/REPLACE_ME/terms');
}

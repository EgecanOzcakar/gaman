// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gaman';

  @override
  String get navToday => 'Today';

  @override
  String get navJournal => 'Journal';

  @override
  String get navEndure => 'Endure';

  @override
  String get navFocus => 'Focus';

  @override
  String get navInsights => 'Insights';

  @override
  String get navSettings => 'Settings';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get started';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String pageOf(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get onboarding1Title => 'Gaman: patient endurance';

  @override
  String get onboarding1Body =>
      'Calm apps help you feel better. Gaman helps you get better at hard things: a daily Stoic practice of chosen discomfort.';

  @override
  String get onboarding2Title => 'Get better at hard things';

  @override
  String get onboarding2Body =>
      'Ride out urges for ten minutes. Choose one small hard thing a day. Miss a day? Mend it, just never miss twice.';

  @override
  String get onboarding3Title => 'Your reflections stay yours';

  @override
  String get onboarding3Body =>
      'No AI reads your journal and there are no ads. Everything starts private to this device. Sign in later to back it up. Next we\'ll ask to send one gentle daily reminder; you can change it any time.';

  @override
  String translatedBy(String translator) {
    return 'Tr. $translator';
  }

  @override
  String get volume => 'Volume';

  @override
  String get beatsDisclaimer =>
      'Ambient tones for relaxing and focusing. Not a medical treatment. Use headphones at a comfortable volume, and not while driving.';

  @override
  String playBeat(String name) {
    return 'Play $name';
  }

  @override
  String pauseBeat(String name) {
    return 'Pause $name';
  }

  @override
  String get weeklyReviewLockedTitle => 'Endurance patterns';

  @override
  String get weeklyReviewLockedBody =>
      'Your triggers, your hardest time of day, trials by level and week-over-week trend. Included with Premium.';

  @override
  String get premiumTitle => 'Gaman Premium';

  @override
  String get premiumFree => 'You\'re on the free plan. See Premium';

  @override
  String get premiumActive => 'Premium is active. Thank you!';

  @override
  String get devPremiumToggle => 'Dev: pretend Premium (debug builds only)';

  @override
  String get paywallTitle => 'Go deeper with Premium';

  @override
  String get paywallBody =>
      'The daily practice stays free. Premium adds tools for those who want more.';

  @override
  String get paywallPerkInsights =>
      'Endurance patterns: triggers, hardest times, trends';

  @override
  String get paywallPerkPrograms =>
      'Programs: 30 days of gaman, the phone fast, Seneca\'s three weeks';

  @override
  String get paywallPerkSupport => 'Support an independent, ad-free app';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restored => 'Premium restored';

  @override
  String get nothingToRestore => 'No purchases found';

  @override
  String get billingUnavailable =>
      'Purchases aren\'t available in this build yet';

  @override
  String get paywallFinePrint =>
      'Placeholder prices. Subscriptions renew automatically until cancelled in your store account settings. Lifetime is a single payment.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get crashReportsTitle => 'Send crash reports';

  @override
  String get crashReportsBody =>
      'Helps fix bugs. Includes device model and the error, never your journal. Off by default.';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get terms => 'Terms of use';

  @override
  String get licenses => 'Open-source licences';

  @override
  String get exportExplainer =>
      'Export a copy of your data to keep somewhere safe or move to another phone.';

  @override
  String get exportAllData => 'Export all data';

  @override
  String exportFailed(String error) {
    return 'Could not export: $error';
  }

  @override
  String get signInApple => 'Sign in with Apple';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountButton => 'Delete my account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently removes your journal, tasks, history and settings from this device and the cloud.';

  @override
  String get deleteAccountConfirmTitle => 'Delete everything?';

  @override
  String get deleteAccountConfirmBody =>
      'This permanently deletes your account and all of its data. It can\'t be undone. You may be asked to sign in again to confirm.';

  @override
  String get deleteAccountDone => 'Your account and data were deleted';

  @override
  String get deleteAccountCancelled =>
      'Your data was deleted, but sign-in was cancelled, so the account itself remains. Try again to finish.';

  @override
  String get deleteAccountFailed =>
      'Could not delete your account. Check your connection and try again.';

  @override
  String get deleteEntry => 'Delete entry';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get openBeats => 'Open binaural beats';

  @override
  String decrease(String setting) {
    return 'Decrease $setting';
  }

  @override
  String increase(String setting) {
    return 'Increase $setting';
  }

  @override
  String get markMainTaskDone => 'Mark main task done';

  @override
  String markTaskDone(int number) {
    return 'Mark task $number done';
  }
}

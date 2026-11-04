import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Gaman'**
  String get appTitle;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get navFocus;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @pageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOf(int current, int total);

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Gaman: patient endurance'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'A daily Stoic practice. One quote, one honest look at your day, one task that matters.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Small practices, every day'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Journal with Stoic prompts, sit for a short meditation, and work in calm, focused blocks.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Your reflections stay yours'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Everything starts private to this device. Sign in later to back it up. Next we\'ll ask to send one gentle daily reminder; you can change it any time.'**
  String get onboarding3Body;

  /// No description provided for @translatedBy.
  ///
  /// In en, this message translates to:
  /// **'Tr. {translator}'**
  String translatedBy(String translator);

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @beatsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Ambient tones for relaxing and focusing. Not a medical treatment. Use headphones at a comfortable volume, and not while driving.'**
  String get beatsDisclaimer;

  /// No description provided for @playBeat.
  ///
  /// In en, this message translates to:
  /// **'Play {name}'**
  String playBeat(String name);

  /// No description provided for @pauseBeat.
  ///
  /// In en, this message translates to:
  /// **'Pause {name}'**
  String pauseBeat(String name);

  /// No description provided for @premiumLockedTooltip.
  ///
  /// In en, this message translates to:
  /// **'{name} is a Premium track'**
  String premiumLockedTooltip(String name);

  /// No description provided for @weeklyReviewLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly review'**
  String get weeklyReviewLockedTitle;

  /// No description provided for @weeklyReviewLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Compare this week with last and see your trend. Included with Premium.'**
  String get weeklyReviewLockedBody;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Gaman Premium'**
  String get premiumTitle;

  /// No description provided for @premiumFree.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the free plan. See Premium'**
  String get premiumFree;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium is active. Thank you!'**
  String get premiumActive;

  /// No description provided for @devPremiumToggle.
  ///
  /// In en, this message translates to:
  /// **'Dev: pretend Premium (debug builds only)'**
  String get devPremiumToggle;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Go deeper with Premium'**
  String get paywallTitle;

  /// No description provided for @paywallBody.
  ///
  /// In en, this message translates to:
  /// **'The daily practice stays free. Premium adds tools for those who want more.'**
  String get paywallBody;

  /// No description provided for @paywallPerkInsights.
  ///
  /// In en, this message translates to:
  /// **'Weekly review and trends in Insights'**
  String get paywallPerkInsights;

  /// No description provided for @paywallPerkBeats.
  ///
  /// In en, this message translates to:
  /// **'All five ambient tracks'**
  String get paywallPerkBeats;

  /// No description provided for @paywallPerkSupport.
  ///
  /// In en, this message translates to:
  /// **'Support an independent, ad-free app'**
  String get paywallPerkSupport;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restored.
  ///
  /// In en, this message translates to:
  /// **'Premium restored'**
  String get restored;

  /// No description provided for @nothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'No purchases found'**
  String get nothingToRestore;

  /// No description provided for @billingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Purchases aren\'t available in this build yet'**
  String get billingUnavailable;

  /// No description provided for @paywallFinePrint.
  ///
  /// In en, this message translates to:
  /// **'Placeholder prices. Subscriptions renew automatically until cancelled in your store account settings.'**
  String get paywallFinePrint;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @crashReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send crash reports'**
  String get crashReportsTitle;

  /// No description provided for @crashReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Helps fix bugs. Includes device model and the error, never your journal. Off by default.'**
  String get crashReportsBody;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get terms;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licenses;

  /// No description provided for @exportExplainer.
  ///
  /// In en, this message translates to:
  /// **'Export a copy of your data to keep somewhere safe or move to another phone.'**
  String get exportExplainer;

  /// No description provided for @exportAllData.
  ///
  /// In en, this message translates to:
  /// **'Export all data'**
  String get exportAllData;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export: {error}'**
  String exportFailed(String error);

  /// No description provided for @signInApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInApple;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently removes your journal, tasks, history and settings from this device and the cloud.'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account and all of its data. It can\'t be undone. You may be asked to sign in again to confirm.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Your account and data were deleted'**
  String get deleteAccountDone;

  /// No description provided for @deleteAccountCancelled.
  ///
  /// In en, this message translates to:
  /// **'Your data was deleted, but sign-in was cancelled, so the account itself remains. Try again to finish.'**
  String get deleteAccountCancelled;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Check your connection and try again.'**
  String get deleteAccountFailed;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntry;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @openBeats.
  ///
  /// In en, this message translates to:
  /// **'Open binaural beats'**
  String get openBeats;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease {setting}'**
  String decrease(String setting);

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase {setting}'**
  String increase(String setting);

  /// No description provided for @markMainTaskDone.
  ///
  /// In en, this message translates to:
  /// **'Mark main task done'**
  String get markMainTaskDone;

  /// No description provided for @markTaskDone.
  ///
  /// In en, this message translates to:
  /// **'Mark task {number} done'**
  String markTaskDone(int number);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

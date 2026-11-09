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

  /// No description provided for @navEndure.
  ///
  /// In en, this message translates to:
  /// **'Endure'**
  String get navEndure;

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
  /// **'Calm apps help you feel better. Gaman helps you get better at hard things: a daily Stoic practice of chosen discomfort.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Get better at hard things'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Ride out urges for ten minutes. Choose one small hard thing a day. Miss a day? Mend it, just never miss twice.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Your reflections stay yours'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'No AI reads your journal and there are no ads. Everything starts private to this device. Sign in later to back it up. Next we\'ll ask to send one gentle daily reminder; you can change it any time.'**
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

  /// No description provided for @weeklyReviewLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Endurance patterns'**
  String get weeklyReviewLockedTitle;

  /// No description provided for @weeklyReviewLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Your triggers, your hardest time of day, trials by level and week-over-week trend. Included with Premium.'**
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
  /// **'Endurance patterns: triggers, hardest times, trends'**
  String get paywallPerkInsights;

  /// No description provided for @paywallPerkPrograms.
  ///
  /// In en, this message translates to:
  /// **'Programs: 30 days of gaman, the phone fast, Seneca\'s three weeks'**
  String get paywallPerkPrograms;

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
  /// **'Placeholder prices. Subscriptions renew automatically until cancelled in your store account settings. Lifetime is a single payment.'**
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

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @todaysPractice.
  ///
  /// In en, this message translates to:
  /// **'Today\'s practice'**
  String get todaysPractice;

  /// No description provided for @morningStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning: premeditatio'**
  String get morningStepTitle;

  /// No description provided for @morningStepBody.
  ///
  /// In en, this message translates to:
  /// **'What could go wrong today, and how will you meet it?'**
  String get morningStepBody;

  /// No description provided for @eveningStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening review'**
  String get eveningStepTitle;

  /// No description provided for @eveningStepBody.
  ///
  /// In en, this message translates to:
  /// **'What went well, what could be better, what was left undone.'**
  String get eveningStepBody;

  /// No description provided for @eveningStepToday.
  ///
  /// In en, this message translates to:
  /// **'Today: {summary}.'**
  String eveningStepToday(String summary);

  /// No description provided for @eveningUrgesHeld.
  ///
  /// In en, this message translates to:
  /// **'{held} of {total} urges held'**
  String eveningUrgesHeld(int held, int total);

  /// No description provided for @eveningTrialDone.
  ///
  /// In en, this message translates to:
  /// **'trial done'**
  String get eveningTrialDone;

  /// No description provided for @eveningTrialOpen.
  ///
  /// In en, this message translates to:
  /// **'trial still open'**
  String get eveningTrialOpen;

  /// No description provided for @summarySeparator.
  ///
  /// In en, this message translates to:
  /// **' · '**
  String get summarySeparator;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @oneTaskDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'The one task that matters today'**
  String get oneTaskDialogTitle;

  /// No description provided for @oneTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Do the hard thing first'**
  String get oneTaskHint;

  /// No description provided for @oneTaskEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'One task that matters'**
  String get oneTaskEmptyTitle;

  /// No description provided for @oneTaskEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Not set. Tap to choose it.'**
  String get oneTaskEmptyBody;

  /// No description provided for @oneTaskChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get oneTaskChange;

  /// No description provided for @chainDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String chainDays(int days);

  /// No description provided for @chainMended.
  ///
  /// In en, this message translates to:
  /// **'{count} mended'**
  String chainMended(int count);

  /// No description provided for @chainAtRisk.
  ///
  /// In en, this message translates to:
  /// **'practise today to mend'**
  String get chainAtRisk;

  /// No description provided for @chainSemantics.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days: {done} practised, {mended} mended'**
  String chainSemantics(int days, int done, int mended);

  /// No description provided for @chainCardDays.
  ///
  /// In en, this message translates to:
  /// **'day chain'**
  String get chainCardDays;

  /// No description provided for @chainCardDaysMended.
  ///
  /// In en, this message translates to:
  /// **'day chain, {count} mended'**
  String chainCardDaysMended(int count);

  /// No description provided for @chainCardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chain yet. Practise once today.'**
  String get chainCardEmpty;

  /// No description provided for @chainCardAtRisk.
  ///
  /// In en, this message translates to:
  /// **'You missed yesterday. Practise today and it\'s mended in gold.'**
  String get chainCardAtRisk;

  /// No description provided for @chainCardExplain.
  ///
  /// In en, this message translates to:
  /// **'Never miss twice: a single missed day is mended in gold, not lost.'**
  String get chainCardExplain;

  /// No description provided for @trialCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s trial'**
  String get trialCardTitle;

  /// No description provided for @trialProgramDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {program}'**
  String trialProgramDay(int day, String program);

  /// No description provided for @trialAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get trialAccept;

  /// No description provided for @trialChooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another'**
  String get trialChooseAnother;

  /// No description provided for @trialEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'One small hard thing, chosen on purpose.'**
  String get trialEmptyBody;

  /// No description provided for @trialChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose today\'s trial'**
  String get trialChoose;

  /// No description provided for @trialLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'{level} trial'**
  String trialLevelLabel(String level);

  /// No description provided for @trialDoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Done. Gaman.'**
  String get trialDoneLabel;

  /// No description provided for @trialIDidIt.
  ///
  /// In en, this message translates to:
  /// **'I did it'**
  String get trialIDidIt;

  /// No description provided for @trialChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get trialChange;

  /// No description provided for @endureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'我慢: bearing what is hard, with patience and dignity.'**
  String get endureSubtitle;

  /// No description provided for @urgeButton.
  ///
  /// In en, this message translates to:
  /// **'I have an urge'**
  String get urgeButton;

  /// No description provided for @urgeButtonEmpty.
  ///
  /// In en, this message translates to:
  /// **'Ride it out for ten minutes before you decide.'**
  String get urgeButtonEmpty;

  /// No description provided for @urgeButtonToday.
  ///
  /// In en, this message translates to:
  /// **'Today: {held} of {total} held.'**
  String urgeButtonToday(int held, int total);

  /// No description provided for @programsTitle.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programsTitle;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools for the hard moments'**
  String get toolsTitle;

  /// No description provided for @toolBreathe.
  ///
  /// In en, this message translates to:
  /// **'Breathe'**
  String get toolBreathe;

  /// No description provided for @toolBreatheBody.
  ///
  /// In en, this message translates to:
  /// **'A short guided sit'**
  String get toolBreatheBody;

  /// No description provided for @toolSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get toolSound;

  /// No description provided for @toolSoundBody.
  ///
  /// In en, this message translates to:
  /// **'Ambient tracks to sit or work with'**
  String get toolSoundBody;

  /// No description provided for @programDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String programDays(int days);

  /// No description provided for @programDayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {days}'**
  String programDayOf(int day, int days);

  /// No description provided for @programStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get programStop;

  /// No description provided for @programCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get programCompleted;

  /// No description provided for @programClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get programClear;

  /// No description provided for @programPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get programPremium;

  /// No description provided for @programStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get programStart;

  /// No description provided for @programSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch to this'**
  String get programSwitch;

  /// No description provided for @urgePickTitle.
  ///
  /// In en, this message translates to:
  /// **'What is pulling at you?'**
  String get urgePickTitle;

  /// No description provided for @urgePickBody.
  ///
  /// In en, this message translates to:
  /// **'Name it, then give it ten minutes before you decide. Most urges pass on their own.'**
  String get urgePickBody;

  /// No description provided for @urgePassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get urgePassed;

  /// No description provided for @urgeAskHeld.
  ///
  /// In en, this message translates to:
  /// **'The wave has passed. Did you hold?'**
  String get urgeAskHeld;

  /// No description provided for @urgeHeld.
  ///
  /// In en, this message translates to:
  /// **'I held'**
  String get urgeHeld;

  /// No description provided for @urgeHeldEarly.
  ///
  /// In en, this message translates to:
  /// **'It passed. I held'**
  String get urgeHeldEarly;

  /// No description provided for @urgeGaveIn.
  ///
  /// In en, this message translates to:
  /// **'I gave in'**
  String get urgeGaveIn;

  /// No description provided for @urgeHeldSnack.
  ///
  /// In en, this message translates to:
  /// **'Gaman. That one is yours.'**
  String get urgeHeldSnack;

  /// No description provided for @urgeGaveInSnack.
  ///
  /// In en, this message translates to:
  /// **'Noted, not judged. Next time, ride it a little longer.'**
  String get urgeGaveInSnack;

  /// No description provided for @urgeTagPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get urgeTagPhone;

  /// No description provided for @urgeTagFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get urgeTagFood;

  /// No description provided for @urgeTagSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get urgeTagSmoking;

  /// No description provided for @urgeTagDrink.
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get urgeTagDrink;

  /// No description provided for @urgeTagAnger.
  ///
  /// In en, this message translates to:
  /// **'Anger'**
  String get urgeTagAnger;

  /// No description provided for @urgeTagQuitting.
  ///
  /// In en, this message translates to:
  /// **'Quitting'**
  String get urgeTagQuitting;

  /// No description provided for @urgeTagOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get urgeTagOther;

  /// No description provided for @urgeGuidance0.
  ///
  /// In en, this message translates to:
  /// **'Notice where you feel it. Name it: \"this is an urge.\"'**
  String get urgeGuidance0;

  /// No description provided for @urgeGuidance1.
  ///
  /// In en, this message translates to:
  /// **'Urges are waves. They rise, peak and fall, usually within minutes.'**
  String get urgeGuidance1;

  /// No description provided for @urgeGuidance2.
  ///
  /// In en, this message translates to:
  /// **'Breathe out longer than you breathe in.'**
  String get urgeGuidance2;

  /// No description provided for @urgeGuidance3.
  ///
  /// In en, this message translates to:
  /// **'\"No one is free who is a slave to the body.\" (Seneca)'**
  String get urgeGuidance3;

  /// No description provided for @urgeGuidance4.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have to win forever. Just these ten minutes.'**
  String get urgeGuidance4;

  /// No description provided for @urgeGuidance5.
  ///
  /// In en, this message translates to:
  /// **'It is already weaker than when you started.'**
  String get urgeGuidance5;

  /// No description provided for @levelGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get levelGentle;

  /// No description provided for @levelFirm.
  ///
  /// In en, this message translates to:
  /// **'Firm'**
  String get levelFirm;

  /// No description provided for @levelHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get levelHard;

  /// No description provided for @trialSafetyNote.
  ///
  /// In en, this message translates to:
  /// **'Trials should feel uncomfortable, never harmful. Skip any that don\'t suit your health and stop if something feels wrong. This isn\'t medical advice.'**
  String get trialSafetyNote;

  /// No description provided for @trialColdCaution.
  ///
  /// In en, this message translates to:
  /// **'Skip this if you have a heart condition, are pregnant or feel unwell.'**
  String get trialColdCaution;

  /// No description provided for @trialPhoneFirstHour.
  ///
  /// In en, this message translates to:
  /// **'Keep your phone in another room for the first hour of the day'**
  String get trialPhoneFirstHour;

  /// No description provided for @trialStairs.
  ///
  /// In en, this message translates to:
  /// **'Take the stairs all day'**
  String get trialStairs;

  /// No description provided for @trialScreenlessMeal.
  ///
  /// In en, this message translates to:
  /// **'Eat one meal with no screen'**
  String get trialScreenlessMeal;

  /// No description provided for @trialSnackWait.
  ///
  /// In en, this message translates to:
  /// **'Wait ten minutes before any snack'**
  String get trialSnackWait;

  /// No description provided for @trialNothingLater.
  ///
  /// In en, this message translates to:
  /// **'Make your bed and leave no dish for later'**
  String get trialNothingLater;

  /// No description provided for @trialColdFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish your shower with 30 seconds of cold water'**
  String get trialColdFinish;

  /// No description provided for @trialNoSocial.
  ///
  /// In en, this message translates to:
  /// **'No social media today'**
  String get trialNoSocial;

  /// No description provided for @trialAvoidedFirst.
  ///
  /// In en, this message translates to:
  /// **'Do the task you\'re avoiding before anything else'**
  String get trialAvoidedFirst;

  /// No description provided for @trialEatPlain.
  ///
  /// In en, this message translates to:
  /// **'Eat plainly today: no sweets, no snacks'**
  String get trialEatPlain;

  /// No description provided for @trialWalkWeather.
  ///
  /// In en, this message translates to:
  /// **'Walk 30 minutes, whatever the weather (dress for it)'**
  String get trialWalkWeather;

  /// No description provided for @trialAwkwardThing.
  ///
  /// In en, this message translates to:
  /// **'Say the awkward thing you\'ve been putting off, kindly'**
  String get trialAwkwardThing;

  /// No description provided for @trialPractisePoverty.
  ///
  /// In en, this message translates to:
  /// **'Eat simply and dress simply. Ask: is this what I feared? (Seneca)'**
  String get trialPractisePoverty;

  /// No description provided for @trialPhoneBedroom.
  ///
  /// In en, this message translates to:
  /// **'Sleep with your phone outside the bedroom'**
  String get trialPhoneBedroom;

  /// No description provided for @trialNoComplaining.
  ///
  /// In en, this message translates to:
  /// **'A full day without complaining. Slip? Start again.'**
  String get trialNoComplaining;

  /// No description provided for @trialColdFull.
  ///
  /// In en, this message translates to:
  /// **'A full two-minute cold shower'**
  String get trialColdFull;

  /// No description provided for @trialPhoneDay.
  ///
  /// In en, this message translates to:
  /// **'A day with no browser or social apps (calls and messages are fine)'**
  String get trialPhoneDay;

  /// No description provided for @trialOneThing.
  ///
  /// In en, this message translates to:
  /// **'A day of doing one thing at a time: no multitasking'**
  String get trialOneThing;

  /// No description provided for @programThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days of gaman'**
  String get programThirtyDays;

  /// No description provided for @programThirtyDaysBlurb.
  ///
  /// In en, this message translates to:
  /// **'A month that starts gentle and ends hard, one trial a day.'**
  String get programThirtyDaysBlurb;

  /// No description provided for @programPhoneFast.
  ///
  /// In en, this message translates to:
  /// **'The phone fast'**
  String get programPhoneFast;

  /// No description provided for @programPhoneFastBlurb.
  ///
  /// In en, this message translates to:
  /// **'Two weeks to loosen the phone\'s grip, a little more each day.'**
  String get programPhoneFastBlurb;

  /// No description provided for @programSenecasMonth.
  ///
  /// In en, this message translates to:
  /// **'Seneca\'s three weeks'**
  String get programSenecasMonth;

  /// No description provided for @programSenecasMonthBlurb.
  ///
  /// In en, this message translates to:
  /// **'Voluntary simplicity: rehearse having less, so you fear it less.'**
  String get programSenecasMonthBlurb;

  /// No description provided for @partMorning.
  ///
  /// In en, this message translates to:
  /// **'morning'**
  String get partMorning;

  /// No description provided for @partAfternoon.
  ///
  /// In en, this message translates to:
  /// **'afternoon'**
  String get partAfternoon;

  /// No description provided for @partEvening.
  ///
  /// In en, this message translates to:
  /// **'evening'**
  String get partEvening;

  /// No description provided for @partNight.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get partNight;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get insightsThisWeek;

  /// No description provided for @statUrgesHeld.
  ///
  /// In en, this message translates to:
  /// **'Urges held'**
  String get statUrgesHeld;

  /// No description provided for @statTrialsDone.
  ///
  /// In en, this message translates to:
  /// **'Trials done'**
  String get statTrialsDone;

  /// No description provided for @statJournalDays.
  ///
  /// In en, this message translates to:
  /// **'Journal days'**
  String get statJournalDays;

  /// No description provided for @statFocusSessions.
  ///
  /// In en, this message translates to:
  /// **'Focus sessions'**
  String get statFocusSessions;

  /// No description provided for @statOf.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String statOf(int total);

  /// No description provided for @patternsTitle.
  ///
  /// In en, this message translates to:
  /// **'Endurance patterns'**
  String get patternsTitle;

  /// No description provided for @patternsTriggers.
  ///
  /// In en, this message translates to:
  /// **'Triggers'**
  String get patternsTriggers;

  /// No description provided for @patternsTagHeld.
  ///
  /// In en, this message translates to:
  /// **'{held} of {total} held'**
  String patternsTagHeld(int held, int total);

  /// No description provided for @patternsHardestTime.
  ///
  /// In en, this message translates to:
  /// **'Hardest time: the {part}. Plan for it in your premeditatio.'**
  String patternsHardestTime(String part);

  /// No description provided for @patternsByLevel.
  ///
  /// In en, this message translates to:
  /// **'Trials by level'**
  String get patternsByLevel;

  /// No description provided for @summaryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet this week. Start with one small hard thing today.'**
  String get summaryEmpty;

  /// No description provided for @summaryWeek.
  ///
  /// In en, this message translates to:
  /// **'So far this week you\'ve {list}.'**
  String summaryWeek(String list);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @listLastSeparator.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get listLastSeparator;

  /// No description provided for @summaryUrges.
  ///
  /// In en, this message translates to:
  /// **'held {held} of {total} urges'**
  String summaryUrges(int held, int total);

  /// No description provided for @summaryTrials.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{completed 1 trial} other{completed {count} trials}}'**
  String summaryTrials(int count);

  /// No description provided for @summaryFocus.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{did 1 focus session} other{did {count} focus sessions}}'**
  String summaryFocus(int count);

  /// No description provided for @summaryMeditation.
  ///
  /// In en, this message translates to:
  /// **'sat for {minutes} minutes'**
  String summaryMeditation(int minutes);

  /// No description provided for @summaryJournal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{journalled 1 day} other{journalled {count} days}}'**
  String summaryJournal(int count);

  /// No description provided for @summaryTasks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{finished 1 task} other{finished {count} tasks}}'**
  String summaryTasks(int count);

  /// No description provided for @trendUp.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 practised day, more than last week} other{{days} practised days, more than last week}}'**
  String trendUp(int days);

  /// No description provided for @trendDown.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 practised day, fewer than last week} other{{days} practised days, fewer than last week}}'**
  String trendDown(int days);

  /// No description provided for @trendSame.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 practised day, the same as last week} other{{days} practised days, the same as last week}}'**
  String trendSame(int days);
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

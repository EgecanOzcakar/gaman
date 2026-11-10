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

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get todaysPractice => 'Today\'s practice';

  @override
  String get morningStepTitle => 'Morning: premeditatio';

  @override
  String get morningStepBody =>
      'What could go wrong today, and how will you meet it?';

  @override
  String get eveningStepTitle => 'Evening review';

  @override
  String get eveningStepBody =>
      'What went well, what could be better, what was left undone.';

  @override
  String eveningStepToday(String summary) {
    return 'Today: $summary.';
  }

  @override
  String eveningUrgesHeld(int held, int total) {
    return '$held of $total urges held';
  }

  @override
  String get eveningTrialDone => 'trial done';

  @override
  String get eveningTrialOpen => 'trial still open';

  @override
  String get summarySeparator => ' · ';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get oneTaskDialogTitle => 'The one task that matters today';

  @override
  String get oneTaskHint => 'Do the hard thing first';

  @override
  String get oneTaskEmptyTitle => 'One task that matters';

  @override
  String get oneTaskEmptyBody => 'Not set. Tap to choose it.';

  @override
  String get oneTaskChange => 'Tap to change';

  @override
  String chainDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String chainMended(int count) {
    return '$count mended';
  }

  @override
  String get chainAtRisk => 'practise today to mend';

  @override
  String chainSemantics(int days, int done, int mended) {
    return 'Last $days days: $done practised, $mended mended';
  }

  @override
  String get chainCardDays => 'day chain';

  @override
  String chainCardDaysMended(int count) {
    return 'day chain, $count mended';
  }

  @override
  String get chainCardEmpty => 'No chain yet. Practise once today.';

  @override
  String get chainCardAtRisk =>
      'You missed yesterday. Practise today and it\'s mended in gold.';

  @override
  String get chainCardExplain =>
      'Never miss twice: a single missed day is mended in gold, not lost.';

  @override
  String get trialCardTitle => 'Today\'s trial';

  @override
  String trialProgramDay(int day, String program) {
    return 'Day $day of $program';
  }

  @override
  String get trialAccept => 'Accept';

  @override
  String get trialChooseAnother => 'Choose another';

  @override
  String get trialEmptyBody => 'One small hard thing, chosen on purpose.';

  @override
  String get trialChoose => 'Choose today\'s trial';

  @override
  String trialLevelLabel(String level) {
    return '$level trial';
  }

  @override
  String get trialDoneLabel => 'Done. Gaman.';

  @override
  String get trialIDidIt => 'I did it';

  @override
  String get trialChange => 'Change';

  @override
  String get endureSubtitle =>
      '我慢: bearing what is hard, with patience and dignity.';

  @override
  String get urgeButton => 'I have an urge';

  @override
  String get urgeButtonEmpty =>
      'Ride it out for ten minutes before you decide.';

  @override
  String urgeButtonToday(int held, int total) {
    return 'Today: $held of $total held.';
  }

  @override
  String get programsTitle => 'Programs';

  @override
  String get toolsTitle => 'Tools for the hard moments';

  @override
  String get toolBreathe => 'Breathe';

  @override
  String get toolBreatheBody => 'A short guided sit';

  @override
  String get toolSound => 'Sound';

  @override
  String get toolSoundBody => 'Ambient tracks to sit or work with';

  @override
  String programDays(int days) {
    return '$days days';
  }

  @override
  String programDayOf(int day, int days) {
    return 'Day $day of $days';
  }

  @override
  String get programStop => 'Stop';

  @override
  String get programCompleted => 'Completed';

  @override
  String get programClear => 'Clear';

  @override
  String get programPremium => 'Premium';

  @override
  String get programStart => 'Start';

  @override
  String get programSwitch => 'Switch to this';

  @override
  String get urgePickTitle => 'What is pulling at you?';

  @override
  String get urgePickBody =>
      'Name it, then give it ten minutes before you decide. Most urges pass on their own.';

  @override
  String get urgePassed => 'Passed';

  @override
  String get urgeAskHeld => 'The wave has passed. Did you hold?';

  @override
  String get urgeHeld => 'I held';

  @override
  String get urgeHeldEarly => 'It passed. I held';

  @override
  String get urgeGaveIn => 'I gave in';

  @override
  String get urgeHeldSnack => 'Gaman. That one is yours.';

  @override
  String get urgeGaveInSnack =>
      'Noted, not judged. Next time, ride it a little longer.';

  @override
  String get urgeTagPhone => 'Phone';

  @override
  String get urgeTagFood => 'Food';

  @override
  String get urgeTagSmoking => 'Smoking';

  @override
  String get urgeTagDrink => 'Drink';

  @override
  String get urgeTagAnger => 'Anger';

  @override
  String get urgeTagQuitting => 'Quitting';

  @override
  String get urgeTagOther => 'Other';

  @override
  String get urgeGuidance0 =>
      'Notice where you feel it. Name it: \"this is an urge.\"';

  @override
  String get urgeGuidance1 =>
      'Urges are waves. They rise, peak and fall, usually within minutes.';

  @override
  String get urgeGuidance2 => 'Breathe out longer than you breathe in.';

  @override
  String get urgeGuidance3 =>
      '\"No one is free who is a slave to the body.\" (Seneca)';

  @override
  String get urgeGuidance4 =>
      'You don\'t have to win forever. Just these ten minutes.';

  @override
  String get urgeGuidance5 => 'It is already weaker than when you started.';

  @override
  String get levelGentle => 'Gentle';

  @override
  String get levelFirm => 'Firm';

  @override
  String get levelHard => 'Hard';

  @override
  String get trialSafetyNote =>
      'Trials should feel uncomfortable, never harmful. Skip any that don\'t suit your health and stop if something feels wrong. This isn\'t medical advice.';

  @override
  String get trialColdCaution =>
      'Skip this if you have a heart condition, are pregnant or feel unwell.';

  @override
  String get trialPhoneFirstHour =>
      'Keep your phone in another room for the first hour of the day';

  @override
  String get trialStairs => 'Take the stairs all day';

  @override
  String get trialScreenlessMeal => 'Eat one meal with no screen';

  @override
  String get trialSnackWait => 'Wait ten minutes before any snack';

  @override
  String get trialNothingLater => 'Make your bed and leave no dish for later';

  @override
  String get trialColdFinish =>
      'Finish your shower with 30 seconds of cold water';

  @override
  String get trialNoSocial => 'No social media today';

  @override
  String get trialAvoidedFirst =>
      'Do the task you\'re avoiding before anything else';

  @override
  String get trialEatPlain => 'Eat plainly today: no sweets, no snacks';

  @override
  String get trialWalkWeather =>
      'Walk 30 minutes, whatever the weather (dress for it)';

  @override
  String get trialAwkwardThing =>
      'Say the awkward thing you\'ve been putting off, kindly';

  @override
  String get trialPractisePoverty =>
      'Eat simply and dress simply. Ask: is this what I feared? (Seneca)';

  @override
  String get trialPhoneBedroom => 'Sleep with your phone outside the bedroom';

  @override
  String get trialNoComplaining =>
      'A full day without complaining. Slip? Start again.';

  @override
  String get trialColdFull => 'A full two-minute cold shower';

  @override
  String get trialPhoneDay =>
      'A day with no browser or social apps (calls and messages are fine)';

  @override
  String get trialOneThing =>
      'A day of doing one thing at a time: no multitasking';

  @override
  String get programThirtyDays => '30 days of gaman';

  @override
  String get programThirtyDaysBlurb =>
      'A month that starts gentle and ends hard, one trial a day.';

  @override
  String get programPhoneFast => 'The phone fast';

  @override
  String get programPhoneFastBlurb =>
      'Two weeks to loosen the phone\'s grip, a little more each day.';

  @override
  String get programSenecasMonth => 'Seneca\'s three weeks';

  @override
  String get programSenecasMonthBlurb =>
      'Voluntary simplicity: rehearse having less, so you fear it less.';

  @override
  String get partMorning => 'morning';

  @override
  String get partAfternoon => 'afternoon';

  @override
  String get partEvening => 'evening';

  @override
  String get partNight => 'night';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsThisWeek => 'This week';

  @override
  String get statUrgesHeld => 'Urges held';

  @override
  String get statTrialsDone => 'Trials done';

  @override
  String get statJournalDays => 'Journal days';

  @override
  String get statFocusSessions => 'Focus sessions';

  @override
  String statOf(int total) {
    return 'of $total';
  }

  @override
  String get patternsTitle => 'Endurance patterns';

  @override
  String get patternsTriggers => 'Triggers';

  @override
  String patternsTagHeld(int held, int total) {
    return '$held of $total held';
  }

  @override
  String patternsHardestTime(String part) {
    return 'Hardest time: the $part. Plan for it in your premeditatio.';
  }

  @override
  String get patternsByLevel => 'Trials by level';

  @override
  String get summaryEmpty =>
      'Nothing logged yet this week. Start with one small hard thing today.';

  @override
  String summaryWeek(String list) {
    return 'So far this week you\'ve $list.';
  }

  @override
  String get listSeparator => ', ';

  @override
  String get listLastSeparator => ' and ';

  @override
  String summaryUrges(int held, int total) {
    return 'held $held of $total urges';
  }

  @override
  String summaryTrials(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'completed $count trials',
      one: 'completed 1 trial',
    );
    return '$_temp0';
  }

  @override
  String summaryFocus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'did $count focus sessions',
      one: 'did 1 focus session',
    );
    return '$_temp0';
  }

  @override
  String summaryMeditation(int minutes) {
    return 'sat for $minutes minutes';
  }

  @override
  String summaryJournal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'journalled $count days',
      one: 'journalled 1 day',
    );
    return '$_temp0';
  }

  @override
  String summaryTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'finished $count tasks',
      one: 'finished 1 task',
    );
    return '$_temp0';
  }

  @override
  String trendUp(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days practised days, more than last week',
      one: '1 practised day, more than last week',
    );
    return '$_temp0';
  }

  @override
  String trendDown(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days practised days, fewer than last week',
      one: '1 practised day, fewer than last week',
    );
    return '$_temp0';
  }

  @override
  String trendSame(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days practised days, the same as last week',
      one: '1 practised day, the same as last week',
    );
    return '$_temp0';
  }

  @override
  String get settingsSoundTitle => 'Sound';

  @override
  String get chimeTitle => 'Bell when a timer ends';

  @override
  String get chimeBody =>
      'A soft bell after urges, focus sessions and meditation';

  @override
  String get shareChain => 'Share your chain';

  @override
  String shareChainText(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days of gaman.',
      one: '1 day of gaman.',
    );
    return '$_temp0 Never miss twice.';
  }

  @override
  String urgeWaveSemantics(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes left',
      one: '1 minute left',
    );
    return '$_temp0';
  }
}

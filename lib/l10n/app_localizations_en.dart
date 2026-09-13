// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'INR Tracker';

  @override
  String get tabToday => 'Today';

  @override
  String get tabMedications => 'Medications';

  @override
  String get tabHistory => 'History';

  @override
  String get tabProfile => 'Profile';

  @override
  String get zoneInRange => 'In range';

  @override
  String get zoneBelowRange => 'Below range';

  @override
  String get zoneAboveRange => 'Above range';

  @override
  String get zoneCriticalLow => 'Critically low';

  @override
  String get zoneCriticalHigh => 'Critically high';

  @override
  String get freqDaily => 'Every day';

  @override
  String get freqEveryOtherDay => 'Every other day';

  @override
  String get freqSpecificDays => 'Specific days';

  @override
  String get freqWeeklyPattern => 'Weekly schedule';

  @override
  String freqDailyAt(String times) {
    return 'Every day · $times';
  }

  @override
  String freqEveryOtherDayAt(String time) {
    return 'Every other day · $time';
  }

  @override
  String freqSpecificDaysAt(String days, String time) {
    return '$days · $time';
  }

  @override
  String freqWeeklyPatternAt(String time) {
    return 'Weekly schedule · $time';
  }

  @override
  String doseMg(String mg) {
    return '$mg mg';
  }

  @override
  String get doseNoneToday => 'No dose today';

  @override
  String doseSummary(String mg, String tablets) {
    return '$mg · $tablets';
  }

  @override
  String tabletCount(String count) {
    return '$count tablet';
  }

  @override
  String get intakeTaken => 'Taken';

  @override
  String get intakeSkipped => 'Skipped';

  @override
  String get foodSpinach => 'Spinach';

  @override
  String get foodKale => 'Kale';

  @override
  String get foodChard => 'Swiss chard';

  @override
  String get foodParsley => 'Parsley';

  @override
  String get foodBroccoli => 'Broccoli';

  @override
  String get foodLettuce => 'Lettuce';

  @override
  String get foodGreenBeans => 'Green beans';

  @override
  String get foodGreenTea => 'Green tea';

  @override
  String get foodOther => 'Other';

  @override
  String get portionSmall => 'Small';

  @override
  String get portionMedium => 'Medium';

  @override
  String get portionLarge => 'Large';

  @override
  String get alertCriticalLowTitle => 'CRITICAL: INR too low';

  @override
  String alertCriticalLowMessage(String value) {
    return 'INR $value — risk of clotting. Please contact your doctor or a healthcare provider as soon as possible.';
  }

  @override
  String get alertCriticalHighTitle => 'CRITICAL: INR too high';

  @override
  String alertCriticalHighMessage(String value) {
    return 'INR $value — risk of bleeding. Please contact your doctor or a healthcare provider as soon as possible.';
  }

  @override
  String get alertBelowRangeTitle => 'INR below target';

  @override
  String alertBelowRangeMessage(String value, String lower, String upper) {
    return 'INR $value, target range $lower–$upper. Plan your follow-up test and inform your doctor.';
  }

  @override
  String get alertAboveRangeTitle => 'INR above target';

  @override
  String alertAboveRangeMessage(String value, String lower, String upper) {
    return 'INR $value, target range $lower–$upper. Plan your follow-up test and inform your doctor.';
  }

  @override
  String get alertInRangeTitle => 'In target range';

  @override
  String alertInRangeMessage(String value) {
    return 'INR $value is in target range. Keep up this routine.';
  }

  @override
  String get alertEdemaTitle => 'Possible acute edema + out-of-range INR';

  @override
  String alertEdemaMessage(String delta, String value) {
    return 'A sudden weight gain of $delta in the last 24 hours (which can indicate fluid retention) was recorded, and your current INR $value is outside the target range. Consider sharing this with your doctor.';
  }

  @override
  String reminderTitle(String medication) {
    return 'Time for $medication';
  }

  @override
  String reminderBodyWithTablets(String mg, String tablets) {
    return '$mg ($tablets)';
  }

  @override
  String get premiumUnlimitedHistory => 'Unlimited history';

  @override
  String get premiumPdfReport => 'PDF doctor report';

  @override
  String get premiumOcrScan => 'Scan INR with camera';

  @override
  String get premiumCloudSync => 'Cloud backup and sync';

  @override
  String get premiumHealthSync => 'Health app sync';

  @override
  String get premiumLockScreenWidget => 'Home screen widget';

  @override
  String get premiumDietInsights => 'Diet–INR insights';

  @override
  String get premiumUnlimitedMedications => 'Unlimited medications';

  @override
  String get premiumCaregiverSharing => 'Share with a loved one';

  @override
  String get freeInrLog => 'INR and dose logging';

  @override
  String get freeMedicationPlan =>
      'Medication plan: dose, frequency and reminders';

  @override
  String get freeCriticalAlert => 'Critical threshold alert';

  @override
  String get freeEmergencyContact => 'Emergency contact notification';

  @override
  String get freeRecentTrend => 'Last 30 days trend';

  @override
  String get freeEmergencyCard => 'Emergency card';

  @override
  String emergencyHeadline(String value, String status) {
    return 'LATEST INR: $value ($status)';
  }

  @override
  String get emergencyStatusStable => 'STABLE';

  @override
  String get emergencyStatusAttention => 'ATTENTION';

  @override
  String get emergencyNoRecord => 'No INR record';

  @override
  String get emergencyNdefTitle => 'EMERGENCY MEDICAL INFO';

  @override
  String emergencyNdefPatient(String name) {
    return 'Patient: $name';
  }

  @override
  String emergencyNdefMedication(String medication) {
    return 'Medication: $medication (anticoagulant)';
  }

  @override
  String emergencyNdefContact(String name, String phone) {
    return 'Emergency contact: $name $phone';
  }

  @override
  String get emergencyNdefStopped =>
      'INR Tracker: emergency info sharing stopped.';

  @override
  String shareSummaryTitle(String name) {
    return '$name — INR status summary';
  }

  @override
  String shareSummaryDate(String date) {
    return 'Dated $date';
  }

  @override
  String shareSummaryLastInr(String value, String zone, String date) {
    return 'Latest INR: $value ($zone) — $date';
  }

  @override
  String shareSummaryTargetRange(String lower, String upper) {
    return 'Target range: $lower–$upper';
  }

  @override
  String get shareSummaryNoInr => 'No INR measurement recorded yet.';

  @override
  String shareSummaryTodayDose(String total, String taken) {
    return 'Today\'s dose: $total (taken: $taken)';
  }

  @override
  String shareSummaryAdherence(String percent, int taken, int scheduled) {
    return 'Medication adherence over the last 7 days: $percent% ($taken/$scheduled doses)';
  }

  @override
  String get shareSummaryFooter =>
      'This summary was sent from the INR Tracker app. Medical decisions rest with your doctor.';

  @override
  String get notificationChannelName => 'INR Alerts';

  @override
  String get notificationChannelDescription =>
      'Critical/out-of-range INR values and edema risk alerts';

  @override
  String get reminderChannelName => 'Medication Reminders';

  @override
  String get reminderChannelDescription =>
      'Reminder notifications for your medication times';

  @override
  String reminderBody(String medication, String dose) {
    return '$medication — $dose.';
  }

  @override
  String reminderBodyAnticoagulant(String medication, String dose) {
    return '$medication — $dose. Taking it at the same time every day matters for INR stability.';
  }

  @override
  String doseWithTablets(String mg, String tablets) {
    return '$mg ($tablets)';
  }

  @override
  String doseSourceToday(String medication) {
    return 'Taken from your $medication plan';
  }

  @override
  String doseSourceLastDay(String medication) {
    return '$medication — taken from your last dosing day';
  }

  @override
  String vitaminKEntrySubtitle(String date, String portion, String load) {
    return '$date · $portion portion · K load $load';
  }

  @override
  String vitaminKDeleteTooltip(String name) {
    return 'Delete $name entry';
  }

  @override
  String dietInsightText(String delta, String foods) {
    return 'INR dropped by $delta. High vitamin K intake was logged in the preceding 3 days: $foods. You may want to share this with your doctor.';
  }

  @override
  String get doseFieldLabel => 'Dose that day';

  @override
  String get doseFieldHelper =>
      'Add a medication plan and this fills in automatically';

  @override
  String get planWeekly => 'Weekly';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planTwoMonth => '2 months';

  @override
  String get planThreeMonth => '3 months';

  @override
  String get planSixMonth => '6 months';

  @override
  String get planAnnual => 'Yearly';

  @override
  String get planLifetime => 'Lifetime';

  @override
  String get periodWeek => 'week';

  @override
  String get periodMonth => 'month';

  @override
  String get periodTwoMonths => '2 months';

  @override
  String get periodThreeMonths => '3 months';

  @override
  String get periodSixMonths => '6 months';

  @override
  String get periodYear => 'year';

  @override
  String get periodOneTime => 'one-time';

  @override
  String savingBadge(int percent) {
    return 'Save $percent%';
  }

  @override
  String get purchaseStoreUnavailable => 'Could not connect to the store.';

  @override
  String get purchasePlanNotFound =>
      'The selected plan was not found in the store.';

  @override
  String get purchaseCompleted => 'Your subscription is active. Thank you!';

  @override
  String get purchaseNotCompleted =>
      'The purchase could not be completed. Please try again.';

  @override
  String get purchasePendingApproval =>
      'Payment is awaiting approval. Premium unlocks once approved.';

  @override
  String get purchaseAlreadyActive => 'This subscription is already active.';

  @override
  String get purchaseNoConnection => 'No internet connection.';

  @override
  String get purchaseNotAllowed =>
      'Purchases are not permitted on this device (parental controls may be on).';

  @override
  String get restoreCompleted => 'Your subscription has been restored.';

  @override
  String get restoreNothingFound =>
      'No active subscription found for this account.';

  @override
  String get restoreFailed => 'Restore could not be completed.';

  @override
  String get paywallHeadline => 'Everything that makes tracking easier';

  @override
  String get paywallSubtitle =>
      'Safety features stay free; premium only unlocks conveniences. Safety alerts are always free.';

  @override
  String paywallTrialCta(int days) {
    return 'Try $days days free';
  }

  @override
  String get paywallCta => 'Go Premium';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String paywallFeatureIsPremium(String feature) {
    return '“$feature” is a premium feature.';
  }

  @override
  String get paywallPdfSubtitle =>
      'A 3, 6 or 12-month INR and dose table, in one tap.';

  @override
  String get paywallHistorySubtitle =>
      'Last 30 days on the free tier; your full history with premium.';

  @override
  String get paywallCloudTitle => 'Cloud backup and multiple devices';

  @override
  String get paywallCloudSubtitle => 'Your records survive a change of phone.';

  @override
  String get paywallOcrSubtitle =>
      'Log the value on your meter without typing it.';

  @override
  String get paywallDietSubtitle => 'See which foods lower your INR.';

  @override
  String get paywallMedsSubtitle =>
      '2 medications on the free tier; your whole treatment list with premium.';

  @override
  String get paywallWidgetSubtitle =>
      'Next dose and current INR, without unlocking your phone.';

  @override
  String get paywallAlwaysFreeTitle => 'These are always free';

  @override
  String paywallTrialBadge(int days) {
    return '$days days free';
  }

  @override
  String paywallPerMonth(String price) {
    return '$price per month';
  }

  @override
  String get paywallPlansErrorTitle => 'Plans could not be loaded';

  @override
  String get paywallPlansErrorMessage =>
      'Could not connect to the store. Check your internet connection and try again.';

  @override
  String get paywallLifetimeTerms =>
      'This is a one-time payment; it does not renew.';

  @override
  String get paywallSubscriptionTerms =>
      'The subscription renews automatically unless cancelled at least 24 hours before the end of the period. You can cancel in your device’s store settings.';

  @override
  String get paywallTerms => 'Terms of Use';

  @override
  String get paywallPrivacy => 'Privacy Policy';

  @override
  String get paywallMedicalDisclaimer =>
      'INR Tracker does not give medical advice; it helps you keep your records in order. Only your doctor changes your dose.';

  @override
  String get retry => 'Try again';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get pdfTitle => 'INR Tracker Report';

  @override
  String pdfHeaderLine(
      String name, String lower, String upper, String from, String to) {
    return 'Patient: $name   |   Target range: $lower–$upper   |   Period: $from – $to';
  }

  @override
  String pdfSummaryLine(int count, String percent) {
    return 'Total measurements: $count   •   Time in target range: $percent%';
  }

  @override
  String get pdfColumnDate => 'Date';

  @override
  String get pdfColumnInr => 'INR';

  @override
  String get pdfColumnDose => 'Dose (mg/day)';

  @override
  String get pdfColumnStatus => 'Status';

  @override
  String get pdfColumnNote => 'Note';

  @override
  String get pdfDisclaimer =>
      'This report was generated from data entered by the patient; clinical judgement rests with the physician.';

  @override
  String get pdfFileName => 'inr_report.pdf';

  @override
  String get chartNoData => 'No records in the last 30 days';

  @override
  String get unlockWithPremium => 'Unlock with Premium';

  @override
  String get measuredToday => 'measured today';

  @override
  String get measuredYesterday => 'measured yesterday';

  @override
  String measuredDaysAgo(int days) {
    return 'measured $days days ago';
  }

  @override
  String get cameraPreparing => 'Preparing camera…';

  @override
  String get cameraFailedTitle => 'Camera could not be opened';

  @override
  String get cameraFailedMessage =>
      'Camera permission may be denied, or the camera is unavailable on this device. You can also enter the INR value by hand.';

  @override
  String get measurementDialogTitle => 'New INR measurement';

  @override
  String get inrFieldLabel => 'INR value';

  @override
  String get inrFieldHint => 'e.g. 2.5';

  @override
  String get inrOutOfBounds => 'INR must be between 0 and 20.';

  @override
  String get doseInvalid => 'Enter a valid dose.';

  @override
  String get vitaminKDialogTitle => 'Vitamin K meal';

  @override
  String get vitaminKWhatQuestion => 'What did you eat?';

  @override
  String get vitaminKPortionLabel => 'Portion';

  @override
  String get vitaminKWhenQuestion => 'When?';

  @override
  String get vitaminKDatePickerHelp => 'Meal date';

  @override
  String get vitaminKFoodNameLabel => 'Food name';

  @override
  String get vitaminKFoodNameHint => 'e.g. Purslane';

  @override
  String get vitaminKFoodNameRequired => 'Enter the name of the food.';

  @override
  String get dateToday => 'Today';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get todayNoMedicationTitle => 'No medication plan';

  @override
  String get todayNoMedicationMessage =>
      'Add your blood thinner so its dose and frequency show up here, and we can remind you on time.';

  @override
  String get todayAddMedication => 'Add medication';

  @override
  String get todayCurrentInr => 'Current INR';

  @override
  String todayTargetRange(String lower, String upper) {
    return 'Target range $lower–$upper';
  }

  @override
  String get todayNoMeasurementTitle => 'No measurements yet';

  @override
  String get todayNoMeasurementMessage =>
      'Enter your first INR value and we will show your status against the target range, plus the trend.';

  @override
  String get todayAddMeasurement => 'Add measurement';

  @override
  String get todayMedicationsTitle => 'Today’s medications';

  @override
  String todayMedicationsSubtitle(int count, String total) {
    return '$count doses · $total total';
  }

  @override
  String get todayEditPlan => 'Edit plan';

  @override
  String get todayDisclaimer =>
      'INR Tracker does not give medical advice. Only your doctor changes your dose.';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingDay => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get todayAllDoneTitle => 'Today’s doses are done';

  @override
  String todayAllDoneSubtitle(String total) {
    return '$total taken in total.';
  }

  @override
  String get zoneNoteInRange =>
      'Your value is in the target range. Keep your dose and diet on the same routine.';

  @override
  String get zoneNoteBelow =>
      'Below target — clotting risk may rise. Do not miss your next check.';

  @override
  String get zoneNoteAbove =>
      'Above target — bleeding risk may rise. Call your doctor if you notice new bruising or bleeding.';

  @override
  String zoneNoteCriticalLow(String threshold) {
    return 'Critically low ($threshold). Contact your doctor today.';
  }

  @override
  String zoneNoteCriticalHigh(String threshold) {
    return 'Critically high ($threshold). Contact your doctor today.';
  }

  @override
  String get medsTitle => 'My medication plan';

  @override
  String get medsSubtitle => 'Dose and frequency — tap to edit';

  @override
  String get medsAdd => 'Add medication';

  @override
  String get medsEmptyTitle => 'No medications added yet';

  @override
  String get medsEmptyMessage =>
      'Add your blood thinner and manage its dose, frequency and reminders here.';

  @override
  String get medsEmptyAction => 'Add the first medication';

  @override
  String get medsAdherenceTitle => 'Adherence over 7 days';

  @override
  String medsAdherenceDetail(int taken, int scheduled) {
    return '$taken/$scheduled doses taken';
  }

  @override
  String medsAdherenceMissed(int missed) {
    return ' · $missed missed';
  }

  @override
  String get medsLimitTitle => 'Add more medications';

  @override
  String medsLimitMessage(int count) {
    return 'The free version tracks $count medications. With Premium, keep your whole treatment list in one place.';
  }

  @override
  String get doseTake => 'Taken';

  @override
  String get doseOverdue => 'Dose is overdue';

  @override
  String get doseCountdown => 'Time to next dose';

  @override
  String doseConfirmAnnouncement(String medication, String amount) {
    return '$medication, $amount. Double tap to confirm you have taken it.';
  }

  @override
  String get doseSkip => 'I skipped this dose';

  @override
  String doseTodayTotal(String total) {
    return 'Today’s total: $total';
  }

  @override
  String doseTakenTotal(String total) {
    return '$total taken';
  }

  @override
  String doseTakeTooltip(String medication) {
    return 'I took the $medication dose';
  }

  @override
  String get doseUndoTooltip => 'Undo mark';

  @override
  String weeklyStripTitle(String medication) {
    return '$medication — weekly schedule';
  }

  @override
  String weeklyStripDayLabel(String day, String amount) {
    return '$day: $amount';
  }

  @override
  String get weeklyStripNoDose => 'no medication';

  @override
  String get anticoagulantBadge => 'Blood thinner';

  @override
  String doseSummaryToday(String summary) {
    return '$summary  ·  today';
  }

  @override
  String get doseStateLate => 'Late';

  @override
  String get doseStateWaiting => 'Pending';

  @override
  String get historyReportFailed => 'The report could not be generated.';

  @override
  String get historyEmptyTitle => 'No records in this period';

  @override
  String get historyEmptyMessage =>
      'As you add INR measurements, the trend chart builds up here.';

  @override
  String get historyReportTitle => 'Doctor report';

  @override
  String get historyReportSubtitle => 'A PDF summary for your visit';

  @override
  String get historyReportPreparing => 'Preparing…';

  @override
  String get historyReportShare => 'Share PDF report';

  @override
  String get historyMeasurements => 'Measurements';

  @override
  String historyRecordCount(int count) {
    return '$count records';
  }

  @override
  String get historyDisclaimer =>
      'The report is built from the data you entered; clinical decisions rest with your doctor.';

  @override
  String windowDays(int days) {
    return '$days days';
  }

  @override
  String windowMonths(int months) {
    return '$months months';
  }

  @override
  String get windowYear => '1 year';

  @override
  String get inRangeTitle => 'Time in target range';

  @override
  String get inRangeGood => 'A good balance — keep this routine.';

  @override
  String get inRangePoor =>
      'Your doctor may want to adjust the dose; share this rate at your visit.';

  @override
  String get vitaminKJournalTitle => 'Vitamin K journal';

  @override
  String get vitaminKJournalEmptyHint => 'Log meals like spinach or broccoli';

  @override
  String vitaminKJournalSummary(int count, String load) {
    return '$count meals · total load $load';
  }

  @override
  String get vitaminKAddMeal => 'Add meal';

  @override
  String get dietLockTitle => 'Vitamin K – INR insight';

  @override
  String get dietLockDescription =>
      'See which meals your INR drops after. It matches value changes against high vitamin K foods like spinach and broccoli.';

  @override
  String get dietEmptyTitle => 'No relationship found yet';

  @override
  String get dietEmptyMessage =>
      'As you log high vitamin K meals, the link with INR drops appears here.';

  @override
  String get dietInsightsTitle => 'Vitamin K – INR insights';

  @override
  String entryRowSubtitle(String dose, String zone) {
    return '$dose mg/day · $zone';
  }

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String get authPasswordTooShort => 'Must be at least 6 characters';

  @override
  String get authSignUpAction => 'Sign up';

  @override
  String get authSignInAction => 'Sign in';

  @override
  String get authHaveAccount => 'I already have an account, sign in';

  @override
  String get authNoAccount => 'I don’t have an account, sign up';

  @override
  String get authErrorInvalidEmail => 'Invalid email address.';

  @override
  String get authErrorUserDisabled => 'This account has been disabled.';

  @override
  String get authErrorUserNotFound => 'No account found for this email.';

  @override
  String get authErrorWrongPassword => 'Email or password is incorrect.';

  @override
  String get authErrorEmailInUse =>
      'This email is already registered. Try signing in.';

  @override
  String get authErrorWeakPassword =>
      'Password is too weak (at least 6 characters).';

  @override
  String get authErrorNotEnabled =>
      'Email/password sign-in is not enabled yet in the Firebase Console.';

  @override
  String get authErrorGeneric => 'Something went wrong.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get shareDraftReady =>
      'Summary ready — tap “Send” in your Messages app to send it.';

  @override
  String get shareNoContact =>
      'First save an emergency contact and phone number on this screen.';

  @override
  String get shareUnavailable => 'No app on this device can send messages.';

  @override
  String get edemaScanNoRisk => 'Edema screening: no risk found.';

  @override
  String edemaScanRisk(String delta) {
    return 'Risk detected: $delta gain + out-of-range INR.';
  }

  @override
  String get edemaScanTooltip => 'Edema screening';

  @override
  String get scanInrTooltip => 'Scan INR with camera';

  @override
  String get bootstrapFailed => 'The app could not start';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageSectionSubtitle => 'App language and number/date format';

  @override
  String get languageSystemDefault => 'Device language';

  @override
  String get profilePatientSection => 'Patient';

  @override
  String get profileNameLabel => 'Full name';

  @override
  String get profileTargetTitle => 'Target INR range';

  @override
  String get profileTargetSubtitle => 'The range your doctor set for you';

  @override
  String get profileLowerBound => 'Lower bound';

  @override
  String get profileUpperBound => 'Upper bound';

  @override
  String get profileCriticalTitle => 'Critical thresholds';

  @override
  String get profileCriticalSubtitle =>
      'An emergency alert fires when these are crossed';

  @override
  String get profileCriticalLow => 'Critically low';

  @override
  String get profileCriticalHigh => 'Critically high';

  @override
  String get profileClotRisk => 'Clotting risk';

  @override
  String get profileBleedRisk => 'Bleeding risk';

  @override
  String get profileContactTitle => 'Emergency contact';

  @override
  String get profileContactSubtitle => 'Notified on a critical value';

  @override
  String get profileContactPhone => 'Phone';

  @override
  String get profileSmsToggle => 'Send an SMS on a critical value';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileInvalidNumber => 'Invalid number';

  @override
  String get profileRangeOrderError =>
      'The lower bound must be smaller than the upper bound.';

  @override
  String profileThresholdError(String lower, String upper) {
    return 'Critical thresholds must sit outside the target range (critical low < $lower, critical high > $upper).';
  }

  @override
  String get subscriptionFreeTitle => 'Free version';

  @override
  String get subscriptionFreeMessage =>
      'Go Premium for PDF reports, cloud backup and unlimited history.';

  @override
  String get subscriptionTrialTitle => 'Trial';

  @override
  String get subscriptionLifetime => 'Lifetime access';

  @override
  String get subscriptionCancelled =>
      'Your subscription has been cancelled. Premium features stay open until this date.';

  @override
  String get subscriptionManage => 'Manage subscription';

  @override
  String get caregiverShareTitle => 'Share with a loved one';

  @override
  String get caregiverShareDescription =>
      'Send your latest INR, today’s dose and your adherence rate to a loved one in one tap. A child or carer far away can follow how you are doing.';

  @override
  String get caregiverSharePreparing => 'Preparing…';

  @override
  String get caregiverShareAction => 'Send my status to a loved one';

  @override
  String get editorDoseAmountTitle => 'Dose amount';

  @override
  String get editorNameRequired => 'A medication name is required.';

  @override
  String get editorWeeklyNeedsDose =>
      'Enter a dose for at least one day of the weekly schedule.';

  @override
  String get editorNeedsTime => 'Add at least one dose time.';

  @override
  String get editorNeedsAmount => 'Enter a dose amount for at least one time.';

  @override
  String get editorNeedsDay => 'Select at least one day.';

  @override
  String get editorDeleteWarning =>
      'The medication plan and its intake records will be deleted. Your INR measurements are not affected.';

  @override
  String get editorDiscard => 'Discard';

  @override
  String get editorEditTitle => 'Edit medication';

  @override
  String get editorAddTitle => 'Add medication';

  @override
  String get editorMedicationSection => 'Medication';

  @override
  String get editorNameLabel => 'Medication name';

  @override
  String get editorNameHint => 'e.g. Coumadin';

  @override
  String get editorStrengthLabel => 'Tablet strength (optional)';

  @override
  String get editorStrengthHelper =>
      'If set, doses also show as “1 tablet”, “½ tablet”.';

  @override
  String get editorAnticoagulantToggle => 'Blood thinner (affects INR)';

  @override
  String get editorAnticoagulantConflict =>
      'A blood thinner is already marked. Usually only one anticoagulant is used — ask your doctor.';

  @override
  String get editorAnticoagulantHelp =>
      'Featured on the home screen and suggested as the dose when logging INR.';

  @override
  String get editorFrequencySection => 'Frequency';

  @override
  String get editorFrequencySubtitle => 'Which days the medication is taken';

  @override
  String get editorStartDay => 'Start day';

  @override
  String get editorStartDayHelp =>
      'Every-other-day counting starts from this day';

  @override
  String get editorAmountSubtitle => 'How many mg per intake';

  @override
  String get editorOtherSection => 'Other';

  @override
  String get editorReminderToggle => 'Reminder notification';

  @override
  String get editorReminderHelp =>
      'A notification with the dose at intake time';

  @override
  String get editorNoteHint => 'e.g. on an empty stomach';

  @override
  String get freqDailyHelp => 'Same dose, every day';

  @override
  String get freqEveryOtherDayHelp => 'One day on, one day off';

  @override
  String get freqSpecificDaysHelp => 'Same dose, on the days you choose';

  @override
  String get freqWeeklyPatternHelp =>
      'A different dose each day (warfarin schedule)';

  @override
  String get editorRemoveTime => 'Remove this time';

  @override
  String get editorAddTime => 'Add dose time';

  @override
  String get editorTimeTitle => 'Dose time';

  @override
  String get editorTimeHelp => 'At the same time every day';

  @override
  String editorWeeklyTotal(String total) {
    return 'Weekly total: $total';
  }

  @override
  String get editorAmountLabel => 'Amount (mg)';

  @override
  String get ok => 'OK';

  @override
  String editorDeleteTitle(String medication) {
    return 'Delete $medication?';
  }

  @override
  String get editorDoseSection => 'Dose';

  @override
  String get editorNoteLabel => 'Note (optional)';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'INR Takip'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get tabToday;

  /// No description provided for @tabMedications.
  ///
  /// In tr, this message translates to:
  /// **'İlaçlarım'**
  String get tabMedications;

  /// No description provided for @tabHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get tabHistory;

  /// No description provided for @tabProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @zoneInRange.
  ///
  /// In tr, this message translates to:
  /// **'Hedefte'**
  String get zoneInRange;

  /// No description provided for @zoneBelowRange.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin altında'**
  String get zoneBelowRange;

  /// No description provided for @zoneAboveRange.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin üstünde'**
  String get zoneAboveRange;

  /// No description provided for @zoneCriticalLow.
  ///
  /// In tr, this message translates to:
  /// **'Kritik düşük'**
  String get zoneCriticalLow;

  /// No description provided for @zoneCriticalHigh.
  ///
  /// In tr, this message translates to:
  /// **'Kritik yüksek'**
  String get zoneCriticalHigh;

  /// No description provided for @freqDaily.
  ///
  /// In tr, this message translates to:
  /// **'Her gün'**
  String get freqDaily;

  /// No description provided for @freqEveryOtherDay.
  ///
  /// In tr, this message translates to:
  /// **'Gün aşırı'**
  String get freqEveryOtherDay;

  /// No description provided for @freqSpecificDays.
  ///
  /// In tr, this message translates to:
  /// **'Belirli günler'**
  String get freqSpecificDays;

  /// No description provided for @freqWeeklyPattern.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık şema'**
  String get freqWeeklyPattern;

  /// No description provided for @freqDailyAt.
  ///
  /// In tr, this message translates to:
  /// **'Her gün · {times}'**
  String freqDailyAt(String times);

  /// No description provided for @freqEveryOtherDayAt.
  ///
  /// In tr, this message translates to:
  /// **'Gün aşırı · {time}'**
  String freqEveryOtherDayAt(String time);

  /// No description provided for @freqSpecificDaysAt.
  ///
  /// In tr, this message translates to:
  /// **'{days} · {time}'**
  String freqSpecificDaysAt(String days, String time);

  /// No description provided for @freqWeeklyPatternAt.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık şema · {time}'**
  String freqWeeklyPatternAt(String time);

  /// No description provided for @doseMg.
  ///
  /// In tr, this message translates to:
  /// **'{mg} mg'**
  String doseMg(String mg);

  /// No description provided for @doseNoneToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün doz yok'**
  String get doseNoneToday;

  /// No description provided for @doseSummary.
  ///
  /// In tr, this message translates to:
  /// **'{mg} · {tablets}'**
  String doseSummary(String mg, String tablets);

  /// count bir kesir içerebilir: 1, ½, 1½
  ///
  /// In tr, this message translates to:
  /// **'{count} tablet'**
  String tabletCount(String count);

  /// No description provided for @intakeTaken.
  ///
  /// In tr, this message translates to:
  /// **'Alındı'**
  String get intakeTaken;

  /// No description provided for @intakeSkipped.
  ///
  /// In tr, this message translates to:
  /// **'Atlandı'**
  String get intakeSkipped;

  /// No description provided for @foodSpinach.
  ///
  /// In tr, this message translates to:
  /// **'Ispanak'**
  String get foodSpinach;

  /// No description provided for @foodKale.
  ///
  /// In tr, this message translates to:
  /// **'Kara lahana'**
  String get foodKale;

  /// No description provided for @foodChard.
  ///
  /// In tr, this message translates to:
  /// **'Pazı'**
  String get foodChard;

  /// No description provided for @foodParsley.
  ///
  /// In tr, this message translates to:
  /// **'Maydanoz'**
  String get foodParsley;

  /// No description provided for @foodBroccoli.
  ///
  /// In tr, this message translates to:
  /// **'Brokoli'**
  String get foodBroccoli;

  /// No description provided for @foodLettuce.
  ///
  /// In tr, this message translates to:
  /// **'Marul'**
  String get foodLettuce;

  /// No description provided for @foodGreenBeans.
  ///
  /// In tr, this message translates to:
  /// **'Taze fasulye'**
  String get foodGreenBeans;

  /// No description provided for @foodGreenTea.
  ///
  /// In tr, this message translates to:
  /// **'Yeşil çay'**
  String get foodGreenTea;

  /// No description provided for @foodOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get foodOther;

  /// No description provided for @portionSmall.
  ///
  /// In tr, this message translates to:
  /// **'Az'**
  String get portionSmall;

  /// No description provided for @portionMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get portionMedium;

  /// No description provided for @portionLarge.
  ///
  /// In tr, this message translates to:
  /// **'Bol'**
  String get portionLarge;

  /// No description provided for @alertCriticalLowTitle.
  ///
  /// In tr, this message translates to:
  /// **'KRİTİK: INR çok düşük'**
  String get alertCriticalLowTitle;

  /// No description provided for @alertCriticalLowMessage.
  ///
  /// In tr, this message translates to:
  /// **'INR {value} — pıhtılaşma riski. Lütfen en kısa sürede doktorunuza veya sağlık kuruluşuna ulaşın.'**
  String alertCriticalLowMessage(String value);

  /// No description provided for @alertCriticalHighTitle.
  ///
  /// In tr, this message translates to:
  /// **'KRİTİK: INR çok yüksek'**
  String get alertCriticalHighTitle;

  /// No description provided for @alertCriticalHighMessage.
  ///
  /// In tr, this message translates to:
  /// **'INR {value} — kanama riski. Lütfen en kısa sürede doktorunuza veya sağlık kuruluşuna ulaşın.'**
  String alertCriticalHighMessage(String value);

  /// No description provided for @alertBelowRangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'INR hedefin altında'**
  String get alertBelowRangeTitle;

  /// No description provided for @alertBelowRangeMessage.
  ///
  /// In tr, this message translates to:
  /// **'INR {value}, hedef aralık {lower}–{upper}. Takip ölçümünüzü planlayın ve doktorunuzu bilgilendirin.'**
  String alertBelowRangeMessage(String value, String lower, String upper);

  /// No description provided for @alertAboveRangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'INR hedefin üstünde'**
  String get alertAboveRangeTitle;

  /// No description provided for @alertAboveRangeMessage.
  ///
  /// In tr, this message translates to:
  /// **'INR {value}, hedef aralık {lower}–{upper}. Takip ölçümünüzü planlayın ve doktorunuzu bilgilendirin.'**
  String alertAboveRangeMessage(String value, String lower, String upper);

  /// No description provided for @alertInRangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedef aralıkta'**
  String get alertInRangeTitle;

  /// No description provided for @alertInRangeMessage.
  ///
  /// In tr, this message translates to:
  /// **'INR {value} hedef aralıkta. Bu düzeni koruyun.'**
  String alertInRangeMessage(String value);

  /// No description provided for @alertEdemaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Olası akut ödem + hedef dışı INR'**
  String get alertEdemaTitle;

  /// No description provided for @alertEdemaMessage.
  ///
  /// In tr, this message translates to:
  /// **'Son 24 saatte {delta} ani kilo artışı (sıvı birikmesi belirtisi olabilir) kaydedildi ve güncel INR {value} hedef aralığın dışında. Bu bilgiyi doktorunuzla paylaşmanız önerilir.'**
  String alertEdemaMessage(String delta, String value);

  /// No description provided for @reminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'{medication} zamanı'**
  String reminderTitle(String medication);

  /// No description provided for @reminderBodyWithTablets.
  ///
  /// In tr, this message translates to:
  /// **'{mg} ({tablets})'**
  String reminderBodyWithTablets(String mg, String tablets);

  /// No description provided for @premiumUnlimitedHistory.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız geçmiş'**
  String get premiumUnlimitedHistory;

  /// No description provided for @premiumPdfReport.
  ///
  /// In tr, this message translates to:
  /// **'PDF doktor raporu'**
  String get premiumPdfReport;

  /// No description provided for @premiumOcrScan.
  ///
  /// In tr, this message translates to:
  /// **'Kamerayla INR okuma'**
  String get premiumOcrScan;

  /// No description provided for @premiumCloudSync.
  ///
  /// In tr, this message translates to:
  /// **'Bulut yedek ve senkron'**
  String get premiumCloudSync;

  /// No description provided for @premiumHealthSync.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık uygulaması senkronu'**
  String get premiumHealthSync;

  /// No description provided for @premiumLockScreenWidget.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekran widget’ı'**
  String get premiumLockScreenWidget;

  /// No description provided for @premiumDietInsights.
  ///
  /// In tr, this message translates to:
  /// **'Diyet–INR içgörüleri'**
  String get premiumDietInsights;

  /// No description provided for @premiumUnlimitedMedications.
  ///
  /// In tr, this message translates to:
  /// **'Sınırsız ilaç'**
  String get premiumUnlimitedMedications;

  /// No description provided for @premiumCaregiverSharing.
  ///
  /// In tr, this message translates to:
  /// **'Yakınla paylaşım'**
  String get premiumCaregiverSharing;

  /// No description provided for @freeInrLog.
  ///
  /// In tr, this message translates to:
  /// **'INR ve doz kaydı'**
  String get freeInrLog;

  /// No description provided for @freeMedicationPlan.
  ///
  /// In tr, this message translates to:
  /// **'İlaç planı: doz, sıklık ve hatırlatıcı'**
  String get freeMedicationPlan;

  /// No description provided for @freeCriticalAlert.
  ///
  /// In tr, this message translates to:
  /// **'Kritik eşik uyarısı'**
  String get freeCriticalAlert;

  /// No description provided for @freeEmergencyContact.
  ///
  /// In tr, this message translates to:
  /// **'Acil durum kişisine bildirim'**
  String get freeEmergencyContact;

  /// No description provided for @freeRecentTrend.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 günün trendi'**
  String get freeRecentTrend;

  /// No description provided for @freeEmergencyCard.
  ///
  /// In tr, this message translates to:
  /// **'Acil durum kartı'**
  String get freeEmergencyCard;

  /// No description provided for @emergencyHeadline.
  ///
  /// In tr, this message translates to:
  /// **'SON INR: {value} ({status})'**
  String emergencyHeadline(String value, String status);

  /// No description provided for @emergencyStatusStable.
  ///
  /// In tr, this message translates to:
  /// **'STABİL'**
  String get emergencyStatusStable;

  /// No description provided for @emergencyStatusAttention.
  ///
  /// In tr, this message translates to:
  /// **'DİKKAT'**
  String get emergencyStatusAttention;

  /// No description provided for @emergencyNoRecord.
  ///
  /// In tr, this message translates to:
  /// **'INR kaydı yok'**
  String get emergencyNoRecord;

  /// No description provided for @emergencyNdefTitle.
  ///
  /// In tr, this message translates to:
  /// **'ACİL TIBBİ BİLGİ'**
  String get emergencyNdefTitle;

  /// No description provided for @emergencyNdefPatient.
  ///
  /// In tr, this message translates to:
  /// **'Hasta: {name}'**
  String emergencyNdefPatient(String name);

  /// No description provided for @emergencyNdefMedication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç: {medication} (antikoagülan)'**
  String emergencyNdefMedication(String medication);

  /// No description provided for @emergencyNdefContact.
  ///
  /// In tr, this message translates to:
  /// **'Acil kişi: {name} {phone}'**
  String emergencyNdefContact(String name, String phone);

  /// No description provided for @emergencyNdefStopped.
  ///
  /// In tr, this message translates to:
  /// **'INR Takip: acil bilgi paylaşımı durduruldu.'**
  String get emergencyNdefStopped;

  /// No description provided for @shareSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} — INR durum özeti'**
  String shareSummaryTitle(String name);

  /// No description provided for @shareSummaryDate.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihli'**
  String shareSummaryDate(String date);

  /// No description provided for @shareSummaryLastInr.
  ///
  /// In tr, this message translates to:
  /// **'Son INR: {value} ({zone}) — {date}'**
  String shareSummaryLastInr(String value, String zone, String date);

  /// No description provided for @shareSummaryTargetRange.
  ///
  /// In tr, this message translates to:
  /// **'Hedef aralık: {lower}–{upper}'**
  String shareSummaryTargetRange(String lower, String upper);

  /// No description provided for @shareSummaryNoInr.
  ///
  /// In tr, this message translates to:
  /// **'Henüz INR ölçümü kaydedilmedi.'**
  String get shareSummaryNoInr;

  /// No description provided for @shareSummaryTodayDose.
  ///
  /// In tr, this message translates to:
  /// **'Bugünkü doz: {total} (alınan: {taken})'**
  String shareSummaryTodayDose(String total, String taken);

  /// No description provided for @shareSummaryAdherence.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün ilaç uyumu: %{percent} ({taken}/{scheduled} doz)'**
  String shareSummaryAdherence(String percent, int taken, int scheduled);

  /// No description provided for @shareSummaryFooter.
  ///
  /// In tr, this message translates to:
  /// **'Bu özet INR Takip uygulamasından gönderildi. Tıbbi karar hekime aittir.'**
  String get shareSummaryFooter;

  /// No description provided for @notificationChannelName.
  ///
  /// In tr, this message translates to:
  /// **'INR Uyarıları'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kritik/hedef dışı INR değerleri ve ödem riski uyarıları'**
  String get notificationChannelDescription;

  /// No description provided for @reminderChannelName.
  ///
  /// In tr, this message translates to:
  /// **'İlaç Hatırlatıcıları'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In tr, this message translates to:
  /// **'İlaç alım saatleriniz için hatırlatma bildirimleri'**
  String get reminderChannelDescription;

  /// No description provided for @reminderBody.
  ///
  /// In tr, this message translates to:
  /// **'{medication} — {dose}.'**
  String reminderBody(String medication, String dose);

  /// No description provided for @reminderBodyAnticoagulant.
  ///
  /// In tr, this message translates to:
  /// **'{medication} — {dose}. Her gün aynı saatte almak INR dengesi için önemlidir.'**
  String reminderBodyAnticoagulant(String medication, String dose);

  /// No description provided for @doseWithTablets.
  ///
  /// In tr, this message translates to:
  /// **'{mg} ({tablets})'**
  String doseWithTablets(String mg, String tablets);

  /// No description provided for @doseSourceToday.
  ///
  /// In tr, this message translates to:
  /// **'{medication} planınızdan alındı'**
  String doseSourceToday(String medication);

  /// No description provided for @doseSourceLastDay.
  ///
  /// In tr, this message translates to:
  /// **'{medication} — son doz gününüzden alındı'**
  String doseSourceLastDay(String medication);

  /// No description provided for @vitaminKEntrySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{date} · {portion} porsiyon · K yükü {load}'**
  String vitaminKEntrySubtitle(String date, String portion, String load);

  /// No description provided for @vitaminKDeleteTooltip.
  ///
  /// In tr, this message translates to:
  /// **'{name} kaydını sil'**
  String vitaminKDeleteTooltip(String name);

  /// No description provided for @dietInsightText.
  ///
  /// In tr, this message translates to:
  /// **'INR {delta} puan düştü. Önceki 3 günde yüksek K vitamini alımı kaydedilmiş: {foods}. Bu bilgiyi doktorunuzla paylaşabilirsiniz.'**
  String dietInsightText(String delta, String foods);

  /// No description provided for @doseFieldLabel.
  ///
  /// In tr, this message translates to:
  /// **'O günkü doz'**
  String get doseFieldLabel;

  /// No description provided for @doseFieldHelper.
  ///
  /// In tr, this message translates to:
  /// **'İlaç planı eklerseniz burası kendiliğinden dolar'**
  String get doseFieldHelper;

  /// No description provided for @planWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get planWeekly;

  /// No description provided for @planMonthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get planMonthly;

  /// No description provided for @planTwoMonth.
  ///
  /// In tr, this message translates to:
  /// **'2 aylık'**
  String get planTwoMonth;

  /// No description provided for @planThreeMonth.
  ///
  /// In tr, this message translates to:
  /// **'3 aylık'**
  String get planThreeMonth;

  /// No description provided for @planSixMonth.
  ///
  /// In tr, this message translates to:
  /// **'6 aylık'**
  String get planSixMonth;

  /// No description provided for @planAnnual.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get planAnnual;

  /// No description provided for @planLifetime.
  ///
  /// In tr, this message translates to:
  /// **'Ömür boyu'**
  String get planLifetime;

  /// No description provided for @periodWeek.
  ///
  /// In tr, this message translates to:
  /// **'hafta'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In tr, this message translates to:
  /// **'ay'**
  String get periodMonth;

  /// No description provided for @periodTwoMonths.
  ///
  /// In tr, this message translates to:
  /// **'2 ay'**
  String get periodTwoMonths;

  /// No description provided for @periodThreeMonths.
  ///
  /// In tr, this message translates to:
  /// **'3 ay'**
  String get periodThreeMonths;

  /// No description provided for @periodSixMonths.
  ///
  /// In tr, this message translates to:
  /// **'6 ay'**
  String get periodSixMonths;

  /// No description provided for @periodYear.
  ///
  /// In tr, this message translates to:
  /// **'yıl'**
  String get periodYear;

  /// No description provided for @periodOneTime.
  ///
  /// In tr, this message translates to:
  /// **'tek seferlik'**
  String get periodOneTime;

  /// No description provided for @savingBadge.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} tasarruf'**
  String savingBadge(int percent);

  /// No description provided for @purchaseStoreUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza bağlantısı kurulamadı.'**
  String get purchaseStoreUnavailable;

  /// No description provided for @purchasePlanNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen plan mağazada bulunamadı.'**
  String get purchasePlanNotFound;

  /// No description provided for @purchaseCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliğiniz aktif. Teşekkürler!'**
  String get purchaseCompleted;

  /// No description provided for @purchaseNotCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Satın alma tamamlanamadı. Lütfen tekrar deneyin.'**
  String get purchaseNotCompleted;

  /// No description provided for @purchasePendingApproval.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme onay bekliyor. Onaylanınca premium açılacak.'**
  String get purchasePendingApproval;

  /// No description provided for @purchaseAlreadyActive.
  ///
  /// In tr, this message translates to:
  /// **'Bu abonelik zaten aktif.'**
  String get purchaseAlreadyActive;

  /// No description provided for @purchaseNoConnection.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı kurulamadı.'**
  String get purchaseNoConnection;

  /// No description provided for @purchaseNotAllowed.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda satın alma izni yok (ör. ebeveyn kontrolü açık olabilir).'**
  String get purchaseNotAllowed;

  /// No description provided for @restoreCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliğiniz geri yüklendi.'**
  String get restoreCompleted;

  /// No description provided for @restoreNothingFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesapta aktif abonelik bulunamadı.'**
  String get restoreNothingFound;

  /// No description provided for @restoreFailed.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme tamamlanamadı.'**
  String get restoreFailed;

  /// No description provided for @paywallHeadline.
  ///
  /// In tr, this message translates to:
  /// **'Takibi kolaylaştıran her şey'**
  String get paywallHeadline;

  /// No description provided for @paywallSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik özellikleri ücretsiz kalır; premium yalnızca kolaylıkları açar. Güvenlik uyarıları her zaman ücretsizdir.'**
  String get paywallSubtitle;

  /// No description provided for @paywallTrialCta.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün ücretsiz dene'**
  String paywallTrialCta(int days);

  /// No description provided for @paywallCta.
  ///
  /// In tr, this message translates to:
  /// **'Premium’a geç'**
  String get paywallCta;

  /// No description provided for @paywallRestore.
  ///
  /// In tr, this message translates to:
  /// **'Satın alımları geri yükle'**
  String get paywallRestore;

  /// No description provided for @paywallFeatureIsPremium.
  ///
  /// In tr, this message translates to:
  /// **'“{feature}” premium bir özellik.'**
  String paywallFeatureIsPremium(String feature);

  /// No description provided for @paywallPdfSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'3, 6 veya 12 aylık INR ve doz tablosu, tek dokunuşla.'**
  String get paywallPdfSubtitle;

  /// No description provided for @paywallHistorySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsizde son 30 gün; premium ile tüm takip geçmişiniz.'**
  String get paywallHistorySubtitle;

  /// No description provided for @paywallCloudTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bulut yedek ve çoklu cihaz'**
  String get paywallCloudTitle;

  /// No description provided for @paywallCloudSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefon değişse de kayıtlarınız kaybolmaz.'**
  String get paywallCloudSubtitle;

  /// No description provided for @paywallOcrSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz ekranındaki değeri elle yazmadan kaydedin.'**
  String get paywallOcrSubtitle;

  /// No description provided for @paywallDietSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hangi beslenmenin INR’yi düşürdüğünü görün.'**
  String get paywallDietSubtitle;

  /// No description provided for @paywallMedsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsizde 2 ilaç; premium ile tüm tedavi listeniz.'**
  String get paywallMedsSubtitle;

  /// No description provided for @paywallWidgetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki doz ve güncel INR, telefonu açmadan.'**
  String get paywallWidgetSubtitle;

  /// No description provided for @paywallAlwaysFreeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bunlar her zaman ücretsiz'**
  String get paywallAlwaysFreeTitle;

  /// No description provided for @paywallTrialBadge.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün ücretsiz'**
  String paywallTrialBadge(int days);

  /// No description provided for @paywallPerMonth.
  ///
  /// In tr, this message translates to:
  /// **'aylık {price}'**
  String paywallPerMonth(String price);

  /// No description provided for @paywallPlansErrorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Planlar yüklenemedi'**
  String get paywallPlansErrorTitle;

  /// No description provided for @paywallPlansErrorMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza bağlantısı kurulamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.'**
  String get paywallPlansErrorMessage;

  /// No description provided for @paywallLifetimeTerms.
  ///
  /// In tr, this message translates to:
  /// **'Tek seferlik ödemedir, yenilenmez.'**
  String get paywallLifetimeTerms;

  /// No description provided for @paywallSubscriptionTerms.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik yenilenir. İptali cihazınızın mağaza ayarlarından yapabilirsiniz.'**
  String get paywallSubscriptionTerms;

  /// No description provided for @paywallTerms.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get paywallTerms;

  /// No description provided for @paywallPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get paywallPrivacy;

  /// No description provided for @paywallMedicalDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'INR Takip tıbbi tavsiye vermez; kayıtlarınızı düzenli tutmanıza yardımcı olur. Doz değişikliğini yalnızca hekiminiz yapar.'**
  String get paywallMedicalDisclaimer;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @pdfTitle.
  ///
  /// In tr, this message translates to:
  /// **'INR Takip Raporu'**
  String get pdfTitle;

  /// No description provided for @pdfHeaderLine.
  ///
  /// In tr, this message translates to:
  /// **'Hasta: {name}   |   Hedef aralık: {lower}–{upper}   |   Dönem: {from} – {to}'**
  String pdfHeaderLine(
      String name, String lower, String upper, String from, String to);

  /// No description provided for @pdfSummaryLine.
  ///
  /// In tr, this message translates to:
  /// **'Toplam ölçüm: {count}   •   Hedef aralıkta kalma: %{percent}'**
  String pdfSummaryLine(int count, String percent);

  /// No description provided for @pdfColumnDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get pdfColumnDate;

  /// No description provided for @pdfColumnInr.
  ///
  /// In tr, this message translates to:
  /// **'INR'**
  String get pdfColumnInr;

  /// No description provided for @pdfColumnDose.
  ///
  /// In tr, this message translates to:
  /// **'Doz (mg/gün)'**
  String get pdfColumnDose;

  /// No description provided for @pdfColumnStatus.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get pdfColumnStatus;

  /// No description provided for @pdfColumnNote.
  ///
  /// In tr, this message translates to:
  /// **'Not'**
  String get pdfColumnNote;

  /// No description provided for @pdfDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu rapor hasta tarafından girilen verilerle oluşturulmuştur; tıbbi karar için hekim değerlendirmesi esastır.'**
  String get pdfDisclaimer;

  /// No description provided for @pdfFileName.
  ///
  /// In tr, this message translates to:
  /// **'inr_raporu.pdf'**
  String get pdfFileName;

  /// No description provided for @chartNoData.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 günde kayıt yok'**
  String get chartNoData;

  /// No description provided for @unlockWithPremium.
  ///
  /// In tr, this message translates to:
  /// **'Premium ile aç'**
  String get unlockWithPremium;

  /// No description provided for @measuredToday.
  ///
  /// In tr, this message translates to:
  /// **'bugün ölçüldü'**
  String get measuredToday;

  /// No description provided for @measuredYesterday.
  ///
  /// In tr, this message translates to:
  /// **'dün ölçüldü'**
  String get measuredYesterday;

  /// No description provided for @measuredDaysAgo.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün önce ölçüldü'**
  String measuredDaysAgo(int days);

  /// No description provided for @cameraPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Kamera hazırlanıyor…'**
  String get cameraPreparing;

  /// No description provided for @cameraFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kamera açılamadı'**
  String get cameraFailedTitle;

  /// No description provided for @cameraFailedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kamera izni verilmemiş olabilir ya da bu cihazda kamera kullanılamıyor. INR değerini elle de girebilirsiniz.'**
  String get cameraFailedMessage;

  /// No description provided for @measurementDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni INR ölçümü'**
  String get measurementDialogTitle;

  /// No description provided for @inrFieldLabel.
  ///
  /// In tr, this message translates to:
  /// **'INR değeri'**
  String get inrFieldLabel;

  /// No description provided for @inrFieldHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. 2,5'**
  String get inrFieldHint;

  /// No description provided for @inrOutOfBounds.
  ///
  /// In tr, this message translates to:
  /// **'INR değeri 0–20 arasında olmalı.'**
  String get inrOutOfBounds;

  /// No description provided for @doseInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir doz girin.'**
  String get doseInvalid;

  /// No description provided for @vitaminKDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'K vitamini öğünü'**
  String get vitaminKDialogTitle;

  /// No description provided for @vitaminKWhatQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Ne yediniz?'**
  String get vitaminKWhatQuestion;

  /// No description provided for @vitaminKPortionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Porsiyon'**
  String get vitaminKPortionLabel;

  /// No description provided for @vitaminKWhenQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Ne zaman?'**
  String get vitaminKWhenQuestion;

  /// No description provided for @vitaminKDatePickerHelp.
  ///
  /// In tr, this message translates to:
  /// **'Öğün tarihi'**
  String get vitaminKDatePickerHelp;

  /// No description provided for @vitaminKFoodNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gıda adı'**
  String get vitaminKFoodNameLabel;

  /// No description provided for @vitaminKFoodNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Semizotu'**
  String get vitaminKFoodNameHint;

  /// No description provided for @vitaminKFoodNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Gıdanın adını yazın.'**
  String get vitaminKFoodNameRequired;

  /// No description provided for @dateToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In tr, this message translates to:
  /// **'Dün'**
  String get dateYesterday;

  /// No description provided for @todayNoMedicationTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlaç planı yok'**
  String get todayNoMedicationTitle;

  /// No description provided for @todayNoMedicationMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kan sulandırıcınızı ekleyin; dozu ve sıklığı burada görünsün, saatinde hatırlatalım.'**
  String get todayNoMedicationMessage;

  /// No description provided for @todayAddMedication.
  ///
  /// In tr, this message translates to:
  /// **'İlaç ekle'**
  String get todayAddMedication;

  /// No description provided for @todayCurrentInr.
  ///
  /// In tr, this message translates to:
  /// **'Güncel INR'**
  String get todayCurrentInr;

  /// No description provided for @todayTargetRange.
  ///
  /// In tr, this message translates to:
  /// **'Hedef aralık {lower}–{upper}'**
  String todayTargetRange(String lower, String upper);

  /// No description provided for @todayNoMeasurementTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ölçüm yok'**
  String get todayNoMeasurementTitle;

  /// No description provided for @todayNoMeasurementMessage.
  ///
  /// In tr, this message translates to:
  /// **'İlk INR değerinizi girin; hedef aralığa göre durumunuzu ve trendi burada gösterelim.'**
  String get todayNoMeasurementMessage;

  /// No description provided for @todayAddMeasurement.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm ekle'**
  String get todayAddMeasurement;

  /// No description provided for @todayMedicationsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün ilaçları'**
  String get todayMedicationsTitle;

  /// No description provided for @todayMedicationsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} alım · toplam {total}'**
  String todayMedicationsSubtitle(int count, String total);

  /// No description provided for @todayEditPlan.
  ///
  /// In tr, this message translates to:
  /// **'Planı düzenle'**
  String get todayEditPlan;

  /// No description provided for @todayDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'INR Takip tıbbi tavsiye vermez. Doz değişikliğini yalnızca hekiminiz yapar.'**
  String get todayDisclaimer;

  /// No description provided for @greetingMorning.
  ///
  /// In tr, this message translates to:
  /// **'Günaydın'**
  String get greetingMorning;

  /// No description provided for @greetingDay.
  ///
  /// In tr, this message translates to:
  /// **'İyi günler'**
  String get greetingDay;

  /// No description provided for @greetingEvening.
  ///
  /// In tr, this message translates to:
  /// **'İyi akşamlar'**
  String get greetingEvening;

  /// No description provided for @todayAllDoneTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün dozları tamam'**
  String get todayAllDoneTitle;

  /// No description provided for @todayAllDoneSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Toplam {total} alındı.'**
  String todayAllDoneSubtitle(String total);

  /// No description provided for @zoneNoteInRange.
  ///
  /// In tr, this message translates to:
  /// **'Değeriniz hedef aralıkta. Dozunuzu ve beslenmenizi aynı düzende sürdürün.'**
  String get zoneNoteInRange;

  /// No description provided for @zoneNoteBelow.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin altında — pıhtı riski artabilir. Kontrol tarihinizi kaçırmayın.'**
  String get zoneNoteBelow;

  /// No description provided for @zoneNoteAbove.
  ///
  /// In tr, this message translates to:
  /// **'Hedefin üstünde — kanama riski artabilir. Yeni bir morarma/kanama olursa hekiminizi arayın.'**
  String get zoneNoteAbove;

  /// No description provided for @zoneNoteCriticalLow.
  ///
  /// In tr, this message translates to:
  /// **'Kritik düşük ({threshold}). Hekiminizle bugün iletişime geçin.'**
  String zoneNoteCriticalLow(String threshold);

  /// No description provided for @zoneNoteCriticalHigh.
  ///
  /// In tr, this message translates to:
  /// **'Kritik yüksek ({threshold}). Hekiminizle bugün iletişime geçin.'**
  String zoneNoteCriticalHigh(String threshold);

  /// No description provided for @medsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlaç planım'**
  String get medsTitle;

  /// No description provided for @medsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Doz ve sıklık — dokunarak düzenleyin'**
  String get medsSubtitle;

  /// No description provided for @medsAdd.
  ///
  /// In tr, this message translates to:
  /// **'İlaç ekle'**
  String get medsAdd;

  /// No description provided for @medsEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ilaç eklemediniz'**
  String get medsEmptyTitle;

  /// No description provided for @medsEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kan sulandırıcınızı ekleyin; dozunu, sıklığını ve hatırlatmasını buradan yönetin.'**
  String get medsEmptyMessage;

  /// No description provided for @medsEmptyAction.
  ///
  /// In tr, this message translates to:
  /// **'İlk ilacı ekle'**
  String get medsEmptyAction;

  /// No description provided for @medsAdherenceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 günlük uyum'**
  String get medsAdherenceTitle;

  /// No description provided for @medsAdherenceDetail.
  ///
  /// In tr, this message translates to:
  /// **'{taken}/{scheduled} doz alındı'**
  String medsAdherenceDetail(int taken, int scheduled);

  /// No description provided for @medsAdherenceMissed.
  ///
  /// In tr, this message translates to:
  /// **' · {missed} kaçırıldı'**
  String medsAdherenceMissed(int missed);

  /// No description provided for @medsLimitTitle.
  ///
  /// In tr, this message translates to:
  /// **'Daha fazla ilaç ekleyin'**
  String get medsLimitTitle;

  /// No description provided for @medsLimitMessage.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz sürümde {count} ilaç takip edilebilir. Premium ile tüm tedavi listenizi tek yerde tutun.'**
  String medsLimitMessage(int count);

  /// No description provided for @doseTake.
  ///
  /// In tr, this message translates to:
  /// **'Aldım'**
  String get doseTake;

  /// No description provided for @doseOverdue.
  ///
  /// In tr, this message translates to:
  /// **'Doz saati geçti'**
  String get doseOverdue;

  /// No description provided for @doseCountdown.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki doza kalan'**
  String get doseCountdown;

  /// No description provided for @doseConfirmAnnouncement.
  ///
  /// In tr, this message translates to:
  /// **'{medication}, {amount}. Aldıysanız onaylamak için çift dokunun.'**
  String doseConfirmAnnouncement(String medication, String amount);

  /// No description provided for @doseSkip.
  ///
  /// In tr, this message translates to:
  /// **'Bu dozu atladım'**
  String get doseSkip;

  /// No description provided for @doseTodayTotal.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün toplamı: {total}'**
  String doseTodayTotal(String total);

  /// No description provided for @doseTakenTotal.
  ///
  /// In tr, this message translates to:
  /// **'{total} alındı'**
  String doseTakenTotal(String total);

  /// No description provided for @doseTakeTooltip.
  ///
  /// In tr, this message translates to:
  /// **'{medication} dozunu aldım'**
  String doseTakeTooltip(String medication);

  /// No description provided for @doseUndoTooltip.
  ///
  /// In tr, this message translates to:
  /// **'İşareti geri al'**
  String get doseUndoTooltip;

  /// No description provided for @weeklyStripTitle.
  ///
  /// In tr, this message translates to:
  /// **'{medication} — haftalık şema'**
  String weeklyStripTitle(String medication);

  /// No description provided for @weeklyStripDayLabel.
  ///
  /// In tr, this message translates to:
  /// **'{day}: {amount}'**
  String weeklyStripDayLabel(String day, String amount);

  /// No description provided for @weeklyStripNoDose.
  ///
  /// In tr, this message translates to:
  /// **'ilaç yok'**
  String get weeklyStripNoDose;

  /// No description provided for @anticoagulantBadge.
  ///
  /// In tr, this message translates to:
  /// **'Kan sulandırıcı'**
  String get anticoagulantBadge;

  /// No description provided for @doseSummaryToday.
  ///
  /// In tr, this message translates to:
  /// **'{summary}  ·  bugün'**
  String doseSummaryToday(String summary);

  /// No description provided for @doseStateLate.
  ///
  /// In tr, this message translates to:
  /// **'Gecikti'**
  String get doseStateLate;

  /// No description provided for @doseStateWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get doseStateWaiting;

  /// No description provided for @historyReportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Rapor oluşturulamadı.'**
  String get historyReportFailed;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönemde kayıt yok'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'INR ölçümü ekledikçe trend grafiği burada oluşur.'**
  String get historyEmptyMessage;

  /// No description provided for @historyReportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doktor raporu'**
  String get historyReportTitle;

  /// No description provided for @historyReportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Vizit için PDF özet'**
  String get historyReportSubtitle;

  /// No description provided for @historyReportPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor…'**
  String get historyReportPreparing;

  /// No description provided for @historyReportShare.
  ///
  /// In tr, this message translates to:
  /// **'PDF raporu paylaş'**
  String get historyReportShare;

  /// No description provided for @historyMeasurements.
  ///
  /// In tr, this message translates to:
  /// **'Ölçümler'**
  String get historyMeasurements;

  /// No description provided for @historyRecordCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kayıt'**
  String historyRecordCount(int count);

  /// No description provided for @historyDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Rapor, girdiğiniz verilerle oluşturulur; tıbbi karar hekiminize aittir.'**
  String get historyDisclaimer;

  /// No description provided for @windowDays.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün'**
  String windowDays(int days);

  /// No description provided for @windowMonths.
  ///
  /// In tr, this message translates to:
  /// **'{months} ay'**
  String windowMonths(int months);

  /// No description provided for @windowYear.
  ///
  /// In tr, this message translates to:
  /// **'1 yıl'**
  String get windowYear;

  /// No description provided for @inRangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedef aralıkta kalma'**
  String get inRangeTitle;

  /// No description provided for @inRangeGood.
  ///
  /// In tr, this message translates to:
  /// **'İyi bir denge — bu düzeni koruyun.'**
  String get inRangeGood;

  /// No description provided for @inRangePoor.
  ///
  /// In tr, this message translates to:
  /// **'Hekiminiz doz ayarı yapmak isteyebilir; bu oranı vizitte paylaşın.'**
  String get inRangePoor;

  /// No description provided for @vitaminKJournalTitle.
  ///
  /// In tr, this message translates to:
  /// **'K vitamini günlüğü'**
  String get vitaminKJournalTitle;

  /// No description provided for @vitaminKJournalEmptyHint.
  ///
  /// In tr, this message translates to:
  /// **'Ispanak, brokoli gibi öğünleri kaydedin'**
  String get vitaminKJournalEmptyHint;

  /// No description provided for @vitaminKJournalSummary.
  ///
  /// In tr, this message translates to:
  /// **'{count} öğün · toplam yük {load}'**
  String vitaminKJournalSummary(int count, String load);

  /// No description provided for @vitaminKAddMeal.
  ///
  /// In tr, this message translates to:
  /// **'Öğün ekle'**
  String get vitaminKAddMeal;

  /// No description provided for @dietLockTitle.
  ///
  /// In tr, this message translates to:
  /// **'K vitamini – INR içgörüsü'**
  String get dietLockTitle;

  /// No description provided for @dietLockDescription.
  ///
  /// In tr, this message translates to:
  /// **'Hangi öğünlerden sonra INR’nizin düştüğünü görün. Ispanak, brokoli gibi K vitamini yüksek gıdalarla değer değişimini eşleştirir.'**
  String get dietLockDescription;

  /// No description provided for @dietEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir ilişki bulunamadı'**
  String get dietEmptyTitle;

  /// No description provided for @dietEmptyMessage.
  ///
  /// In tr, this message translates to:
  /// **'K vitamini yüksek öğünlerinizi kaydettikçe, INR düşüşleriyle bağlantı burada görünür.'**
  String get dietEmptyMessage;

  /// No description provided for @dietInsightsTitle.
  ///
  /// In tr, this message translates to:
  /// **'K vitamini – INR içgörüleri'**
  String get dietInsightsTitle;

  /// No description provided for @entryRowSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{dose} mg/gün · {zone}'**
  String entryRowSubtitle(String dose, String zone);

  /// No description provided for @authSignUpTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get authSignUpTitle;

  /// No description provided for @authSignInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get authSignInTitle;

  /// No description provided for @authEmailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta girin'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'En az 6 karakter olmalı'**
  String get authPasswordTooShort;

  /// No description provided for @authSignUpAction.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get authSignUpAction;

  /// No description provided for @authSignInAction.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get authSignInAction;

  /// No description provided for @authHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabım var, giriş yap'**
  String get authHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabım yok, kayıt ol'**
  String get authNoAccount;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz e-posta adresi.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Bu hesap devre dışı bırakılmış.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta ile kayıtlı bir hesap bulunamadı.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya parola hatalı.'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In tr, this message translates to:
  /// **'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In tr, this message translates to:
  /// **'Parola çok zayıf (en az 6 karakter).'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorNotEnabled.
  ///
  /// In tr, this message translates to:
  /// **'E-posta/parola girişi Firebase Console’da henüz etkinleştirilmemiş.'**
  String get authErrorNotEnabled;

  /// No description provided for @authErrorGeneric.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen bir hata oluştu.'**
  String get authErrorGeneric;

  /// No description provided for @emailLabel.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In tr, this message translates to:
  /// **'Parola'**
  String get passwordLabel;

  /// No description provided for @shareDraftReady.
  ///
  /// In tr, this message translates to:
  /// **'Özet hazırlandı — göndermek için Mesajlar uygulamasında “Gönder”e dokunun.'**
  String get shareDraftReady;

  /// No description provided for @shareNoContact.
  ///
  /// In tr, this message translates to:
  /// **'Önce bu ekrandan acil durum kişisi ve telefonunu kaydedin.'**
  String get shareNoContact;

  /// No description provided for @shareUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda mesaj gönderebilecek bir uygulama bulunamadı.'**
  String get shareUnavailable;

  /// No description provided for @edemaScanNoRisk.
  ///
  /// In tr, this message translates to:
  /// **'Ödem taraması: risk bulunamadı.'**
  String get edemaScanNoRisk;

  /// No description provided for @edemaScanRisk.
  ///
  /// In tr, this message translates to:
  /// **'Risk tespit edildi: {delta} artış + hedef dışı INR.'**
  String edemaScanRisk(String delta);

  /// No description provided for @edemaScanTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Ödem taraması'**
  String get edemaScanTooltip;

  /// No description provided for @scanInrTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kamerayla INR oku'**
  String get scanInrTooltip;

  /// No description provided for @bootstrapFailed.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama başlatılamadı'**
  String get bootstrapFailed;

  /// No description provided for @languageSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get languageSectionTitle;

  /// No description provided for @languageSectionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dili ve sayı/tarih biçimi'**
  String get languageSectionSubtitle;

  /// No description provided for @languageSystemDefault.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz dili'**
  String get languageSystemDefault;

  /// No description provided for @profilePatientSection.
  ///
  /// In tr, this message translates to:
  /// **'Hasta'**
  String get profilePatientSection;

  /// No description provided for @profileNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get profileNameLabel;

  /// No description provided for @profileTargetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedef INR aralığı'**
  String get profileTargetTitle;

  /// No description provided for @profileTargetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hekiminizin sizin için belirlediği aralık'**
  String get profileTargetSubtitle;

  /// No description provided for @profileLowerBound.
  ///
  /// In tr, this message translates to:
  /// **'Alt sınır'**
  String get profileLowerBound;

  /// No description provided for @profileUpperBound.
  ///
  /// In tr, this message translates to:
  /// **'Üst sınır'**
  String get profileUpperBound;

  /// No description provided for @profileCriticalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kritik eşikler'**
  String get profileCriticalTitle;

  /// No description provided for @profileCriticalSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu değerler aşılınca acil uyarı verilir'**
  String get profileCriticalSubtitle;

  /// No description provided for @profileCriticalLow.
  ///
  /// In tr, this message translates to:
  /// **'Kritik düşük'**
  String get profileCriticalLow;

  /// No description provided for @profileCriticalHigh.
  ///
  /// In tr, this message translates to:
  /// **'Kritik yüksek'**
  String get profileCriticalHigh;

  /// No description provided for @profileClotRisk.
  ///
  /// In tr, this message translates to:
  /// **'Pıhtı riski'**
  String get profileClotRisk;

  /// No description provided for @profileBleedRisk.
  ///
  /// In tr, this message translates to:
  /// **'Kanama riski'**
  String get profileBleedRisk;

  /// No description provided for @profileContactTitle.
  ///
  /// In tr, this message translates to:
  /// **'Acil durum kişisi'**
  String get profileContactTitle;

  /// No description provided for @profileContactSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kritik değerde bilgilendirilir'**
  String get profileContactSubtitle;

  /// No description provided for @profileContactPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get profileContactPhone;

  /// No description provided for @profileSmsToggle.
  ///
  /// In tr, this message translates to:
  /// **'Kritik değerde SMS gönder'**
  String get profileSmsToggle;

  /// No description provided for @profileSaveChanges.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikleri kaydet'**
  String get profileSaveChanges;

  /// No description provided for @profileSignOut.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get profileSignOut;

  /// No description provided for @profileInvalidNumber.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz sayı'**
  String get profileInvalidNumber;

  /// No description provided for @profileRangeOrderError.
  ///
  /// In tr, this message translates to:
  /// **'Hedef alt sınır, üst sınırdan küçük olmalı.'**
  String get profileRangeOrderError;

  /// No description provided for @profileThresholdError.
  ///
  /// In tr, this message translates to:
  /// **'Kritik eşikler hedef aralığın dışında olmalı (kritik düşük < {lower}, kritik yüksek > {upper}).'**
  String profileThresholdError(String lower, String upper);

  /// No description provided for @subscriptionFreeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ücretsiz sürüm'**
  String get subscriptionFreeTitle;

  /// No description provided for @subscriptionFreeMessage.
  ///
  /// In tr, this message translates to:
  /// **'PDF rapor, bulut yedek ve sınırsız geçmiş için premium’a geçin.'**
  String get subscriptionFreeMessage;

  /// No description provided for @subscriptionTrialTitle.
  ///
  /// In tr, this message translates to:
  /// **'Deneme sürümü'**
  String get subscriptionTrialTitle;

  /// No description provided for @subscriptionLifetime.
  ///
  /// In tr, this message translates to:
  /// **'Ömür boyu erişim'**
  String get subscriptionLifetime;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliğiniz iptal edilmiş. Bu tarihe kadar premium özellikler açık kalır.'**
  String get subscriptionCancelled;

  /// No description provided for @subscriptionManage.
  ///
  /// In tr, this message translates to:
  /// **'Aboneliği yönet'**
  String get subscriptionManage;

  /// No description provided for @caregiverShareTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakınla paylaşım'**
  String get caregiverShareTitle;

  /// No description provided for @caregiverShareDescription.
  ///
  /// In tr, this message translates to:
  /// **'Son INR değerinizi, bugünkü dozunuzu ve ilaç uyum oranınızı tek dokunuşla yakınınıza gönderin. Uzaktaki bir çocuğunuz ya da bakıcınız durumunuzu düzenli takip edebilir.'**
  String get caregiverShareDescription;

  /// No description provided for @caregiverSharePreparing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor…'**
  String get caregiverSharePreparing;

  /// No description provided for @caregiverShareAction.
  ///
  /// In tr, this message translates to:
  /// **'Durumumu yakınıma gönder'**
  String get caregiverShareAction;

  /// No description provided for @editorDoseAmountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doz miktarı'**
  String get editorDoseAmountTitle;

  /// No description provided for @editorNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'İlaç adı zorunlu.'**
  String get editorNameRequired;

  /// No description provided for @editorWeeklyNeedsDose.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık şemada en az bir güne doz girin.'**
  String get editorWeeklyNeedsDose;

  /// No description provided for @editorNeedsTime.
  ///
  /// In tr, this message translates to:
  /// **'En az bir alım saati ekleyin.'**
  String get editorNeedsTime;

  /// No description provided for @editorNeedsAmount.
  ///
  /// In tr, this message translates to:
  /// **'En az bir saat için doz miktarı girin.'**
  String get editorNeedsAmount;

  /// No description provided for @editorNeedsDay.
  ///
  /// In tr, this message translates to:
  /// **'En az bir gün seçin.'**
  String get editorNeedsDay;

  /// No description provided for @editorDeleteWarning.
  ///
  /// In tr, this message translates to:
  /// **'İlaç planı ve bu ilaca ait alım kayıtları silinir. INR ölçümleriniz etkilenmez.'**
  String get editorDeleteWarning;

  /// No description provided for @editorDiscard.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get editorDiscard;

  /// No description provided for @editorEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlacı düzenle'**
  String get editorEditTitle;

  /// No description provided for @editorAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlaç ekle'**
  String get editorAddTitle;

  /// No description provided for @editorMedicationSection.
  ///
  /// In tr, this message translates to:
  /// **'İlaç'**
  String get editorMedicationSection;

  /// No description provided for @editorNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'İlaç adı'**
  String get editorNameLabel;

  /// No description provided for @editorNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Coumadin'**
  String get editorNameHint;

  /// No description provided for @editorStrengthLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tablet gücü (opsiyonel)'**
  String get editorStrengthLabel;

  /// No description provided for @editorStrengthHelper.
  ///
  /// In tr, this message translates to:
  /// **'Girilirse doz “1 tablet”, “½ tablet” olarak da gösterilir.'**
  String get editorStrengthHelper;

  /// No description provided for @editorAnticoagulantToggle.
  ///
  /// In tr, this message translates to:
  /// **'Kan sulandırıcı (INR’yi etkiler)'**
  String get editorAnticoagulantToggle;

  /// No description provided for @editorAnticoagulantConflict.
  ///
  /// In tr, this message translates to:
  /// **'Zaten bir kan sulandırıcı işaretli. Genelde tek antikoagülan kullanılır — hekiminize danışın.'**
  String get editorAnticoagulantConflict;

  /// No description provided for @editorAnticoagulantHelp.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekranda öne çıkar ve INR kaydında doz olarak önerilir.'**
  String get editorAnticoagulantHelp;

  /// No description provided for @editorFrequencySection.
  ///
  /// In tr, this message translates to:
  /// **'Sıklık'**
  String get editorFrequencySection;

  /// No description provided for @editorFrequencySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İlacın hangi günlerde alınacağı'**
  String get editorFrequencySubtitle;

  /// No description provided for @editorStartDay.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç günü'**
  String get editorStartDay;

  /// No description provided for @editorStartDayHelp.
  ///
  /// In tr, this message translates to:
  /// **'Gün aşırı sayımı bu günden başlar'**
  String get editorStartDayHelp;

  /// No description provided for @editorAmountSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her alımda kaç mg'**
  String get editorAmountSubtitle;

  /// No description provided for @editorOtherSection.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get editorOtherSection;

  /// No description provided for @editorReminderToggle.
  ///
  /// In tr, this message translates to:
  /// **'Hatırlatma bildirimi'**
  String get editorReminderToggle;

  /// No description provided for @editorReminderHelp.
  ///
  /// In tr, this message translates to:
  /// **'Alım saatinde doz bilgisiyle bildirim'**
  String get editorReminderHelp;

  /// No description provided for @editorNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. aç karnına'**
  String get editorNoteHint;

  /// No description provided for @freqDailyHelp.
  ///
  /// In tr, this message translates to:
  /// **'Aynı doz, her gün'**
  String get freqDailyHelp;

  /// No description provided for @freqEveryOtherDayHelp.
  ///
  /// In tr, this message translates to:
  /// **'Bir gün al, bir gün ara ver'**
  String get freqEveryOtherDayHelp;

  /// No description provided for @freqSpecificDaysHelp.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğiniz günlerde, aynı doz'**
  String get freqSpecificDaysHelp;

  /// No description provided for @freqWeeklyPatternHelp.
  ///
  /// In tr, this message translates to:
  /// **'Her gün farklı doz (warfarin şeması)'**
  String get freqWeeklyPatternHelp;

  /// No description provided for @editorRemoveTime.
  ///
  /// In tr, this message translates to:
  /// **'Bu saati kaldır'**
  String get editorRemoveTime;

  /// No description provided for @editorAddTime.
  ///
  /// In tr, this message translates to:
  /// **'Alım saati ekle'**
  String get editorAddTime;

  /// No description provided for @editorTimeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alım saati'**
  String get editorTimeTitle;

  /// No description provided for @editorTimeHelp.
  ///
  /// In tr, this message translates to:
  /// **'Her gün aynı saatte'**
  String get editorTimeHelp;

  /// No description provided for @editorWeeklyTotal.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık toplam: {total}'**
  String editorWeeklyTotal(String total);

  /// No description provided for @editorAmountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Miktar (mg)'**
  String get editorAmountLabel;

  /// No description provided for @ok.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get ok;

  /// No description provided for @editorDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'{medication} silinsin mi?'**
  String editorDeleteTitle(String medication);

  /// No description provided for @editorDoseSection.
  ///
  /// In tr, this message translates to:
  /// **'Doz'**
  String get editorDoseSection;

  /// No description provided for @editorNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Not (opsiyonel)'**
  String get editorNoteLabel;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

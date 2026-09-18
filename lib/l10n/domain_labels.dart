/// Alan (domain) nesnelerinin yerelleştirilmiş etiketleri.
///
/// Modeller ve servisler artık hiçbir kullanıcı metni üretmez — yalnızca
/// yapısal veri döndürür (enum, sayı, kesir). Metne çevirme işi tek yerde,
/// burada yapılır; hem UI hem de metin üretmek zorunda olan servisler
/// (bildirim, PDF, NFC, SMS) aynı fonksiyonları kullanır.
///
/// Neden extension: modele davranış eklerken modelin kendisini `intl`e ve
/// [AppLocalizations]'a bağımlı kılmaz — model saf Dart kalır, test edilmesi
/// trivial olmaya devam eder.
library;

import 'package:flutter/widgets.dart';

import '../models/inr_entry.dart';
import '../services/alert_service.dart';
import '../services/entitlement_service.dart';
import '../models/medication.dart';
import '../models/vitamin_k_log.dart';
import '../services/medication_service.dart';
import 'app_localizations.dart';
import 'formats.dart';

/// Bir ekranın ihtiyaç duyduğu iki yerelleştirme aracını birlikte taşır:
/// cümleler ([l10n]) ve değer biçimleri ([formats]).
class Loc {
  final AppLocalizations l10n;
  final AppFormats formats;

  const Loc(this.l10n, this.formats);

  /// Widget ağacından tek satırda: `context.loc`.
  factory Loc.of(BuildContext context) => Loc(
        AppLocalizations.of(context),
        AppFormats.of(Localizations.localeOf(context)),
      );

  /// Widget ağacı dışından (bildirim, PDF, NFC, SMS) — yerel ayar
  /// uygulamanın seçili dilinden gelir.
  static Future<Loc> forLocale(Locale locale) async => Loc(
        await AppLocalizations.delegate.load(locale),
        AppFormats.of(locale),
      );
}

extension LocContext on BuildContext {
  Loc get loc => Loc.of(this);
}

String inrZoneLabel(Loc loc, InrZone zone) => switch (zone) {
      InrZone.inRange => loc.l10n.zoneInRange,
      InrZone.belowRange => loc.l10n.zoneBelowRange,
      InrZone.aboveRange => loc.l10n.zoneAboveRange,
      InrZone.criticalLow => loc.l10n.zoneCriticalLow,
      InrZone.criticalHigh => loc.l10n.zoneCriticalHigh,
    };

String vitaminKFoodLabel(Loc loc, VitaminKFood food) => switch (food) {
      VitaminKFood.spinach => loc.l10n.foodSpinach,
      VitaminKFood.kale => loc.l10n.foodKale,
      VitaminKFood.chard => loc.l10n.foodChard,
      VitaminKFood.parsley => loc.l10n.foodParsley,
      VitaminKFood.broccoli => loc.l10n.foodBroccoli,
      VitaminKFood.lettuce => loc.l10n.foodLettuce,
      VitaminKFood.greenBeans => loc.l10n.foodGreenBeans,
      VitaminKFood.greenTea => loc.l10n.foodGreenTea,
      VitaminKFood.other => loc.l10n.foodOther,
    };

String portionLabel(Loc loc, PortionSize portion) => switch (portion) {
      PortionSize.small => loc.l10n.portionSmall,
      PortionSize.medium => loc.l10n.portionMedium,
      PortionSize.large => loc.l10n.portionLarge,
    };

String intakeStatusLabel(Loc loc, IntakeStatus status) => switch (status) {
      IntakeStatus.taken => loc.l10n.intakeTaken,
      IntakeStatus.skipped => loc.l10n.intakeSkipped,
    };

String doseFrequencyLabel(Loc loc, DoseFrequency frequency) =>
    switch (frequency) {
      DoseFrequency.daily => loc.l10n.freqDaily,
      DoseFrequency.everyOtherDay => loc.l10n.freqEveryOtherDay,
      DoseFrequency.specificDays => loc.l10n.freqSpecificDays,
      DoseFrequency.weeklyPattern => loc.l10n.freqWeeklyPattern,
    };

extension VitaminKLogLabels on VitaminKLog {
  /// "Diğer" seçildiyse kullanıcının yazdığı ad, değilse katalog adı.
  String displayName(Loc loc) => food == VitaminKFood.other
      ? (customName ?? loc.l10n.foodOther)
      : vitaminKFoodLabel(loc, food);
}

extension DoseTimeLabels on DoseTime {
  String label(Loc loc) => loc.formats.timeOfDay(hour, minute);
}

extension MedicationLabels on Medication {
  /// mg değerinin yerelleştirilmiş gösterimi: "5 mg" / "2,5 mg".
  static String mg(Loc loc, double value) =>
      loc.l10n.doseMg(loc.formats.decimal(value));

  /// "1 tablet", "½ tablet", "1½ tablet". Tablet gücü bilinmiyorsa null.
  String? tabletLabel(Loc loc, double mgAmount) {
    final fraction = tabletFraction(mgAmount);
    return fraction == null ? null : loc.l10n.tabletCount(fraction);
  }

  /// Sıklığın okunabilir özeti — "Her gün · 19:00", "Pzt, Çar, Cum · 08:00".
  String frequencyLabel(Loc loc) {
    switch (frequency) {
      case DoseFrequency.daily:
        if (times.isEmpty) return loc.l10n.freqDaily;
        return loc.l10n.freqDailyAt(times.map((t) => t.label(loc)).join(', '));
      case DoseFrequency.everyOtherDay:
        if (times.isEmpty) return loc.l10n.freqEveryOtherDay;
        return loc.l10n.freqEveryOtherDayAt(times.first.label(loc));
      case DoseFrequency.specificDays:
        final days = (weekdays.toList()..sort())
            .map(loc.formats.weekdayShort)
            .join(', ');
        if (times.isEmpty) return days;
        return loc.l10n.freqSpecificDaysAt(days, times.first.label(loc));
      case DoseFrequency.weeklyPattern:
        final time = times.isEmpty
            ? loc.formats.timeOfDay(19, 0)
            : times.first.label(loc);
        return loc.l10n.freqWeeklyPatternAt(time);
    }
  }

  /// "5 mg · 1 tablet" biçiminde tek satırlık doz özeti.
  String doseSummary(Loc loc, DateTime day) {
    final amount = doseForDay(day);
    if (amount <= 0) return loc.l10n.doseNoneToday;
    final mgLabel = MedicationLabels.mg(loc, amount);
    final tablet = tabletLabel(loc, amount);
    return tablet == null ? mgLabel : loc.l10n.doseSummary(mgLabel, tablet);
  }
}

extension ScheduledDoseLabels on ScheduledDose {
  /// "5 mg · 1 tablet" — bugünün tablosundaki tek bir alım için.
  String amountLabel(Loc loc) {
    final mgLabel = MedicationLabels.mg(loc, amountMg);
    final tablet = medication.tabletLabel(loc, amountMg);
    return tablet == null ? mgLabel : loc.l10n.doseSummary(mgLabel, tablet);
  }
}

/// Uyarı başlığı — tür + değerden üretilir.
String alertTitle(Loc loc, InrAlert alert) => switch (alert.kind) {
      InrAlertKind.criticalLow => loc.l10n.alertCriticalLowTitle,
      InrAlertKind.criticalHigh => loc.l10n.alertCriticalHighTitle,
      InrAlertKind.belowRange => loc.l10n.alertBelowRangeTitle,
      InrAlertKind.aboveRange => loc.l10n.alertAboveRangeTitle,
    };

String alertMessage(Loc loc, InrAlert alert) {
  final value = loc.formats.inr(alert.inrValue);
  final range = alert.targetRange;
  final lower = range == null ? '' : loc.formats.inr(range.lower);
  final upper = range == null ? '' : loc.formats.inr(range.upper);

  return switch (alert.kind) {
    InrAlertKind.criticalLow => loc.l10n.alertCriticalLowMessage(value),
    InrAlertKind.criticalHigh => loc.l10n.alertCriticalHighMessage(value),
    InrAlertKind.belowRange =>
      loc.l10n.alertBelowRangeMessage(value, lower, upper),
    InrAlertKind.aboveRange =>
      loc.l10n.alertAboveRangeMessage(value, lower, upper),
  };
}

String premiumFeatureLabel(Loc loc, PremiumFeature feature) =>
    switch (feature) {
      PremiumFeature.unlimitedHistory => loc.l10n.premiumUnlimitedHistory,
      PremiumFeature.pdfReport => loc.l10n.premiumPdfReport,
      PremiumFeature.ocrScan => loc.l10n.premiumOcrScan,
      PremiumFeature.cloudSync => loc.l10n.premiumCloudSync,
      PremiumFeature.lockScreenWidget => loc.l10n.premiumLockScreenWidget,
      PremiumFeature.dietInsights => loc.l10n.premiumDietInsights,
      PremiumFeature.unlimitedMedications =>
        loc.l10n.premiumUnlimitedMedications,
      PremiumFeature.caregiverSharing => loc.l10n.premiumCaregiverSharing,
    };

String alwaysFreeFeatureLabel(Loc loc, AlwaysFreeFeature feature) =>
    switch (feature) {
      AlwaysFreeFeature.inrLog => loc.l10n.freeInrLog,
      AlwaysFreeFeature.medicationPlan => loc.l10n.freeMedicationPlan,
      AlwaysFreeFeature.criticalAlert => loc.l10n.freeCriticalAlert,
      AlwaysFreeFeature.emergencyContact => loc.l10n.freeEmergencyContact,
      AlwaysFreeFeature.recentTrend => loc.l10n.freeRecentTrend,
      AlwaysFreeFeature.emergencyCard => loc.l10n.freeEmergencyCard,
    };

/// Plan başlığı: "Yıllık", "Aylık", "Ömür boyu".
String subscriptionPlanLabel(Loc loc, SubscriptionPeriod period) =>
    switch (period) {
      SubscriptionPeriod.weekly => loc.l10n.planWeekly,
      SubscriptionPeriod.monthly => loc.l10n.planMonthly,
      SubscriptionPeriod.twoMonth => loc.l10n.planTwoMonth,
      SubscriptionPeriod.threeMonth => loc.l10n.planThreeMonth,
      SubscriptionPeriod.sixMonth => loc.l10n.planSixMonth,
      SubscriptionPeriod.annual => loc.l10n.planAnnual,
      SubscriptionPeriod.lifetime => loc.l10n.planLifetime,
    };

/// Fiyatın yanına gelen dönem: "/ ay", "/ yıl", "tek seferlik".
String subscriptionPeriodLabel(Loc loc, SubscriptionPeriod period) =>
    switch (period) {
      SubscriptionPeriod.weekly => loc.l10n.periodWeek,
      SubscriptionPeriod.monthly => loc.l10n.periodMonth,
      SubscriptionPeriod.twoMonth => loc.l10n.periodTwoMonths,
      SubscriptionPeriod.threeMonth => loc.l10n.periodThreeMonths,
      SubscriptionPeriod.sixMonth => loc.l10n.periodSixMonths,
      SubscriptionPeriod.annual => loc.l10n.periodYear,
      SubscriptionPeriod.lifetime => loc.l10n.periodOneTime,
    };

String purchaseMessageText(Loc loc, PurchaseMessage message) =>
    switch (message) {
      PurchaseMessage.storeUnavailable => loc.l10n.purchaseStoreUnavailable,
      PurchaseMessage.planNotFound => loc.l10n.purchasePlanNotFound,
      PurchaseMessage.purchaseCompleted => loc.l10n.purchaseCompleted,
      PurchaseMessage.purchaseNotCompleted => loc.l10n.purchaseNotCompleted,
      PurchaseMessage.pendingApproval => loc.l10n.purchasePendingApproval,
      PurchaseMessage.alreadyActive => loc.l10n.purchaseAlreadyActive,
      PurchaseMessage.noConnection => loc.l10n.purchaseNoConnection,
      PurchaseMessage.notAllowed => loc.l10n.purchaseNotAllowed,
      PurchaseMessage.restoreCompleted => loc.l10n.restoreCompleted,
      PurchaseMessage.restoreNothingFound => loc.l10n.restoreNothingFound,
      PurchaseMessage.restoreFailed => loc.l10n.restoreFailed,
    };

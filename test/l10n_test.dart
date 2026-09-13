/// Dil sisteminin bütünlük testleri.
///
/// Amaç: yeni bir dil eklendiğinde ya da bir anahtar unutulduğunda
/// derleme değil **test** patlasın. Eksik çeviri sessizce şablon dile
/// düşer; tıbbi bir uygulamada bunun fark edilmeden yayına çıkması
/// kabul edilemez.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/l10n/app_localizations.dart';
import 'package:inr_takip/l10n/domain_labels.dart';
import 'package:inr_takip/l10n/formats.dart';
import 'package:inr_takip/models/inr_entry.dart';
import 'package:inr_takip/models/medication.dart';
import 'package:inr_takip/models/vitamin_k_log.dart';
import 'package:inr_takip/services/alert_service.dart';
import 'package:inr_takip/services/app_settings.dart';
import 'package:inr_takip/services/entitlement_service.dart';

import 'l10n_helper.dart';

void main() {
  test('desteklenen her dil yüklenebilir ve temel metinleri doludur',
      () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.appTitle, isNotEmpty, reason: locale.languageCode);
      expect(l10n.tabToday, isNotEmpty, reason: locale.languageCode);
      expect(l10n.alertCriticalHighTitle, isNotEmpty,
          reason: locale.languageCode);
    }
  });

  test('her enum değerinin her dilde bir etiketi vardır', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final loc = await testLoc(locale.languageCode);
      for (final zone in InrZone.values) {
        expect(inrZoneLabel(loc, zone), isNotEmpty);
      }
      for (final food in VitaminKFood.values) {
        expect(vitaminKFoodLabel(loc, food), isNotEmpty);
      }
      for (final portion in PortionSize.values) {
        expect(portionLabel(loc, portion), isNotEmpty);
      }
      for (final frequency in DoseFrequency.values) {
        expect(doseFrequencyLabel(loc, frequency), isNotEmpty);
      }
      for (final status in IntakeStatus.values) {
        expect(intakeStatusLabel(loc, status), isNotEmpty);
      }
      for (final feature in PremiumFeature.values) {
        expect(premiumFeatureLabel(loc, feature), isNotEmpty);
      }
      for (final feature in AlwaysFreeFeature.values) {
        expect(alwaysFreeFeatureLabel(loc, feature), isNotEmpty);
      }
      for (final period in SubscriptionPeriod.values) {
        expect(subscriptionPlanLabel(loc, period), isNotEmpty);
        expect(subscriptionPeriodLabel(loc, period), isNotEmpty);
      }
      for (final message in PurchaseMessage.values) {
        expect(purchaseMessageText(loc, message), isNotEmpty);
      }
      for (final kind in InrAlertKind.values) {
        final alert = InrAlert(
          severity: AlertSeverity.warning,
          kind: kind,
          inrValue: 2.4,
          targetRange: TargetRange.standard,
          weightDeltaKg: 1.8,
        );
        expect(alertTitle(loc, alert), isNotEmpty);
        expect(alertMessage(loc, alert), isNotEmpty);
      }
    }
  });

  test('uyarı metni değeri ve aralığı gerçekten içerir', () async {
    const alert = InrAlert(
      severity: AlertSeverity.warning,
      kind: InrAlertKind.aboveRange,
      inrValue: 3.4,
      targetRange: TargetRange.standard,
    );

    final tr = await testLoc('tr');
    expect(alertMessage(tr, alert), contains('3,4'));
    expect(alertMessage(tr, alert), contains('2,0'));

    final en = await testLoc('en');
    expect(alertMessage(en, alert), contains('3.4'));
    expect(alertMessage(en, alert), contains('2.0'));
  });

  group('AppFormats', () {
    test('ondalık ayracı bölgeye göre değişir', () {
      expect(AppFormats('tr', usesPounds: false).decimal(2.5), '2,5');
      expect(AppFormats('en_US', usesPounds: true).decimal(2.5), '2.5');
      expect(AppFormats('de', usesPounds: false).decimal(2.5), '2,5');
    });

    test('ağırlık yalnızca ABD yerel ayarında pound gösterilir', () {
      expect(AppFormats.of(const Locale('en', 'US')).weightKg(1.5),
          contains('lb'));
      expect(AppFormats.of(const Locale('en', 'CA')).weightKg(1.5),
          contains('kg'));
      expect(AppFormats.of(const Locale('tr')).weightKg(1.5), contains('kg'));
    });

    test('pound dönüşümü doğru', () {
      final us = AppFormats('en_US', usesPounds: true);
      // 1,5 kg = 3,3 lb
      expect(us.weightKg(1.5), '3.3 lb');
    });

    test('INR her zaman tek ondalıkla gösterilir', () {
      final tr = AppFormats('tr', usesPounds: false);
      expect(tr.inr(3), '3,0');
      expect(tr.inr(2.45), '2,5');
    });
  });

  group('yerel ayar çözümleme', () {
    test('desteklenmeyen dil şablon dile düşer', () {
      expect(resolveSupportedLocale(const Locale('sw')),
          AppLocalizations.supportedLocales.first);
    });

    test('ülke varyantı aynı dile eşlenir', () {
      expect(resolveSupportedLocale(const Locale('en', 'GB')).languageCode,
          'en');
    });

    test('null tercih şablon dili verir', () {
      expect(resolveSupportedLocale(null),
          AppLocalizations.supportedLocales.first);
    });

    test('dil etiketi ayrıştırma', () {
      expect(parseLocale('en').languageCode, 'en');
      expect(parseLocale('pt-BR').countryCode, 'BR');
      expect(parseLocale('zh-Hans').scriptCode, 'Hans');
    });
  });
}

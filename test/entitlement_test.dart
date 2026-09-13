/// Premium yetkilendirme kuralları.
///
/// En kritik test: güvenlik özelliklerinin paywall'a takılmaması.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/l10n/domain_labels.dart';
import 'package:inr_takip/services/entitlement_service.dart';

import 'l10n_helper.dart';

void main() {
  late FakeEntitlementGateway gateway;
  late EntitlementService service;

  setUp(() {
    gateway = FakeEntitlementGateway();
    service = EntitlementService(gateway);
  });

  tearDown(() {
    service.dispose();
    gateway.dispose();
  });

  test('varsayılan ücretsiz katmandır', () async {
    await service.start();
    expect(service.isPremium, isFalse);
    expect(service.has(PremiumFeature.pdfReport), isFalse);
    expect(service.historyWindowDays, FreeTierLimits.historyDays);
  });

  test('abonelik açılınca tüm premium özellikler açılır', () async {
    await service.start();
    gateway.emit(const Entitlement(isPremium: true, productId: 'annual'));
    await Future<void>.delayed(Duration.zero);

    expect(service.isPremium, isTrue);
    for (final feature in PremiumFeature.values) {
      expect(service.has(feature), isTrue, reason: feature.name);
    }
    expect(service.historyWindowDays, isNull);
  });

  test('ücretsiz katmanda ilaç sayısı sınırlı', () async {
    await service.start();
    expect(service.canAddMedication(0), isTrue);
    expect(service.canAddMedication(FreeTierLimits.medicationCount - 1), isTrue);
    expect(service.canAddMedication(FreeTierLimits.medicationCount), isFalse);
  });

  test('premium ile ilaç sınırı kalkar', () async {
    await service.start();
    gateway.emit(const Entitlement(isPremium: true));
    await Future<void>.delayed(Duration.zero);
    expect(service.canAddMedication(50), isTrue);
  });

  test('güvenlik özellikleri hiçbir zaman ücretli değildir', () async {
    // Artık metin değil TÜR karşılaştırılıyor: 18 dilde çeviri kayarsa
    // bile bu sınır kaymaz.
    expect(
      kAlwaysFreeFeatures,
      containsAll([
        AlwaysFreeFeature.criticalAlert,
        AlwaysFreeFeature.emergencyContact,
        AlwaysFreeFeature.medicationPlan,
        AlwaysFreeFeature.emergencyCard,
      ]),
    );

    // Ücretsiz ve premium listeleri aynı etikete sahip olmamalı: kullanıcı
    // aynı adı hem "her zaman ücretsiz" hem "premium" görürse güven kaybolur.
    final loc = await testLoc();
    final premiumLabels =
        PremiumFeature.values.map((f) => premiumFeatureLabel(loc, f)).toSet();
    for (final free in kAlwaysFreeFeatures) {
      expect(premiumLabels, isNot(contains(alwaysFreeFeatureLabel(loc, free))));
    }
  });

  test('abonelik durumu değişince dinleyiciler haberdar olur', () async {
    await service.start();
    var notifications = 0;
    service.addListener(() => notifications++);

    gateway.emit(const Entitlement(isPremium: true));
    await Future<void>.delayed(Duration.zero);
    gateway.emit(const Entitlement.free());
    await Future<void>.delayed(Duration.zero);

    expect(notifications, 2);
    expect(service.isPremium, isFalse);
  });
}

/// Ekranların gerçekten çizildiğini ve doz/sıklık bilgisinin görünür
/// olduğunu doğrulayan widget testleri.
library;

import 'package:flutter/material.dart';
import 'package:inr_takip/l10n/app_localizations.dart';
import 'package:inr_takip/l10n/domain_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/models/inr_entry.dart';
import 'package:inr_takip/models/medication.dart';
import 'package:inr_takip/models/patient_profile.dart';
import 'package:inr_takip/repositories/repositories.dart';
import 'package:inr_takip/services/entitlement_service.dart';
import 'package:inr_takip/services/medication_service.dart';
import 'package:inr_takip/ui/medication_card.dart';
import 'package:inr_takip/ui/medications_screen.dart';
import 'package:inr_takip/ui/premium_gate.dart';
import 'package:inr_takip/ui/theme.dart';

import 'package:inr_takip/ui/today_screen.dart';

import 'l10n_helper.dart';

Medication warfarin({DateTime? start}) => Medication(
      id: 'w',
      name: 'Coumadin',
      startDate: start ?? DateTime(2026, 8, 31),
      isAnticoagulant: true,
      unitStrengthMg: 5,
      frequency: DoseFrequency.weeklyPattern,
      weeklyDoseMg: const {1: 5, 2: 2.5, 3: 5, 4: 2.5, 5: 5, 6: 5, 7: 2.5},
      times: const [DoseTime(hour: 19, minute: 0, amountMg: 0)],
    );

Widget wrap(Widget child, EntitlementService service) => PremiumScope(
      service: service,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    );

void main() {
  late FakeEntitlementGateway gateway;
  late EntitlementService entitlements;

  setUp(() {
    gateway = FakeEntitlementGateway();
    entitlements = EntitlementService(gateway);
  });

  tearDown(() {
    entitlements.dispose();
    gateway.dispose();
  });

  testWidgets('haftalık şerit her günün dozunu gösterir', (tester) async {
    await tester.pumpWidget(wrap(
      SingleChildScrollView(
        child: WeeklyDoseStrip(
          medication: warfarin(),
          today: DateTime(2026, 8, 31),
        ),
      ),
      entitlements,
    ));

    // Gün başlıkları ve mg değerleri ekranda.
    expect(find.text('Pzt'), findsOneWidget);
    expect(find.text('Paz'), findsOneWidget);
    expect(find.text('2,5'), findsNWidgets(3)); // Sal, Per, Paz
    expect(find.text('Toplam 27,5 mg'), findsOneWidget);
  });

  testWidgets('ilaç satırı dozu ve sıklığı birlikte gösterir',
      (tester) async {
    await tester.pumpWidget(wrap(
      MedicationSummaryTile(
        medication: warfarin(),
        today: DateTime(2026, 8, 31), // Pazartesi -> 5 mg
      ),
      entitlements,
    ));

    expect(find.textContaining('5 mg · 1 tablet'), findsOneWidget);
    expect(find.textContaining('Haftalık şema · 19:00'), findsOneWidget);
    expect(find.text('Kan sulandırıcı'), findsOneWidget);
  });

  testWidgets('ilaç yokken boş durum ve ekleme butonu görünür',
      (tester) async {
    final medRepo = InMemoryMedicationRepository();
    final intakeRepo = InMemoryDoseIntakeRepository();

    await tester.pumpWidget(wrap(
      MedicationsScreen(
        repository: medRepo,
        service: MedicationService(medRepo, intakeRepo),
        onChanged: () async {},
      ),
      entitlements,
    ));
    await tester.pump();

    expect(find.text('Henüz ilaç eklemediniz'), findsOneWidget);
    expect(find.text('İlk ilacı ekle'), findsOneWidget);
  });

  testWidgets('Bugün ekranı sonraki dozu miktarıyla gösterir',
      (tester) async {
    final medRepo = InMemoryMedicationRepository();
    final intakeRepo = InMemoryDoseIntakeRepository();
    await medRepo.upsert(warfarin(start: DateTime.now()));

    final service = MedicationService(medRepo, intakeRepo);
    // Bugünün planı; saat 19:00 dozu henüz işaretlenmemiş.
    final day = await service.buildDay(DateTime.now());

    await tester.pumpWidget(wrap(
      TodayScreen(
        profile: const PatientProfile(name: 'Ayşe Yılmaz'),
        trend: null,
        medicationDay: day,
        anticoagulant: await service.primaryAnticoagulant(),
        onMark: (_, __) async {},
        onAddMeasurement: () {},
        onOpenMedications: () {},
      ),
      entitlements,
    ));
    await tester.pump();

    expect(find.textContaining('Ayşe'), findsOneWidget);
    expect(find.text('Coumadin'), findsWidgets);
    // Doz miktarı kartta yazılı olmalı (mg + tablet).
    expect(find.textContaining('mg'), findsWidgets);
    expect(find.text('Aldım'), findsOneWidget);
    // Ölçüm yokken açıklayıcı boş durum.
    expect(find.text('Henüz ölçüm yok'), findsOneWidget);
  });

  testWidgets('premium olmayan kullanıcıya kilit kartı gösterilir',
      (tester) async {
    await entitlements.start();
    await tester.pumpWidget(wrap(
      const SingleChildScrollView(
        child: PremiumLockCard(
          feature: PremiumFeature.pdfReport,
          icon: Icons.picture_as_pdf_outlined,
          title: 'Doktor raporu',
          description: 'Vizit için PDF özet.',
        ),
      ),
      entitlements,
    ));

    expect(find.text('Premium ile aç'), findsOneWidget);
  });

  testWidgets('INR bölge renkleri ve etiketleri her dilde tanımlı',
      (tester) async {
    for (final tag in ['tr', 'en']) {
      final loc = await testLoc(tag);
      for (final zone in InrZone.values) {
        for (final brightness in Brightness.values) {
          expect(ZoneColors.of(zone, brightness).foreground, isNotNull);
        }
        // Renk tek başına bilgi taşımaz: her bölgenin metni de olmalı.
        expect(inrZoneLabel(loc, zone), isNotEmpty);
      }
    }
  });
}

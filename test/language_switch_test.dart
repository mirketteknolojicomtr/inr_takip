/// Dil değişiminin ekrana gerçekten yansıdığının uçtan uca kanıtı.
///
/// Birim testi "çeviri dosyasında karşılığı var" der; bu test "ekranda
/// görünüyor" der. İkisi farklı şeylerdir: bir widget yanlışlıkla sabit
/// metin kullanıyorsa yalnızca bu test yakalar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/l10n/app_localizations.dart';
import 'package:inr_takip/models/medication.dart';
import 'package:inr_takip/models/patient_profile.dart';
import 'package:inr_takip/services/entitlement_service.dart';
import 'package:inr_takip/services/medication_service.dart';
import 'package:inr_takip/ui/premium_gate.dart';
import 'package:inr_takip/ui/theme.dart';
import 'package:inr_takip/ui/today_screen.dart';

final _medication = Medication(
  id: 'm1',
  name: 'Coumadin',
  startDate: DateTime(2026, 1, 1),
  isAnticoagulant: true,
  unitStrengthMg: 5,
  times: const [DoseTime(hour: 19, minute: 0, amountMg: 2.5)],
);

Widget _app(Locale locale, EntitlementService service) => PremiumScope(
      service: service,
      child: MaterialApp(
        locale: locale,
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: TodayScreen(
            profile: const PatientProfile(name: 'Ayşe'),
            trend: null,
            medicationDay: MedicationDay(
              date: DateTime(2026, 8, 31),
              doses: [
                ScheduledDose(
                  medication: _medication,
                  scheduledAt: DateTime(2026, 8, 31, 19),
                  amountMg: 2.5,
                ),
              ],
            ),
            anticoagulant: _medication,
            onMark: (_, __) async {},
            onAddMeasurement: () {},
            onOpenMedications: () {},
          ),
        ),
      ),
    );

void main() {
  late EntitlementService service;

  setUp(() => service = EntitlementService(FakeEntitlementGateway()));

  testWidgets('Türkçede ekran Türkçe metin gösterir', (tester) async {
    await tester.pumpWidget(_app(const Locale('tr'), service));
    await tester.pump();

    expect(find.text('Güncel INR'), findsOneWidget);
    // ListView içinde aşağıda kalan bölüm inşa edilmemiş olabilir; başlığı
    // görünür hale getirip doğrula.
    await tester.scrollUntilVisible(find.text('Bugünün ilaçları'), 200);
    expect(find.text('Bugünün ilaçları'), findsOneWidget);
  });

  testWidgets('İngilizcede aynı ekran İngilizce metin gösterir',
      (tester) async {
    await tester.pumpWidget(_app(const Locale('en'), service));
    await tester.pump();

    expect(find.text('Current INR'), findsOneWidget);
    // Türkçe metin hiçbir yerde kalmamalı: sabit dize sızıntısı olurdu.
    expect(find.text('Güncel INR'), findsNothing);
    await tester.scrollUntilVisible(find.text('Today’s medications'), 200);
    expect(find.text('Today’s medications'), findsOneWidget);
  });

  testWidgets('sayı biçimi de yerel ayara uyar', (tester) async {
    await tester.pumpWidget(_app(const Locale('tr'), service));
    await tester.pump();
    expect(find.textContaining('2,5 mg'), findsWidgets);

    await tester.pumpWidget(_app(const Locale('en'), service));
    await tester.pump();
    expect(find.textContaining('2.5 mg'), findsWidgets);
  });
}

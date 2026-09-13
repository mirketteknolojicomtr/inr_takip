/// Ölçüm ekleme diyaloğu: doz otomatik dolsun, kaydet tek sefer koşsun.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_helper.dart';
import 'package:inr_takip/models/medication.dart';
import 'package:inr_takip/services/medication_service.dart';
import 'package:inr_takip/ui/add_measurement_dialog.dart';

Medication warfarin() => Medication(
      id: 'w',
      name: 'Coumadin',
      startDate: DateTime(2026, 8, 31),
      isAnticoagulant: true,
      unitStrengthMg: 5,
      times: const [DoseTime(hour: 19, minute: 0, amountMg: 2.5)],
    );

Future<void> openDialog(
  WidgetTester tester, {
  DoseSuggestion? suggestion,
  void Function(double inr, double dose)? onSave,
}) async {
  await tester.pumpWidget(localizedApp(
    Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AddMeasurementDialog(
                suggestion: suggestion,
                onSave: onSave ?? (_, __) {},
              ),
            ),
            child: const Text('Aç'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Aç'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('doz alanı ilaç planından otomatik dolar', (tester) async {
    await openDialog(
      tester,
      suggestion: DoseSuggestion(
        medication: warfarin(),
        mg: 2.5,
        fromToday: true,
      ),
    );

    final doseField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'O günkü doz'),
    );
    expect(doseField.controller?.text, '2,5');
    expect(find.text('Coumadin planınızdan alındı'), findsOneWidget);
  });

  testWidgets('öneri yoksa alan boş ve yönlendirici metin görünür',
      (tester) async {
    await openDialog(tester);

    final doseField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'O günkü doz'),
    );
    expect(doseField.controller?.text, isEmpty);
    expect(
      find.text('İlaç planı eklerseniz burası kendiliğinden dolar'),
      findsOneWidget,
    );
  });

  testWidgets('önerilen doz olduğu gibi kaydedilir', (tester) async {
    double? savedInr;
    double? savedDose;

    await openDialog(
      tester,
      suggestion: DoseSuggestion(
        medication: warfarin(),
        mg: 2.5,
        fromToday: true,
      ),
      onSave: (inr, dose) {
        savedInr = inr;
        savedDose = dose;
      },
    );

    await tester.enterText(
        find.widgetWithText(TextField, 'INR değeri'), '2,8');
    await tester.tap(find.text('Kaydet'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(savedInr, 2.8);
    expect(savedDose, 2.5, reason: 'otomatik doz kaydedilmedi');
    // Diyalog kapandı ama alttaki ekran ayakta (siyah ekran regresyonu).
    expect(find.text('Yeni INR ölçümü'), findsNothing);
    expect(find.text('Aç'), findsOneWidget);
  });

  testWidgets('geçersiz INR kaydetmez, hata gösterir', (tester) async {
    var saveCount = 0;
    await openDialog(tester, onSave: (_, __) => saveCount++);

    await tester.enterText(
        find.widgetWithText(TextField, 'INR değeri'), '99');
    await tester.tap(find.text('Kaydet'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(saveCount, 0);
    expect(find.text('INR değeri 0–20 arasında olmalı.'), findsOneWidget);
    expect(find.text('Yeni INR ölçümü'), findsOneWidget);
  });
}

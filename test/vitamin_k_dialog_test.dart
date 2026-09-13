/// K vitamini öğün girişi: kayıt üretimi ve iptal davranışı.
///
/// Bu ekran olmadan model, sqflite tablosu ve diyet korelasyonu boşta
/// kalıyordu — içgörüler hep boş dönüyordu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_helper.dart';
import 'package:inr_takip/models/vitamin_k_log.dart';
import 'package:inr_takip/ui/vitamin_k_dialog.dart';

Future<VitaminKLog?> _openAndTap(
  WidgetTester tester, {
  required String food,
  String? portion,
  required String action,
}) async {
  VitaminKLog? saved;

  await tester.pumpWidget(localizedApp(
    Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => VitaminKDialog(
              now: DateTime(2026, 8, 30, 13, 30),
              onSave: (log) => saved = log,
            ),
          ),
          child: const Text('aç'),
        ),
      ),
    ),
  ));

  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();

  // SteadyTouchTarget ham pointer olaylarını dinler; dokunuş metnin tam
  // üstüne düşmeyebilir (bkz. add_measurement_dialog_test.dart).
  await tester.tap(find.text(food), warnIfMissed: false);
  await tester.pumpAndSettle();
  if (portion != null) {
    await tester.tap(find.text(portion), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(action), warnIfMissed: false);
  await tester.pumpAndSettle();

  return saved;
}

void main() {
  testWidgets('seçilen gıda ve porsiyon kayda geçer', (tester) async {
    final log = await _openAndTap(
      tester,
      food: 'Brokoli',
      portion: 'Bol',
      action: 'Kaydet',
    );

    expect(log, isNotNull);
    expect(log!.food, VitaminKFood.broccoli);
    expect(log.portion, PortionSize.large);
    expect(log.date, DateTime(2026, 8, 30, 13, 30));
    // Brokoli 3 puan x bol porsiyon 1.5 = 4.5 göreli K yükü.
    expect(log.kLoad, 4.5);
    expect(log.id, isNotEmpty);
  });

  testWidgets('iptal hiçbir kayıt üretmez', (tester) async {
    final log = await _openAndTap(
      tester,
      food: 'Ispanak',
      action: 'İptal',
    );

    expect(log, isNull);
  });

  testWidgets('"Diğer" seçilince ad zorunludur', (tester) async {
    VitaminKLog? saved;

    await tester.pumpWidget(localizedApp(
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => VitaminKDialog(
                now: DateTime(2026, 8, 30),
                onSave: (log) => saved = log,
              ),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Diğer'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(saved, isNull);
    expect(find.text('Gıdanın adını yazın.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Semizotu');
    // SteadyTouchArea'nın tremor sıçrama filtresi gerçek saatle çalışır
    // (DateTime.now). Test sahte saatte koştuğu için gerçek zamanın
    // ilerlemesi `runAsync` ile sağlanır; aksi hâlde ikinci onay
    // "sıçrama" sanılıp yutulur.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.tap(find.text('Kaydet'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.customName, 'Semizotu');
  });
}

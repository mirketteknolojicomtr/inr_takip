/// Ölçüm ekleme diyaloğundaki "Kaydet" akışının regresyon testi.
///
/// Hata: [SteadyTouchArea] ham pointer olaylarını dinler ve bırakma anında
/// en yakın [SteadyTouchTarget]'ı tetikler. Hedefin içindeki butonun kendi
/// `onPressed`'i de ayrıca çalıştığı için "Kaydet" iki kez koşuyor ve
/// `Navigator.pop` iki kez çağrılıyordu: ilki diyaloğu, ikincisi ana
/// ekranın rotasını kapatıp uygulamayı siyah ekranda bırakıyordu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_helper.dart';
import 'package:inr_takip/ui/steady_touch.dart';

void main() {
  testWidgets('Kaydet tek sefer tetiklenir, ana rota kapanmaz',
      (tester) async {
    var saveCount = 0;

    await tester.pumpWidget(localizedApp(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (ctx) {
                  void trySave() {
                    saveCount++;
                    Navigator.pop(ctx);
                  }

                  return SteadyTouchArea(
                    child: AlertDialog(
                      title: const Text('Yeni INR ölçümü'),
                      actions: [
                        SteadyTouchTarget(
                          id: 'iptal',
                          onConfirm: () => Navigator.pop(ctx),
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('İptal'),
                          ),
                        ),
                        SteadyTouchTarget(
                          id: 'kaydet',
                          onConfirm: trySave,
                          child: FilledButton(
                            onPressed: trySave,
                            child: const Text('Kaydet'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni INR ölçümü'), findsOneWidget);

    // IgnorePointer nedeniyle tap hedefi butonun kendisi değil,
    // üstteki SteadyTouchArea listener'ı -- beklenen davranış.
    await tester.tap(find.text('Kaydet'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Tek kayıt, tek pop: diyalog kapandı ama ana ekran ayakta.
    expect(saveCount, 1, reason: 'Kaydet birden fazla kez tetiklendi');
    expect(find.text('Yeni INR ölçümü'), findsNothing);
    expect(find.text('Aç'), findsOneWidget,
        reason: 'ana ekran da pop edilmiş (siyah ekran)');
  });

  testWidgets('mıknatıs bölgesi dışındaki alana dokunmak kaydetmez',
      (tester) async {
    var saveCount = 0;
    final ctrl = TextEditingController();

    await tester.pumpWidget(localizedApp(
      Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Metin alanı mıknatıs bölgesinin DIŞINDA olmalı.
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'INR değeri'),
            ),
            SteadyTouchArea(
              child: SteadyTouchTarget(
                id: 'kaydet',
                onConfirm: () => saveCount++,
                child: FilledButton(
                  onPressed: () => saveCount++,
                  child: const Text('Kaydet'),
                ),
              ),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(saveCount, 0, reason: 'metin alanına dokunmak kaydetti');

    await tester.tap(find.text('Kaydet'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(saveCount, 1);
  });

  testWidgets('İptal’e dokunmak Kaydet’i tetiklemez', (tester) async {
    var saveCount = 0;
    var cancelCount = 0;

    await tester.pumpWidget(localizedApp(
      Scaffold(
        body: SteadyTouchArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SteadyTouchTarget(
                id: 'iptal',
                onConfirm: () => cancelCount++,
                child: TextButton(
                  onPressed: () => cancelCount++,
                  child: const Text('İptal'),
                ),
              ),
              SteadyTouchTarget(
                id: 'kaydet',
                onConfirm: () => saveCount++,
                child: FilledButton(
                  onPressed: () => saveCount++,
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    ));

    await tester.tap(find.text('İptal'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(cancelCount, 1);
    expect(saveCount, 0, reason: 'İptal, Kaydet’i mıknatısladı');
  });
}

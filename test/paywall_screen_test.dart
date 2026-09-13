import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'l10n_helper.dart';
import 'package:inr_takip/services/entitlement_service.dart';
import 'package:inr_takip/ui/paywall_screen.dart';

/// Paywall'ın kapatılması hiçbir koşulda ekranı boşaltmamalı.
///
/// Regresyon: paywall tek route olarak açıldığında (dev önizleme, deep link,
/// ileride push notification'dan doğrudan açılma) kapatma tuşu Navigator'ı
/// boşaltıyor ve kullanıcı siyah ekranda kalıyordu.
void main() {
  late EntitlementService service;

  setUp(() {
    service = EntitlementService(FakeEntitlementGateway());
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('bir ekranın üstüne açıldığında kapatınca alttaki ekran döner',
      (tester) async {
    await tester.pumpWidget(localizedApp(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => PaywallScreen(service: service),
                ),
              ),
              child: const Text('Premium'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();
    expect(find.text('INR Takip Premium'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('INR Takip Premium'), findsNothing);
  });

  testWidgets('tek route olarak açıldığında kapatma tuşu ekranı boşaltmaz',
      (tester) async {
    await tester.pumpWidget(localizedApp(
      PaywallScreen(service: service),
    ));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Siyah ekran yok: paywall hâlâ ayakta ve çizilebilir durumda.
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(find.text('INR Takip Premium'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kapatma tuşuna iki kez basmak alttaki ekranı da kapatmaz',
      (tester) async {
    await tester.pumpWidget(localizedApp(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaywallScreen(service: service),
                ),
              ),
              child: const Text('Premium'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();

    final close = find.byIcon(Icons.close);
    await tester.tap(close);
    await tester.pump();
    // Kapanış animasyonu sürerken ikinci dokunuş.
    if (tester.any(close)) {
      await tester.tap(close, warnIfMissed: false);
    }
    await tester.pumpAndSettle();

    expect(find.text('Premium'), findsOneWidget);
  });
}

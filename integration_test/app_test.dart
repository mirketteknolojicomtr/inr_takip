/// Gerçek cihaz/simülatör üzerinde uçtan uca akış testi.
///
/// Amaç: "ölçüm ekleyince ekran bozuluyor" sınıfı hataları yakalamak.
/// Widget testleri sahte bir rasterizer kullandığı için gerçek çizim
/// hatalarını göremez; bu test gerçek Flutter engine'inde koşar.
///
///   flutter test integration_test/app_test.dart -d <simulator-udid>
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:inr_takip/firebase_options.dart';
import 'package:inr_takip/l10n/app_localizations.dart';
import 'package:inr_takip/main.dart';
import 'package:inr_takip/services/entitlement_service.dart';
import 'package:inr_takip/services/firebase_auth_service.dart';
import 'package:inr_takip/ui/premium_gate.dart';
import 'package:inr_takip/ui/theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> bootApp(WidgetTester tester) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    final entitlements = EntitlementService(FakeEntitlementGateway());
    await entitlements.start();

    await tester.pumpWidget(PremiumScope(
      service: entitlements,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) =>
            clampTextScale(context, child ?? const SizedBox.shrink()),
        home: HomeShell(uid: 'e2e', authService: FirebaseAuthService()),
      ),
    ));
    // Bootstrap (sqflite + trend + ilaç planı) tamamlansın.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Bugün').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  testWidgets('ölçüm ekleme akışı ekranı bozmuyor', (tester) async {
    await bootApp(tester);
    expect(tester.takeException(), isNull, reason: 'açılışta hata');

    // "Ölçüm ekle" -> diyalog
    await tester.tap(find.text('Ölçüm ekle'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni INR ölçümü'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'INR değeri'), '2,6');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Diyalog kapandı, hata yok, hero çizildi.
    expect(tester.takeException(), isNull, reason: 'kayıt sırasında hata');
    expect(find.text('Yeni INR ölçümü'), findsNothing);
    expect(find.text('Güncel INR'), findsOneWidget);
  });

  testWidgets('dört sekme de hatasız çiziliyor', (tester) async {
    await bootApp(tester);

    for (final tab in ['İlaçlarım', 'Geçmiş', 'Profil', 'Bugün']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab).last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: '$tab sekmesinde hata');
    }
  });

  testWidgets('ilaç ekleme ekranı açılıyor', (tester) async {
    await bootApp(tester);
    await tester
        .tap(find.widgetWithText(NavigationDestination, 'İlaçlarım').last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final addButton = find.text('İlaç ekle').evaluate().isNotEmpty
        ? find.text('İlaç ekle')
        : find.text('İlk ilacı ekle');
    await tester.tap(addButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Sıklık'), findsOneWidget);
  });
}

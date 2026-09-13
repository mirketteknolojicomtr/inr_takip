/// GEÇİCİ geliştirme girişi. Firebase oturumu olmadan doğrudan [HomeShell]'i
/// açar; yalnızca UI'yi simülatörde incelemek için.
///   flutter run -t lib/dev_preview.dart
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'services/entitlement_service.dart';
import 'services/firebase_auth_service.dart';
import 'ui/paywall_screen.dart';
import 'ui/premium_gate.dart';
import 'ui/theme.dart';

/// Mağaza bağlantısı olmayan simülatörde paywall'ı dolu göstermek için;
/// fiyatlar App Store Connect'te tanımlı gerçek fiyatlarla aynıdır.
class _StoreScreenshotGateway extends FakeEntitlementGateway {
  @override
  Future<List<SubscriptionOffer>> offers() async => const [
        SubscriptionOffer(
          id: r'$rc_annual',
          period: SubscriptionPeriod.annual,
          priceString: '\$34,99',
          perMonthString: '\$2,92',
          trialDays: 7,
          savingPercent: 27,
        ),
        SubscriptionOffer(
          id: r'$rc_monthly',
          period: SubscriptionPeriod.monthly,
          priceString: '\$3,99',
          trialDays: 7,
        ),
        SubscriptionOffer(
          id: r'$rc_lifetime',
          period: SubscriptionPeriod.lifetime,
          priceString: '\$89,99',
        ),
      ];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final entitlements = EntitlementService(_StoreScreenshotGateway());
  await entitlements.start();

  const paywall = bool.fromEnvironment('DEV_PAYWALL');

  runApp(PremiumScope(
    service: entitlements,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) =>
          clampTextScale(context, child ?? const SizedBox.shrink()),
      home: _DevHome(
        entitlements: entitlements,
        openPaywall: paywall,
      ),
    ),
  ));
}

/// Paywall'ı gerçek akıştaki gibi HomeShell'in ÜSTÜNE açar; böylece kapatma
/// tuşu alttaki ekrana döner (home olarak açılsaydı Navigator boşalırdı).
class _DevHome extends StatefulWidget {
  final EntitlementService entitlements;
  final bool openPaywall;

  const _DevHome({required this.entitlements, required this.openPaywall});

  @override
  State<_DevHome> createState() => _DevHomeState();
}

class _DevHomeState extends State<_DevHome> {
  final _paywallScroll = ScrollController();

  /// Mağaza ekran görüntüsünde fiyatların görünmesi için başlangıç kaydırması.
  static const _scrollTo = int.fromEnvironment('DEV_SCROLL');

  @override
  void initState() {
    super.initState();
    if (widget.openPaywall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PrimaryScrollController(
            controller: _paywallScroll,
            child: PaywallScreen(service: widget.entitlements),
          ),
        ));
        if (_scrollTo > 0) {
          Future.delayed(const Duration(milliseconds: 900), () {
            if (!_paywallScroll.hasClients) return;
            final max = _paywallScroll.position.maxScrollExtent;
            _paywallScroll.jumpTo(_scrollTo.toDouble().clamp(0, max));
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _paywallScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HomeShell(
        uid: 'dev-preview',
        authService: FirebaseAuthService(),
        initialTab: const int.fromEnvironment('DEV_TAB'),
      );
}

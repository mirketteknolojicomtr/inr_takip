/// RevenueCat yapılandırması.
///
/// Anahtarlar kaynak koda gömülmez; derleme sırasında verilir:
///
/// ```
/// flutter run \
///   --dart-define=RC_IOS_KEY=appl_XXXXXXXX \
///   --dart-define=RC_ANDROID_KEY=goog_XXXXXXXX
/// ```
///
/// (RevenueCat public SDK anahtarları gizli değildir, ama yine de
/// store'a göre ayrıştırmak ve repoda tutmamak doğru pratiktir.)
///
/// Anahtar verilmezse uygulama `FakeEntitlementGateway` ile çalışır:
/// herkes ücretsiz katmandadır, hiçbir ekran kilitlenmez, çökme olmaz.
library;

import 'dart:io';

class RevenueCatConfig {
  /// RevenueCat panelindeki Entitlement identifier'ı.
  /// Panel > Entitlements > "premium" olarak oluşturun.
  static const entitlementId =
      String.fromEnvironment('RC_ENTITLEMENT', defaultValue: 'premium');

  /// Panel > Offerings > "default" offering.
  static const offeringId =
      String.fromEnvironment('RC_OFFERING', defaultValue: 'default');

  static const _iosKey = String.fromEnvironment('RC_IOS_KEY');
  static const _androidKey = String.fromEnvironment('RC_ANDROID_KEY');

  /// Geliştirme sırasında paywall'ı atlamak için:
  /// `--dart-define=DEBUG_PREMIUM=true`
  static const debugPremium =
      bool.fromEnvironment('DEBUG_PREMIUM', defaultValue: false);

  static String? get apiKey {
    if (Platform.isIOS || Platform.isMacOS) {
      return _iosKey.isEmpty ? null : _iosKey;
    }
    if (Platform.isAndroid) {
      return _androidKey.isEmpty ? null : _androidKey;
    }
    return null;
  }

  static bool get isConfigured => apiKey != null;
}

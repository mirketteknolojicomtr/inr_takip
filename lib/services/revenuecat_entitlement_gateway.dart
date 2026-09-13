/// [EntitlementGateway]'in RevenueCat implementasyonu.
///
/// `purchases_flutter` paketine bağımlı TEK dosya budur; geri kalan
/// uygulama yalnızca `entitlement_service.dart`'taki soyut arayüzü görür.
/// Sağlayıcı değişirse (doğrudan `in_app_purchase`, Adapty vb.) yalnızca
/// bu dosya yeniden yazılır.
///
/// Kurulum:
///  1. RevenueCat panelinde Entitlement: `premium`
///  2. Offering: `default`, paketler: `$rc_monthly`, `$rc_annual`,
///     `$rc_lifetime`
///  3. App Store Connect / Play Console'da abonelik ürünlerini oluşturup
///     RevenueCat'e bağlayın; fiyatı MAĞAZADA belirleyin (uygulamada
///     sabit fiyat yazmak mağaza kurallarına aykırıdır).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:url_launcher/url_launcher.dart';

import '../config/revenuecat_config.dart';
import 'entitlement_service.dart';

class RevenueCatEntitlementGateway implements EntitlementGateway {
  final String _entitlementId;
  final String _offeringId;

  final _controller = StreamController<Entitlement>.broadcast();
  rc.CustomerInfo? _lastInfo;
  bool _configured = false;

  RevenueCatEntitlementGateway({
    String? entitlementId,
    String? offeringId,
  })  : _entitlementId = entitlementId ?? RevenueCatConfig.entitlementId,
        _offeringId = offeringId ?? RevenueCatConfig.offeringId;

  @override
  Future<void> initialize() async {
    if (_configured) return;
    final apiKey = RevenueCatConfig.apiKey;
    if (apiKey == null) return; // yapılandırılmamış -> ücretsiz katman

    try {
      await rc.Purchases.setLogLevel(
        kDebugMode ? rc.LogLevel.debug : rc.LogLevel.warn,
      );
      await rc.Purchases.configure(rc.PurchasesConfiguration(apiKey));
      rc.Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      _configured = true;
    } catch (e) {
      // Mağaza servisleri yoksa (emülatör, Play Services eksik cihaz)
      // uygulama yine de açılmalı.
      debugPrint('[REVENUECAT] configure başarısız: $e');
    }
  }

  void _onCustomerInfo(rc.CustomerInfo info) {
    _lastInfo = info;
    _controller.add(_map(info));
  }

  /// RevenueCat'in `CustomerInfo` nesnesini uygulama modeline çevirir.
  Entitlement _map(rc.CustomerInfo info) {
    final active = info.entitlements.active[_entitlementId];
    if (active == null || !active.isActive) return const Entitlement.free();
    return Entitlement(
      isPremium: true,
      // RevenueCat tarihleri ISO-8601 String döndürür.
      expiresAt: active.expirationDate == null
          ? null
          : DateTime.tryParse(active.expirationDate!),
      productId: active.productIdentifier,
      isTrial: active.periodType == rc.PeriodType.trial,
      willRenew: active.willRenew,
    );
  }

  @override
  Future<void> identify(String appUserId) async {
    if (!_configured) return;
    try {
      final result = await rc.Purchases.logIn(appUserId);
      _onCustomerInfo(result.customerInfo);
    } catch (e) {
      debugPrint('[REVENUECAT] logIn başarısız: $e');
    }
  }

  @override
  Future<void> logOut() async {
    if (!_configured) return;
    try {
      final info = await rc.Purchases.logOut();
      _onCustomerInfo(info);
    } catch (e) {
      debugPrint('[REVENUECAT] logOut başarısız: $e');
    }
  }

  @override
  Future<Entitlement> current() async {
    if (!_configured) return const Entitlement.free();
    try {
      final info = await rc.Purchases.getCustomerInfo();
      _lastInfo = info;
      return _map(info);
    } catch (e) {
      debugPrint('[REVENUECAT] getCustomerInfo başarısız: $e');
      // Ağ yoksa son bilinen durumu koru; abonelik ağ hatası yüzünden
      // kapanmamalı.
      final cached = _lastInfo;
      return cached == null ? const Entitlement.free() : _map(cached);
    }
  }

  @override
  Stream<Entitlement> watch() => _controller.stream;

  @override
  Future<List<SubscriptionOffer>> offers() async {
    if (!_configured) return const [];
    try {
      final offerings = await rc.Purchases.getOfferings();
      final offering = offerings.getOffering(_offeringId) ?? offerings.current;
      final packages = offering?.availablePackages ?? const <rc.Package>[];
      if (packages.isEmpty) return const [];

      // Yıllık plandaki tasarrufu hesaplamak için aylık fiyat referansı.
      final monthly = _firstWhereOrNull(
        packages,
        (p) => p.packageType == rc.PackageType.monthly,
      );
      final monthlyPrice = monthly?.storeProduct.price;

      // Paywall'da gösterim sırası paket tipinden gelir; rozetin varlığına
      // bağlamak kırılgandı (aylık plan yoksa yıllık rozet alamıyor ve
      // sıralama rastgeleleşiyordu).
      final sorted = [...packages]
        ..sort((a, b) =>
            _typeOrder(a.packageType).compareTo(_typeOrder(b.packageType)));
      return sorted.map((p) => _mapPackage(p, monthlyPrice)).toList();
    } catch (e) {
      debugPrint('[REVENUECAT] getOfferings başarısız: $e');
      return const [];
    }
  }

  /// Paywall'da gösterim sırası: yıllık (önerilen) > aylık > ömür boyu.
  int _typeOrder(rc.PackageType type) => switch (type) {
        rc.PackageType.annual => 0,
        rc.PackageType.sixMonth => 1,
        rc.PackageType.threeMonth => 2,
        rc.PackageType.twoMonth => 3,
        rc.PackageType.monthly => 4,
        rc.PackageType.weekly => 5,
        rc.PackageType.lifetime => 6,
        _ => 7,
      };

  SubscriptionOffer _mapPackage(rc.Package p, double? monthlyReference) {
    final product = p.storeProduct;
    final isLifetime = p.packageType == rc.PackageType.lifetime;

    // Başlık ve dönem metni burada üretilmez: paket tipi olduğu gibi
    // taşınır, cümleye çevirme paywall'da yapılır (bkz. domain_labels.dart).
    final period = switch (p.packageType) {
      rc.PackageType.annual => SubscriptionPeriod.annual,
      rc.PackageType.monthly => SubscriptionPeriod.monthly,
      rc.PackageType.sixMonth => SubscriptionPeriod.sixMonth,
      rc.PackageType.threeMonth => SubscriptionPeriod.threeMonth,
      rc.PackageType.twoMonth => SubscriptionPeriod.twoMonth,
      rc.PackageType.weekly => SubscriptionPeriod.weekly,
      _ => SubscriptionPeriod.lifetime,
    };

    // Yıllık planın aylığa göre tasarrufu.
    int? savingPercent;
    if (p.packageType == rc.PackageType.annual &&
        monthlyReference != null &&
        monthlyReference > 0) {
      final perMonth = product.price / 12;
      final saving = (1 - perMonth / monthlyReference) * 100;
      if (saving >= 5) savingPercent = saving.round();
    }

    return SubscriptionOffer(
      id: p.identifier,
      period: period,
      priceString: product.priceString,
      perMonthString: isLifetime ? null : product.pricePerMonthString,
      trialDays: _trialDays(product.introductoryPrice),
      savingPercent: savingPercent,
    );
  }

  int? _trialDays(rc.IntroductoryPrice? intro) {
    if (intro == null || intro.price > 0) return null;
    final units = intro.periodNumberOfUnits * intro.cycles;
    return switch (intro.periodUnit) {
      rc.PeriodUnit.day => units,
      rc.PeriodUnit.week => units * 7,
      rc.PeriodUnit.month => units * 30,
      rc.PeriodUnit.year => units * 365,
      _ => null,
    };
  }

  @override
  Future<PurchaseResult> purchase(SubscriptionOffer offer) async {
    if (!_configured) {
      return const PurchaseResult(
        PurchaseOutcome.failed,
        Entitlement.free(),
        message: PurchaseMessage.storeUnavailable,
      );
    }

    try {
      final offerings = await rc.Purchases.getOfferings();
      final offering = offerings.getOffering(_offeringId) ?? offerings.current;
      final package = offering == null
          ? null
          : _firstWhereOrNull(
              offering.availablePackages,
              (p) => p.identifier == offer.id,
            );

      if (package == null) {
        return PurchaseResult(
          PurchaseOutcome.failed,
          await current(),
          message: PurchaseMessage.planNotFound,
        );
      }

      final result =
          await rc.Purchases.purchase(rc.PurchaseParams.package(package));
      _lastInfo = result.customerInfo;
      final entitlement = _map(result.customerInfo);
      _controller.add(entitlement);

      return PurchaseResult(
        entitlement.isPremium
            ? PurchaseOutcome.success
            : PurchaseOutcome.pending,
        entitlement,
        message: entitlement.isPremium
            ? PurchaseMessage.purchaseCompleted
            : PurchaseMessage.pendingApproval,
      );
    } on PlatformException catch (e) {
      return _mapError(e);
    } catch (e) {
      return PurchaseResult(
        PurchaseOutcome.failed,
        await current(),
        message: PurchaseMessage.purchaseNotCompleted,
        detail: '$e',
      );
    }
  }

  Future<PurchaseResult> _mapError(PlatformException e) async {
    final code = rc.PurchasesErrorHelper.getErrorCode(e);
    final entitlement = await current();

    return switch (code) {
      rc.PurchasesErrorCode.purchaseCancelledError =>
        PurchaseResult(PurchaseOutcome.cancelled, entitlement),
      rc.PurchasesErrorCode.paymentPendingError => PurchaseResult(
          PurchaseOutcome.pending,
          entitlement,
          message: PurchaseMessage.pendingApproval,
        ),
      rc.PurchasesErrorCode.productAlreadyPurchasedError => PurchaseResult(
          PurchaseOutcome.success,
          entitlement,
          message: PurchaseMessage.alreadyActive,
        ),
      rc.PurchasesErrorCode.networkError => PurchaseResult(
          PurchaseOutcome.failed,
          entitlement,
          message: PurchaseMessage.noConnection,
        ),
      rc.PurchasesErrorCode.purchaseNotAllowedError => PurchaseResult(
          PurchaseOutcome.failed,
          entitlement,
          message: PurchaseMessage.notAllowed,
        ),
      _ => PurchaseResult(
          PurchaseOutcome.failed,
          entitlement,
          message: PurchaseMessage.purchaseNotCompleted,
        ),
    };
  }

  @override
  Future<PurchaseResult> restore() async {
    if (!_configured) {
      return const PurchaseResult(
        PurchaseOutcome.failed,
        Entitlement.free(),
        message: PurchaseMessage.storeUnavailable,
      );
    }
    try {
      final info = await rc.Purchases.restorePurchases();
      _lastInfo = info;
      final entitlement = _map(info);
      _controller.add(entitlement);
      return PurchaseResult(
        PurchaseOutcome.success,
        entitlement,
        message: entitlement.isPremium
            ? PurchaseMessage.restoreCompleted
            : PurchaseMessage.restoreNothingFound,
      );
    } catch (e) {
      return PurchaseResult(
        PurchaseOutcome.failed,
        await current(),
        message: PurchaseMessage.restoreFailed,
        detail: '$e',
      );
    }
  }

  /// Aboneliği iptal/yönetme: mağazanın kendi sayfası açılır
  /// (App Store ve Play, iptalin uygulama içinde değil mağazada
  /// yapılmasını şart koşar).
  @override
  Future<void> openManagementPage() async {
    final url = _lastInfo?.managementURL;
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// `package:collection` bağımlılığı eklemeden `firstWhereOrNull`.
  static T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  void dispose() {
    if (_configured) {
      rc.Purchases.removeCustomerInfoUpdateListener(_onCustomerInfo);
    }
    _controller.close();
  }
}

/// Premium (abonelik) yetkilendirme katmanı — mağaza SDK'sından bağımsız.
///
/// Tasarım kararı: RevenueCat (veya ileride başka bir sağlayıcı) yalnızca
/// [EntitlementGateway] arayüzünü implemente eder. UI ve iş mantığı
/// `purchases_flutter` paketini hiç görmez; böylece testlerde
/// [FakeEntitlementGateway] ile tek satır DI değişikliği yeterlidir
/// (bkz. ARCHITECTURE.md "Temiz kod kararları").
///
/// ÖNEMLİ KLİNİK KURAL: Güvenlikle ilgili hiçbir özellik paywall'ın
/// arkasına konmaz. Kritik INR uyarısı, acil durum kişisine SMS, ilaç
/// hatırlatıcısı, ilaç planı ve son 30 günün takibi her zaman ücretsizdir
/// ([kAlwaysFreeFeatures] listesi bunu kodda sabitler). Premium yalnızca
/// kolaylık ve derinlik özelliklerini kapsar.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Ücretli (premium) özellikler. Etiket taşımaz — ad çeviri katmanından
/// gelir (bkz. l10n/domain_labels.dart `premiumFeatureLabel`).
enum PremiumFeature {
  /// 30 günden eski trend ve ölçüm geçmişi.
  unlimitedHistory,

  /// Doktor viziti için PDF rapor.
  pdfReport,

  /// Kamerayla cihaz ekranından INR okuma (OCR).
  ocrScan,

  /// Firestore üzerinden bulut yedek + çoklu cihaz.
  cloudSync,

  /// Apple Health / Google Fit ölçümleri + ödem riski taraması.
  healthSync,

  /// Ana ekran / kilit ekranı widget'ı.
  lockScreenWidget,

  /// K vitamini ↔ INR korelasyon içgörüleri.
  dietInsights,

  /// 2'den fazla ilaç ekleme.
  unlimitedMedications,

  /// Yakınla paylaşım.
  caregiverSharing,
}

/// Paywall'ın ARKASINA ASLA KONMAYACAK özellikler.
///
/// Bu bir pazarlama listesi değil, kodda uygulanan bir sınır:
/// [EntitlementService.has] bunları her zaman true döner ve
/// `entitlement_test.dart` premium listesiyle kesişmediğini doğrular.
/// Enum olması, çeviriyle birlikte kaymasını da imkânsız kılar — 18 dilde
/// metin karşılaştırmak yerine tür karşılaştırılır.
enum AlwaysFreeFeature {
  inrLog,
  medicationPlan,
  criticalAlert,
  emergencyContact,
  recentTrend,
  emergencyCard,
}

const kAlwaysFreeFeatures = AlwaysFreeFeature.values;

/// Ücretsiz katman limitleri.
class FreeTierLimits {
  /// Ücretsiz kullanıcının görebildiği geçmiş penceresi.
  static const historyDays = 30;

  /// Ücretsiz kullanıcının ekleyebileceği ilaç sayısı.
  /// Antikoagülan + bir yardımcı ilaç ücretsiz kalır.
  static const medicationCount = 2;
}

/// Kullanıcının güncel abonelik durumu.
@immutable
class Entitlement {
  final bool isPremium;
  final DateTime? expiresAt;
  final String? productId;

  /// Deneme süresi içinde mi?
  final bool isTrial;

  /// Dönem sonunda yenilenecek mi? (iptal edilmişse false)
  final bool willRenew;

  const Entitlement({
    required this.isPremium,
    this.expiresAt,
    this.productId,
    this.isTrial = false,
    this.willRenew = false,
  });

  const Entitlement.free() : this(isPremium: false);

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.isPremium == isPremium &&
      other.expiresAt == expiresAt &&
      other.productId == productId &&
      other.isTrial == isTrial &&
      other.willRenew == willRenew;

  @override
  int get hashCode =>
      Object.hash(isPremium, expiresAt, productId, isTrial, willRenew);
}

/// Mağazadan gelen tek bir abonelik seçeneği. Fiyat metni **her zaman**
/// mağazadan gelir (yerel para birimi, vergi dahil) — uygulamada sabit
/// fiyat yazmak App Store/Play kurallarına aykırıdır.
@immutable
class SubscriptionOffer {
  /// RevenueCat package identifier (ör. `$rc_annual`).
  final String id;

  /// Planın süresi — başlık ve "/ay" gibi ekler bundan üretilir.
  final SubscriptionPeriod period;

  /// Mağazadan gelen biçimlendirilmiş fiyat (ör. "₺499,99").
  final String priceString;

  /// Aylığa çevrilmiş fiyat metni (yıllık planda gösterilir).
  final String? perMonthString;

  /// Ücretsiz deneme gün sayısı (yoksa null).
  final int? trialDays;

  /// Aylığa göre tasarruf yüzdesi (yalnızca yıllık planda, %5'ten büyükse).
  final int? savingPercent;

  const SubscriptionOffer({
    required this.id,
    required this.period,
    required this.priceString,
    this.perMonthString,
    this.trialDays,
    this.savingPercent,
  });

  bool get isLifetime => period == SubscriptionPeriod.lifetime;
}

/// Mağaza paket tipinin dilden bağımsız karşılığı.
enum SubscriptionPeriod { weekly, monthly, twoMonth, threeMonth, sixMonth, annual, lifetime }

/// Satın alma akışının sonucu.
enum PurchaseOutcome { success, cancelled, pending, failed }

/// Kullanıcıya gösterilecek sonucun TÜRÜ (metin değil).
enum PurchaseMessage {
  storeUnavailable,
  planNotFound,
  purchaseCompleted,
  purchaseNotCompleted,
  pendingApproval,
  alreadyActive,
  noConnection,
  notAllowed,
  restoreCompleted,
  restoreNothingFound,
  restoreFailed,
}

class PurchaseResult {
  final PurchaseOutcome outcome;
  final Entitlement entitlement;
  final PurchaseMessage? message;

  /// Teknik hata ayrıntısı (mağaza SDK'sından). Kullanıcıya gösterilmez,
  /// yalnızca günlüğe yazılır — çevrilecek bir metin değildir.
  final String? detail;

  const PurchaseResult(
    this.outcome,
    this.entitlement, {
    this.message,
    this.detail,
  });
}

/// Mağaza soyutlaması. RevenueCat implementasyonu için bkz.
/// `revenuecat_entitlement_gateway.dart`.
abstract interface class EntitlementGateway {
  /// SDK'yı başlatır. Hata fırlatmaz — yapılandırılmamışsa sessizce
  /// ücretsiz katmanda kalır (uygulama asla paywall yüzünden açılmamazlık
  /// etmemeli).
  Future<void> initialize();

  /// Firebase kullanıcısını RevenueCat App User ID ile eşler; böylece
  /// abonelik cihaz değil hesap bazlı taşınır.
  Future<void> identify(String appUserId);

  Future<void> logOut();

  Future<Entitlement> current();

  /// Abonelik durumu değiştikçe yayın yapar (yenileme, iptal, iade).
  Stream<Entitlement> watch();

  Future<List<SubscriptionOffer>> offers();

  Future<PurchaseResult> purchase(SubscriptionOffer offer);

  /// "Satın alımları geri yükle" — App Store zorunlu şartı.
  Future<PurchaseResult> restore();

  /// Abonelik yönetimi ekranını açar (iptal için mağaza sayfası).
  Future<void> openManagementPage();
}

/// Uygulama genelinde tek yetkilendirme kaynağı.
///
/// [ChangeNotifier]'dır: `PremiumScope` bunu dinler, abonelik değişince
/// paywall'lı ekranlar kendiliğinden açılır/kilitlenir.
class EntitlementService extends ChangeNotifier {
  final EntitlementGateway _gateway;
  StreamSubscription<Entitlement>? _sub;

  Entitlement _entitlement = const Entitlement.free();
  bool _ready = false;

  EntitlementService(this._gateway);

  Entitlement get entitlement => _entitlement;
  bool get isPremium => _entitlement.isPremium;

  /// SDK yanıtı gelene kadar false — UI bu sırada kilitli varsayar,
  /// böylece premium içerik bir an için "sızmaz".
  bool get isReady => _ready;

  Future<void> start({String? appUserId}) async {
    await _gateway.initialize();
    if (appUserId != null) await _gateway.identify(appUserId);
    _entitlement = await _gateway.current();
    _ready = true;
    _sub?.cancel();
    _sub = _gateway.watch().listen((e) {
      _entitlement = e;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> signOut() async {
    await _gateway.logOut();
    _entitlement = await _gateway.current();
    notifyListeners();
  }

  /// Bu özellik şu an kullanılabilir mi?
  bool has(PremiumFeature feature) => _entitlement.isPremium;

  /// Ücretsiz kullanıcının görebileceği geçmiş penceresi (gün).
  /// Premium'da `null` = sınır yok.
  int? get historyWindowDays =>
      has(PremiumFeature.unlimitedHistory) ? null : FreeTierLimits.historyDays;

  /// [currentCount] ilaç varken bir tane daha eklenebilir mi?
  bool canAddMedication(int currentCount) =>
      has(PremiumFeature.unlimitedMedications) ||
      currentCount < FreeTierLimits.medicationCount;

  Future<List<SubscriptionOffer>> offers() => _gateway.offers();

  Future<PurchaseResult> purchase(SubscriptionOffer offer) async {
    final result = await _gateway.purchase(offer);
    if (result.outcome == PurchaseOutcome.success) {
      _entitlement = result.entitlement;
      notifyListeners();
    }
    return result;
  }

  Future<PurchaseResult> restore() async {
    final result = await _gateway.restore();
    _entitlement = result.entitlement;
    notifyListeners();
    return result;
  }

  Future<void> openManagementPage() => _gateway.openManagementPage();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// RevenueCat anahtarı tanımlı değilken (ör. testler, CI, ilk kurulum)
/// kullanılan yedek gateway. Uygulama çalışır, herkes ücretsiz katmandadır.
class FakeEntitlementGateway implements EntitlementGateway {
  final _controller = StreamController<Entitlement>.broadcast();
  Entitlement _entitlement;

  FakeEntitlementGateway({bool premium = false})
      : _entitlement = premium
            ? const Entitlement(isPremium: true, productId: 'debug_premium')
            : const Entitlement.free();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> identify(String appUserId) async {}

  @override
  Future<void> logOut() async {}

  @override
  Future<Entitlement> current() async => _entitlement;

  @override
  Stream<Entitlement> watch() => _controller.stream;

  @override
  Future<List<SubscriptionOffer>> offers() async => const [];

  @override
  Future<PurchaseResult> purchase(SubscriptionOffer offer) async =>
      PurchaseResult(
        PurchaseOutcome.failed,
        _entitlement,
        message: PurchaseMessage.storeUnavailable,
      );

  @override
  Future<PurchaseResult> restore() async =>
      PurchaseResult(PurchaseOutcome.success, _entitlement);

  @override
  Future<void> openManagementPage() async {}

  /// Testlerde durumu değiştirmek için.
  void emit(Entitlement entitlement) {
    _entitlement = entitlement;
    _controller.add(entitlement);
  }

  void dispose() => _controller.close();
}

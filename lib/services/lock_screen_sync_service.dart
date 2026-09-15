/// Acil Durum Yüzeyi Senkronizasyonu (widget + NFC).
///
/// InrRepository + ProfileRepository'deki değişiklikleri dinler, saf bir
/// fonksiyonla ([LockScreenPayload.build]) gösterilecek veriyi üretir ve
/// kayıtlı **her** [LockScreenGateway]'e yayınlar:
///   - [HomeWidgetLockScreenGateway] -> ana/kilit ekranı widget'ı (premium),
///   - [NfcEmergencyService] -> Android HCE ile pasif NFC kartı (ücretsiz;
///     acil durum kartı `kAlwaysFreeFeatures` içindedir).
///
/// Bir gateway hata verirse (ör. NFC donanımı yok, iOS'ta HCE desteklenmiyor)
/// diğerleri yayına devam eder: acil durum yüzeylerinden birinin arızası
/// ötekini sessizce düşürmemelidir.
///
/// Native taraf (bu dosyanın kapsamı dışında, iOS/Android proje
/// hedeflerinde yazılır):
///   iOS   -> WidgetKit uzantısı, App Group'tan `UserDefaults(suiteName:)`
///            ile okur (bkz. sohbetteki Swift örneği).
///   Android -> Glance widget'ı, `HomeWidgetGlanceStateDefinition` ile aynı
///            SharedPreferences'ı okur (bkz. sohbetteki Kotlin örneği).
///
/// pubspec: home_widget: ^0.7.0
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../l10n/domain_labels.dart';
import '../models/inr_entry.dart';
import '../models/patient_profile.dart';
import '../repositories/repositories.dart';
import 'alert_service.dart' show LocProvider;

/// Widget'ta gösterilecek verinin saf/yan-etkisiz temsili.
/// Native tarafın anlayacağı düz string alanlara indirger.
class LockScreenPayload {
  final String patientName;
  final double? lastInr;
  final DateTime? lastInrDate;
  final bool isStable;
  final String medicationName;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const LockScreenPayload({
    required this.patientName,
    required this.lastInr,
    required this.lastInrDate,
    required this.isStable,
    required this.medicationName,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  /// SAF FONKSİYON: repository verisinden widget payload'ı üretir.
  factory LockScreenPayload.build({
    required PatientProfile profile,
    required InrEntry? latestEntry,
  }) {
    return LockScreenPayload(
      patientName: profile.name,
      lastInr: latestEntry?.inrValue,
      lastInrDate: latestEntry?.date,
      isStable: latestEntry?.isInRange ?? false,
      medicationName: profile.schedule.medicationName,
      emergencyContactName: profile.emergencyContact?.name,
      emergencyContactPhone: profile.emergencyContact?.phone,
    );
  }

  /// Kilit ekranında tek satırda gösterilecek, yüksek okunabilirlikli özet.
  /// Örn: "SON INR: 2,5 (STABİL)" — dil ve sayı biçimi [loc]'tan gelir.
  String headline(Loc loc) {
    final value = lastInr;
    if (value == null) return loc.l10n.emergencyNoRecord;
    final status = isStable
        ? loc.l10n.emergencyStatusStable
        : loc.l10n.emergencyStatusAttention;
    return loc.l10n.emergencyHeadline(loc.formats.inr(value), status);
  }
}

/// Widget'ın okuyacağı paylaşılan depoya yazan soyutlama —
/// testte mock'lanır, üretimde [HomeWidgetLockScreenGateway] kullanılır.
abstract interface class LockScreenGateway {
  /// [loc] dışarıdan verilir: widget ve NFC yüzeyleri aynı senkron
  /// döngüsünde, aynı dilde yayınlanmalıdır.
  Future<void> publish(LockScreenPayload payload, Loc loc);

  /// Hesap silinince yüzeydeki kişisel bilgiyi (ad, INR, acil kişi) kaldırır.
  Future<void> clear();
}

/// `home_widget` paketiyle App Group (iOS) / SharedPreferences (Android)
/// köprüsü. Anahtar isimleri native widget koduyla birebir eşleşmelidir.
class HomeWidgetLockScreenGateway implements LockScreenGateway {
  static const _iosWidgetKind = 'InrEmergencyWidget';
  static const _androidWidgetName = 'InrEmergencyGlanceWidget';

  /// ios/InrEmergencyWidgetExtension'daki entitlements dosyasıyla ve
  /// ios/Runner/Runner.entitlements ile birebir aynı olmalı.
  static const _iosAppGroupId = 'group.com.mirketteknoloji.inrtakip';

  bool _appGroupConfigured = false;

  Future<void> _ensureAppGroupConfigured() async {
    if (_appGroupConfigured) return;
    await HomeWidget.setAppGroupId(_iosAppGroupId);
    _appGroupConfigured = true;
  }

  @override
  Future<void> publish(LockScreenPayload payload, Loc loc) async {
    await _ensureAppGroupConfigured();
    await HomeWidget.saveWidgetData<String>('patientName', payload.patientName);
    await HomeWidget.saveWidgetData<String>('headline', payload.headline(loc));
    await HomeWidget.saveWidgetData<String>(
        'medication', payload.medicationName);
    await HomeWidget.saveWidgetData<String>(
        'emergencyContactName', payload.emergencyContactName ?? '');
    await HomeWidget.saveWidgetData<String>(
        'emergencyContactPhone', payload.emergencyContactPhone ?? '');

    await HomeWidget.updateWidget(
      iOSName: _iosWidgetKind,
      androidName: _androidWidgetName,
    );
  }

  /// `null` yazmak anahtarı paylaşılan depodan siler; widget boş durumuna
  /// döner.
  @override
  Future<void> clear() async {
    await _ensureAppGroupConfigured();
    for (final key in const [
      'patientName',
      'headline',
      'medication',
      'emergencyContactName',
      'emergencyContactPhone',
    ]) {
      await HomeWidget.saveWidgetData<String>(key, null);
    }
    await HomeWidget.updateWidget(
      iOSName: _iosWidgetKind,
      androidName: _androidWidgetName,
    );
  }
}

class LockScreenSyncService {
  final InrRepository _inrRepo;
  final ProfileRepository _profileRepo;
  final List<LockScreenGateway> _gateways;
  final LocProvider _loc;

  StreamSubscription<List<InrEntry>>? _sub;
  bool _started = false;

  LockScreenSyncService(
    this._inrRepo,
    this._profileRepo,
    List<LockScreenGateway> gateways,
    this._loc,
  ) : _gateways = [...gateways];

  /// İlk senkronizasyonu yapar, sonra her yeni INR kaydında otomatik
  /// tekrarlar. Poll yok — repository'nin zaten reaktif olan
  /// `watchEntries()` akışına abone olunur (bkz. ARCHITECTURE.md).
  /// Birden fazla çağrılırsa (ör. önce ücretsiz NFC yüzeyi, sonra abonelik
  /// açılınca widget) ikinci abonelik açılmaz.
  Future<void> start() async {
    if (_started) {
      await _syncNow();
      return;
    }
    _started = true;
    await _syncNow();
    _sub = _inrRepo.watchEntries().listen((_) => _syncNow());
  }

  /// Çalışırken yeni bir yüzey ekler ve hemen besler — abonelik uygulama
  /// açıkken satın alındığında widget'ın boş kalmaması için.
  Future<void> addGateway(LockScreenGateway gateway) async {
    if (_gateways.contains(gateway)) return;
    _gateways.add(gateway);
    if (_started) await _syncNow();
  }

  Future<void> _syncNow() async {
    if (_gateways.isEmpty) return;
    final profile = await _profileRepo.getProfile();
    if (profile == null) return;
    final latest = await _inrRepo.getLatest();
    final payload =
        LockScreenPayload.build(profile: profile, latestEntry: latest);
    final loc = await _loc();

    for (final gateway in _gateways) {
      try {
        await gateway.publish(payload, loc);
      } catch (e) {
        // Tek bir yüzeyin arızası (NFC donanımı yok, widget kaldırılmış)
        // diğerlerini durdurmamalı.
        debugPrint('[ACİL YÜZEY YAYIN HATASI] ${gateway.runtimeType}: $e');
      }
    }
  }

  /// Hesap silinirken: INR akışını durdurur ve tüm yüzeylerdeki kişisel
  /// bilgiyi kaldırır. Bir yüzeyin arızası diğerlerini durdurmaz.
  Future<void> clearAll() async {
    await _sub?.cancel();
    _sub = null;
    _started = false;
    for (final gateway in _gateways) {
      try {
        await gateway.clear();
      } catch (e) {
        debugPrint('[ACİL YÜZEY TEMİZLEME HATASI] ${gateway.runtimeType}: $e');
      }
    }
  }

  void dispose() => _sub?.cancel();
}

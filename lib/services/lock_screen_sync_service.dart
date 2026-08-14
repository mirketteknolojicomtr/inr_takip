/// Kilit Ekranı / Acil Durum Widget Senkronizasyonu.
///
/// InrRepository + ProfileRepository'deki değişiklikleri dinler, saf bir
/// fonksiyonla ([LockScreenPayload.build]) gösterilecek metni üretir ve
/// [LockScreenGateway] üzerinden paylaşılan depoya (App Group / Android
/// SharedPreferences) yazıp widget'ın zaman çizelgesini yeniler.
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

import 'package:home_widget/home_widget.dart';

import '../models/inr_entry.dart';
import '../models/patient_profile.dart';
import '../repositories/repositories.dart';

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
  /// Örn: "SON INR: 2.5 (STABİL)"
  String get headlineTr {
    final value = lastInr;
    if (value == null) return 'INR kaydı yok';
    final status = isStable ? 'STABİL' : 'DİKKAT';
    return 'SON INR: ${value.toStringAsFixed(1)} ($status)';
  }
}

/// Widget'ın okuyacağı paylaşılan depoya yazan soyutlama —
/// testte mock'lanır, üretimde [HomeWidgetLockScreenGateway] kullanılır.
abstract interface class LockScreenGateway {
  Future<void> publish(LockScreenPayload payload);
}

/// `home_widget` paketiyle App Group (iOS) / SharedPreferences (Android)
/// köprüsü. Anahtar isimleri native widget koduyla birebir eşleşmelidir.
class HomeWidgetLockScreenGateway implements LockScreenGateway {
  static const _iosWidgetKind = 'InrEmergencyWidget';
  static const _androidWidgetName = 'InrEmergencyGlanceWidget';

  /// ios/InrEmergencyWidgetExtension'daki entitlements dosyasıyla ve
  /// ios/Runner/Runner.entitlements ile birebir aynı olmalı.
  static const _iosAppGroupId = 'group.com.example.inrTakip';

  bool _appGroupConfigured = false;

  Future<void> _ensureAppGroupConfigured() async {
    if (_appGroupConfigured) return;
    await HomeWidget.setAppGroupId(_iosAppGroupId);
    _appGroupConfigured = true;
  }

  @override
  Future<void> publish(LockScreenPayload payload) async {
    await _ensureAppGroupConfigured();
    await HomeWidget.saveWidgetData<String>('patientName', payload.patientName);
    await HomeWidget.saveWidgetData<String>('headline', payload.headlineTr);
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
}

class LockScreenSyncService {
  final InrRepository _inrRepo;
  final ProfileRepository _profileRepo;
  final LockScreenGateway _gateway;

  StreamSubscription<List<InrEntry>>? _sub;

  LockScreenSyncService(this._inrRepo, this._profileRepo, this._gateway);

  /// İlk senkronizasyonu yapar, sonra her yeni INR kaydında otomatik
  /// tekrarlar. Poll yok — repository'nin zaten reaktif olan
  /// `watchEntries()` akışına abone olunur (bkz. ARCHITECTURE.md).
  Future<void> start() async {
    await _syncNow();
    _sub = _inrRepo.watchEntries().listen((_) => _syncNow());
  }

  Future<void> _syncNow() async {
    final profile = await _profileRepo.getProfile();
    if (profile == null) return;
    final latest = await _inrRepo.getLatest();
    await _gateway.publish(
      LockScreenPayload.build(profile: profile, latestEntry: latest),
    );
  }

  void dispose() => _sub?.cancel();
}

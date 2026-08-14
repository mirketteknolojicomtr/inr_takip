/// `health` paketiyle HealthKit (iOS) / Health Connect ve Google Fit
/// (Android) üzerinden gerçek Kilo ve Nabız verisini okuyan
/// [HealthMetricsGateway] implementasyonu.
///
/// Gerekli platform izinleri (bkz. bu dosyaya eşlik eden Info.plist /
/// AndroidManifest.xml eklemeleri — yeni Xcode target'ı veya Gradle
/// modülü GEREKMEZ, yalnızca izin bildirimi):
///   iOS: `NSHealthShareUsageDescription` (Info.plist).
///   Android: `android.permission.health.READ_WEIGHT` +
///            `android.permission.health.READ_HEART_RATE`
///            (AndroidManifest.xml) ve cihazda Health Connect uygulaması
///            kurulu olmalı.
///
/// `requestAuthorization()` reddedilirse (veya hiç çağrılmazsa)
/// `getWeights`/`getHeartRates` boş liste döner; bu da
/// [EdemaRiskEvaluator]'ın "yetersiz veri" durumunda sessizce hiçbir uyarı
/// üretmemesiyle güvenli şekilde örtüşür — izin yokken yanlış negatif
/// alarm kesmek yerine, hiç değerlendirme yapılmamış olur.
library;

import 'package:health/health.dart';

import 'comorbidity_sync_service.dart';

class HealthPackageMetricsGateway implements HealthMetricsGateway {
  static const _types = [HealthDataType.WEIGHT, HealthDataType.HEART_RATE];

  final Health _health;
  bool _authorized = false;

  HealthPackageMetricsGateway({Health? health}) : _health = health ?? Health();

  /// Uygulama ilk açılışta veya ayarlar ekranında bir kez çağrılmalı.
  /// Sonraki `getWeights`/`getHeartRates` çağrıları bunu tekrar tetiklemez.
  Future<bool> requestAuthorization() async {
    _health.configure();
    _authorized = await _health.requestAuthorization(_types);
    return _authorized;
  }

  @override
  Future<List<WeightSample>> getWeights({required Duration window}) async {
    if (!await _ensureAuthorized()) return const [];

    final points = await _fetch(HealthDataType.WEIGHT, window);
    final samples = <WeightSample>[];
    for (final point in points) {
      final value = point.value;
      if (value is NumericHealthValue) {
        // `health` paketi kiloyu kilogram cinsinden normalize eder.
        samples.add(WeightSample(point.dateFrom, value.numericValue.toDouble()));
      }
    }
    samples.sort((a, b) => a.date.compareTo(b.date));
    return samples;
  }

  @override
  Future<List<HeartRateSample>> getHeartRates({required Duration window}) async {
    if (!await _ensureAuthorized()) return const [];

    final points = await _fetch(HealthDataType.HEART_RATE, window);
    final samples = <HeartRateSample>[];
    for (final point in points) {
      final value = point.value;
      if (value is NumericHealthValue) {
        samples.add(HeartRateSample(point.dateFrom, value.numericValue.toDouble()));
      }
    }
    samples.sort((a, b) => a.date.compareTo(b.date));
    return samples;
  }

  Future<bool> _ensureAuthorized() async {
    if (_authorized) return true;
    return requestAuthorization();
  }

  Future<List<HealthDataPoint>> _fetch(HealthDataType type, Duration window) {
    final now = DateTime.now();
    return _health.getHealthDataFromTypes(
      types: [type],
      startTime: now.subtract(window),
      endTime: now,
    );
  }
}

/// Ödem & Kalp Senkronizasyon Servisi (Comorbidity Sync).
///
/// HealthKit (iOS) / Health Connect ve Google Fit (Android) üzerinden son
/// saatlerin Kilo ve Nabız örneklerini okur; INR ile birlikte
/// değerlendirip akut ödem riski + hedef dışı INR kombinasyonunda yüksek
/// öncelikli bir uyarı tetikler. Uyarı dağıtımı için mevcut
/// [NotificationGateway]/[InrAlert] (bkz. alert_service.dart) yeniden
/// kullanılır — ikinci bir bildirim modeli icat edilmedi.
///
/// BATARYA NOTU: Bu servisin `checkNow()` metodu ne zaman çağrılacağını
/// bilmez (kasıtlı — saf orkestrasyon). Tetikleyici seçimi platforma göre
/// değişir ve pil ömrü açısından kritik:
///
///   iOS: Sabit aralıklı polling YERİNE `HKObserverQuery` +
///        `HKHealthStore.enableBackgroundDelivery` kullanılmalı — yeni bir
///        kilo örneği HealthKit'e yazıldığında iOS uygulamayı olay bazlı
///        arka planda uyandırır. `health` paketi bunu tam kapsamıyorsa,
///        native tarafta (AppDelegate.swift) bir HKObserverQuery kurulup
///        sonucu bir MethodChannel ile bu servise iletilmelidir.
///        `BGAppRefreshTask` yalnızca fallback'tir; Apple zamanlamayı
///        garanti etmez.
///
///   Android: `workmanager` paketiyle periyodik görev (OS tabanı ~15 dk)
///        veya tercihen Health Connect'in `changesToken` API'si — tam
///        taramak yerine yalnızca son senkronizasyondan bu yana değişen
///        kayıtları çeker, çok daha ucuzdur.
///
/// pubspec: health: ^11.1.1
library;

import '../models/inr_entry.dart';
import 'alert_service.dart';

class WeightSample {
  final DateTime date;
  final double kg;
  const WeightSample(this.date, this.kg);
}

class HeartRateSample {
  final DateTime date;
  final double bpm;
  const HeartRateSample(this.date, this.bpm);
}

/// Sağlık verisi kaynağı soyutlaması — testte mock'lanır, üretimde
/// `health` paketi (HealthKit/Health Connect/Google Fit) ile implemente
/// edilir.
abstract interface class HealthMetricsGateway {
  Future<List<WeightSample>> getWeights({required Duration window});

  /// Şu an tetikleme kuralına dahil değil (bkz. [EdemaRiskEvaluator]);
  /// ödem + taşikardi korelasyonu gibi ileride eklenebilecek kurallar için
  /// arayüzde hazır tutuluyor.
  Future<List<HeartRateSample>> getHeartRates({required Duration window});
}

class ComorbidityAlert {
  final double weightDeltaKg;
  final double latestInr;

  const ComorbidityAlert({
    required this.weightDeltaKg,
    required this.latestInr,
  });

  InrAlert toInrAlert() => InrAlert(
        severity: AlertSeverity.critical,
        titleTr: 'Olası akut ödem + hedef dışı INR',
        messageTr:
            'Son 24 saatte ${weightDeltaKg.toStringAsFixed(1)} kg ani kilo '
            'artışı (sıvı birikmesi belirtisi olabilir) kaydedildi ve '
            'güncel INR ${latestInr.toStringAsFixed(1)} hedef aralığın '
            'dışında. Bu bilgiyi doktorunuzla paylaşmanız önerilir.',
        notifyEmergencyContact: true,
      );
}

/// SAF DEĞERLENDİRME: yan etkisiz, I/O yok — birim testi trivial.
/// Kural (kullanıcı tarafından tanımlandığı haliyle): son 24 saatte
/// >1.5 kg kilo artışı VE güncel INR hedef aralığın (varsayılan 2.0-3.0)
/// dışında.
class EdemaRiskEvaluator {
  final double weightDeltaThresholdKg;

  const EdemaRiskEvaluator({this.weightDeltaThresholdKg = 1.5});

  ComorbidityAlert? evaluate({
    required List<WeightSample> weights24h,
    required InrEntry? latestInr,
  }) {
    if (latestInr == null) return null;
    if (latestInr.targetRange.contains(latestInr.inrValue)) return null;
    if (weights24h.length < 2) return null;

    final sorted = [...weights24h]..sort((a, b) => a.date.compareTo(b.date));
    final delta = sorted.last.kg - sorted.first.kg;
    if (delta <= weightDeltaThresholdKg) return null;

    return ComorbidityAlert(
      weightDeltaKg: delta,
      latestInr: latestInr.inrValue,
    );
  }
}

class ComorbiditySyncService {
  final HealthMetricsGateway _health;
  final NotificationGateway _notifications;
  final EdemaRiskEvaluator _evaluator;

  ComorbiditySyncService(
    this._health,
    this._notifications, {
    EdemaRiskEvaluator evaluator = const EdemaRiskEvaluator(),
  }) : _evaluator = evaluator;

  /// WorkManager görevi / HealthKit observer geri çağrımı / manuel
  /// "Şimdi kontrol et" eylemi tarafından tetiklenir. Kendi zamanlamasını
  /// yönetmez (bkz. dosya başı batarya notu).
  Future<ComorbidityAlert?> checkNow(InrEntry? latestInr) async {
    final weights = await _health.getWeights(window: const Duration(hours: 24));
    final alert =
        _evaluator.evaluate(weights24h: weights, latestInr: latestInr);
    if (alert != null) {
      await _notifications.showLocalAlert(alert.toInrAlert());
    }
    return alert;
  }
}

/// iOS'ta `AppDelegate.swift`deki `HKObserverQuery`den gelen "yeni kilo
/// örneği yazıldı" olayını dinleyip [ComorbiditySyncService]'i tetikleyen
/// köprü. Android'de bu channel hiç çağrılmaz (bkz.
/// comorbidity_background_scheduler.dart -- Android tarafı WorkManager
/// periyodik görevi kullanıyor, çünkü Android'de HealthKit'in
/// `enableBackgroundDelivery` karşılığı olan Health Connect "Changes API"
/// bu paket sürümünde henüz kullanılabilir değil).
///
/// Olay bazlı (event-driven): iOS uygulamayı yalnızca gerçekten yeni bir
/// kilo örneği geldiğinde arka planda uyandırır -- WorkManager'ın aksine
/// sabit aralıklı polling yok, bu yüzden Android'e göre daha batarya dostu.
///
/// main.dart bu sınıfı kalıcı [SqfliteInrRepository] ile enjekte eder --
/// arka plan uyanışında da aynı fiziksel sqlite dosyası okunduğu için
/// (bkz. comorbidity_background_scheduler.dart) son INR kaydı doğru gelir.
library;

import 'package:flutter/services.dart';

import '../repositories/repositories.dart';
import 'comorbidity_sync_service.dart';

class HealthBackgroundObserver {
  static const _channel = MethodChannel('inr_takip/health_observer');

  final ComorbiditySyncService _syncService;
  final InrRepository _inrRepo;

  HealthBackgroundObserver(this._syncService, this._inrRepo);

  void start() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNewWeightSample') {
        final latest = await _inrRepo.getLatest();
        await _syncService.checkNow(latest);
      }
    });
  }
}

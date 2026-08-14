/// Android'de [ComorbiditySyncService]'i periyodik olarak (OS tabanı ~15dk,
/// burada 6 saat seçildi) arka planda tetikleyen WorkManager entegrasyonu.
/// iOS'ta WorkManager desteklenmez -- bkz. HealthKit background delivery
/// (services/health_background_observer.dart, HKObserverQuery tabanlı,
/// olay bazlı ve WorkManager'dan daha batarya dostu).
///
/// WorkManager görevleri ayrı bir Dart izolatında/işlem bağlamında çalışır;
/// ana uygulamanın çalışan state'ini GÖREMEZ. Bu yüzden [SqfliteInrRepository]
/// kullanılır (InMemory* değil) -- her izolat aynı fiziksel sqlite dosyasını
/// açtığı için, uygulama kapalıyken bile son INR kaydı doğru okunur.
library;

import 'package:workmanager/workmanager.dart';

import '../repositories/sqflite_repositories.dart';
import 'comorbidity_sync_service.dart';
import 'health_package_metrics_gateway.dart';
import 'local_notification_gateway.dart';

const comorbiditySyncTaskName = 'inr_takip.comorbidity_sync';

/// WorkManager'ın arka plan izolatında çağırdığı giriş noktası.
/// Üst düzey (top-level) fonksiyon olmalı -- kapanan (closure) state
/// taşınamaz, bu yüzden bağımlılıklar burada yeniden kurulur.
@pragma('vm:entry-point')
void comorbidityCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != comorbiditySyncTaskName) return true;

    final notificationGateway = LocalNotificationGateway();
    await notificationGateway.initialize();

    final syncService = ComorbiditySyncService(
      HealthPackageMetricsGateway(),
      notificationGateway,
    );

    final inrRepo = SqfliteInrRepository();
    final latest = await inrRepo.getLatest();

    await syncService.checkNow(latest);
    return true;
  });
}

class ComorbidityBackgroundScheduler {
  Future<void> initializeAndSchedule() async {
    await Workmanager().initialize(comorbidityCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      comorbiditySyncTaskName,
      comorbiditySyncTaskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }

  Future<void> cancel() => Workmanager().cancelByUniqueName(comorbiditySyncTaskName);
}

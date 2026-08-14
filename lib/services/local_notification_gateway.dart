/// `flutter_local_notifications` sarmalayıcısı — ARCHITECTURE.md'de
/// örneklenen `LocalNotificationGateway`'in gerçek implementasyonu.
/// [NotificationGateway] arayüzünü (bkz. alert_service.dart) somutlaştırır.
///
/// Android 13+ için çalışma zamanı bildirim izni gerekir; `initialize()`
/// bunu ister. AndroidManifest.xml'e `POST_NOTIFICATIONS` izni eklenmelidir.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alert_service.dart';

class LocalNotificationGateway implements NotificationGateway {
  static const _channelId = 'inr_alerts';
  static const _channelName = 'INR Uyarıları';
  static const _channelDescription =
      'Kritik/hedef dışı INR değerleri ve ödem riski uyarıları';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Uygulama açılışında bir kez çağrılmalı (ör. main.dart initState).
  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  @override
  Future<void> showLocalAlert(InrAlert alert) async {
    if (!_initialized) await initialize();

    final importance = switch (alert.severity) {
      AlertSeverity.critical => Importance.max,
      AlertSeverity.warning => Importance.high,
      AlertSeverity.info => Importance.defaultImportance,
    };
    final priority = switch (alert.severity) {
      AlertSeverity.critical => Priority.max,
      AlertSeverity.warning => Priority.high,
      AlertSeverity.info => Priority.defaultPriority,
    };

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: importance,
        priority: priority,
        styleInformation: BigTextStyleInformation(alert.messageTr),
      ),
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    // id: aynı anda tek bir kritik uyarı yeterli; her seferinde aynı id ile
    // üst üste yazmak yerine zaman damgasına göre benzersizleştiriyoruz.
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _plugin.show(id, alert.titleTr, alert.messageTr, details);
  }
}

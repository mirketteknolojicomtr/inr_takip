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

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final LocProvider _loc;

  LocalNotificationGateway(this._loc);

  bool _initialized = false;

  /// Android kanal adı sistem ayarlarında görünür; kullanıcının dilinde
  /// olmalı. Kanal bir kez oluşturulur — dil sonradan değişirse ad eski
  /// dilde kalır, bu Android'in bilinen bir kısıtıdır (kanal yeniden
  /// adlandırmak için silinip yeniden kurulması gerekir ve bu, kullanıcının
  /// kanal ayarlarını sıfırlar; ada göre sıfırlamak daha kötü bir takas).
  String _channelName = 'INR';
  String _channelDescription = '';

  /// Uygulama açılışında bir kez çağrılmalı (ör. main.dart initState).
  Future<void> initialize() async {
    if (_initialized) return;

    final loc = await _loc();
    _channelName = loc.l10n.notificationChannelName;
    _channelDescription = loc.l10n.notificationChannelDescription;

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
  Future<void> showLocalAlert({
    required String title,
    required String body,
    required AlertSeverity severity,
  }) async {
    if (!_initialized) await initialize();

    final importance = switch (severity) {
      AlertSeverity.critical => Importance.max,
      AlertSeverity.warning => Importance.high,
      AlertSeverity.info => Importance.defaultImportance,
    };
    final priority = switch (severity) {
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
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    // id: aynı anda tek bir kritik uyarı yeterli; her seferinde aynı id ile
    // üst üste yazmak yerine zaman damgasına göre benzersizleştiriyoruz.
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    await _plugin.show(id, title, body, details);
  }
}

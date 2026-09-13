/// [ReminderScheduler]'ın `flutter_local_notifications` implementasyonu.
///
/// Zaman dilimi: tekrarlayan bildirimler `TZDateTime` ister. Cihazın
/// gerçek saat dilimi `flutter_timezone` ile okunur; okunamazsa
/// Türkiye (Europe/Istanbul) varsayılır — yanlış bir UTC varsayımı ilaç
/// saatini kaydırır, bu da klinik olarak kabul edilemez.
///
/// Android notları:
///  - AndroidManifest.xml'e `SCHEDULE_EXACT_ALARM` (veya
///    `USE_EXACT_ALARM`) ve `RECEIVE_BOOT_COMPLETED` izinleri gerekir.
///  - Tam zamanlı alarm izni verilmemişse `inexactAllowWhileIdle`'a
///    düşülür: bildirim birkaç dakika gecikebilir ama hiç gelmemesinden
///    iyidir.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'alert_service.dart' show LocProvider;
import 'reminder_service.dart';

class LocalReminderScheduler implements ReminderScheduler {
  static const _channelId = 'medication_reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  final LocProvider _loc;

  bool _tzReady = false;
  AndroidScheduleMode _scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;

  /// Kanal adı sistem ayarlarında görünür; kullanıcının dilinde olmalı
  /// (bkz. local_notification_gateway.dart'taki aynı gerekçe).
  String _channelName = 'Reminders';
  String _channelDescription = '';

  LocalReminderScheduler(this._loc, [FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> _ensureTimeZone() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('[HATIRLATICI] Saat dilimi okunamadı, Europe/Istanbul '
          'varsayılıyor: $e');
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    }
    _tzReady = true;
  }

  /// Android 12+ tam alarm iznini ister; yoksa yaklaşık moda düşer.
  Future<void> initialize() async {
    await _ensureTimeZone();

    final loc = await _loc();
    _channelName = loc.l10n.reminderChannelName;
    _channelDescription = loc.l10n.reminderChannelDescription;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final granted = await android.requestExactAlarmsPermission();
    if (granted == false) {
      _scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
    }
  }

  NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  tz.TZDateTime _nextInstanceOf(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (weekday != null) {
      while (scheduled.weekday != weekday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }
    return scheduled;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _ensureTimeZone();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _details,
      androidScheduleMode: _scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _ensureTimeZone();
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute, weekday: weekday),
      _details,
      androidScheduleMode: _scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    await _ensureTimeZone();
    final scheduled = tz.TZDateTime.from(at, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode: _scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  /// Yalnızca [MedicationReminderService] aralığındaki planlı bildirimleri
  /// iptal eder; kritik INR uyarıları etkilenmez.
  @override
  Future<void> cancelAllReminders() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      if (request.id >= MedicationReminderService.idRangeStart &&
          request.id <= MedicationReminderService.idRangeEnd) {
        await _plugin.cancel(request.id);
      }
    }
  }
}

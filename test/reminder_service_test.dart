/// [MedicationReminderService] — sıklığın doğru bildirim tipine çevrilmesi.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/models/medication.dart';
import 'package:inr_takip/services/reminder_service.dart';

import 'l10n_helper.dart';

class _FakeScheduler implements ReminderScheduler {
  final daily = <({int hour, int minute, String body})>[];
  final weekly = <({int weekday, int hour, int minute, String body})>[];
  final once = <({DateTime at, String body})>[];
  var cancelAllCount = 0;
  final ids = <int>[];

  @override
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    ids.add(id);
    daily.add((hour: hour, minute: minute, body: body));
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
    ids.add(id);
    weekly.add((weekday: weekday, hour: hour, minute: minute, body: body));
  }

  @override
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  }) async {
    ids.add(id);
    once.add((at: at, body: body));
  }

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAllReminders() async => cancelAllCount++;
}

void main() {
  final monday = DateTime(2026, 8, 31, 8);

  late _FakeScheduler scheduler;
  late MedicationReminderService service;

  setUp(() {
    scheduler = _FakeScheduler();
    service = MedicationReminderService(scheduler, testLoc);
  });

  test('her gün: alım saati başına bir günlük bildirim', () async {
    await service.syncAll([
      Medication(
        id: 'm',
        name: 'B12',
        startDate: monday,
        times: const [
          DoseTime(hour: 9, minute: 0, amountMg: 1),
          DoseTime(hour: 21, minute: 0, amountMg: 1),
        ],
      ),
    ], now: monday);

    expect(scheduler.cancelAllCount, 1);
    expect(scheduler.daily.length, 2);
    expect(scheduler.weekly, isEmpty);
  });

  test('haftalık şema: dozu olan her gün için haftalık bildirim', () async {
    await service.syncAll([
      Medication(
        id: 'w',
        name: 'Coumadin',
        startDate: monday,
        isAnticoagulant: true,
        unitStrengthMg: 5,
        frequency: DoseFrequency.weeklyPattern,
        weeklyDoseMg: const {1: 5, 3: 2.5, 5: 5},
        times: const [DoseTime(hour: 19, minute: 0, amountMg: 0)],
      ),
    ], now: monday);

    expect(scheduler.weekly.length, 3);
    expect(scheduler.weekly.map((w) => w.weekday), containsAll([1, 3, 5]));
    // Bildirim metni dozu ve tablet adedini yazmalı.
    final wednesday = scheduler.weekly.firstWhere((w) => w.weekday == 3);
    expect(wednesday.body, contains('2,5 mg'));
    expect(wednesday.body, contains('½ tablet'));
  });

  test('gün aşırı: ileriye dönük tek seferlik bildirimler', () async {
    await service.syncAll([
      Medication(
        id: 'e',
        name: 'İlaç',
        startDate: monday,
        frequency: DoseFrequency.everyOtherDay,
        times: const [DoseTime(hour: 19, minute: 0, amountMg: 5)],
      ),
    ], now: monday);

    expect(scheduler.daily, isEmpty);
    expect(scheduler.weekly, isEmpty);
    // 30 günlük pencerede gün aşırı -> 15 alım.
    expect(scheduler.once.length, 15);
    expect(scheduler.once.first.at, DateTime(2026, 8, 31, 19));
    expect(scheduler.once[1].at, DateTime(2026, 9, 2, 19));
  });

  test('hatırlatması kapalı ilaç planlanmaz', () async {
    await service.syncAll([
      Medication(
        id: 'm',
        name: 'B12',
        startDate: monday,
        remindersEnabled: false,
        times: const [DoseTime(hour: 9, minute: 0, amountMg: 1)],
      ),
    ], now: monday);

    expect(scheduler.daily, isEmpty);
  });

  test('bildirim id’leri ayrılmış aralıkta kalır', () async {
    await service.syncAll([
      Medication(
        id: 'm',
        name: 'B12',
        startDate: monday,
        times: const [DoseTime(hour: 9, minute: 0, amountMg: 1)],
      ),
    ], now: monday);

    for (final id in scheduler.ids) {
      expect(id, greaterThanOrEqualTo(MedicationReminderService.idRangeStart));
      expect(id, lessThanOrEqualTo(MedicationReminderService.idRangeEnd));
    }
  });
}

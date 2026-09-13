/// İlaç Saati Hatırlatıcısı — planlama mantığı.
///
/// Artık tek bir "günlük saat" değil, her ilacın kendi sıklığı
/// (her gün / gün aşırı / belirli günler / haftalık şema) ve her alım
/// saatindeki miktarı için ayrı bildirim planlanır. Bildirim metni dozu
/// da yazar: "Warfarin — 5 mg (1 tablet)".
///
/// Platform soyutlaması [ReminderScheduler] üzerindedir; gerçek
/// implementasyon `local_reminder_scheduler.dart`.
library;

import '../l10n/domain_labels.dart';
import '../models/medication.dart';
import 'alert_service.dart' show LocProvider;

/// Platform bildirim soyutlaması — testte mock'lanır.
abstract interface class ReminderScheduler {
  /// Her gün aynı saatte tekrarlayan bildirim.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  /// Haftanın belirli gününde tekrarlayan bildirim (1=Pzt ... 7=Paz).
  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });

  /// Tek seferlik bildirim (gün aşırı şema için ileriye dönük olarak
  /// birkaç tanesi peş peşe planlanır).
  Future<void> scheduleOnce({
    required int id,
    required DateTime at,
    required String title,
    required String body,
  });

  Future<void> cancel(int id);

  /// Bu servise ayrılmış id aralığındaki tüm planlı bildirimleri iptal
  /// eder — INR uyarıları gibi diğer bildirimlere dokunmaz.
  Future<void> cancelAllReminders();
}

class MedicationReminderService {
  /// Bu servise ayrılan bildirim id aralığı.
  static const idRangeStart = 2000;
  static const idRangeEnd = 8999;

  /// Gün aşırı ilaçlar için kaç gün ileriye bildirim planlanacağı.
  /// (Tekrarlayan bir "gün aşırı" kuralı platformda yok; uygulama her
  /// açıldığında bu pencere yenilenir.)
  static const everyOtherDayHorizon = 30;

  final ReminderScheduler _scheduler;
  final LocProvider _loc;

  MedicationReminderService(this._scheduler, this._loc);

  /// Tüm ilaç planını bildirimlere yansıtır. Önce kendi aralığını
  /// temizler, sonra yeniden kurar — böylece silinen/düzenlenen ilaçların
  /// bildirimi ortada kalmaz.
  Future<void> syncAll(List<Medication> medications, {DateTime? now}) async {
    await _scheduler.cancelAllReminders();
    final reference = now ?? DateTime.now();
    final loc = await _loc();

    var id = idRangeStart;
    int nextId() {
      final current = id++;
      return current > idRangeEnd ? idRangeEnd : current;
    }

    for (final med in medications) {
      if (!med.remindersEnabled) continue;

      switch (med.frequency) {
        case DoseFrequency.daily:
          for (final time in med.times) {
            if (time.amountMg <= 0) continue;
            await _scheduler.scheduleDaily(
              id: nextId(),
              hour: time.hour,
              minute: time.minute,
              title: loc.l10n.reminderTitle(med.name),
              body: _body(loc, med, time.amountMg),
            );
          }

        case DoseFrequency.specificDays:
          for (final time in med.times) {
            if (time.amountMg <= 0) continue;
            for (final weekday in med.weekdays) {
              await _scheduler.scheduleWeekly(
                id: nextId(),
                weekday: weekday,
                hour: time.hour,
                minute: time.minute,
                title: loc.l10n.reminderTitle(med.name),
                body: _body(loc, med, time.amountMg),
              );
            }
          }

        case DoseFrequency.weeklyPattern:
          final time = med.times.isEmpty
              ? const DoseTime(hour: 19, minute: 0, amountMg: 0)
              : med.times.first;
          for (final entry in med.weeklyDoseMg.entries) {
            if (entry.value <= 0) continue;
            await _scheduler.scheduleWeekly(
              id: nextId(),
              weekday: entry.key,
              hour: time.hour,
              minute: time.minute,
              title: loc.l10n.reminderTitle(med.name),
              body: _body(loc, med, entry.value),
            );
          }

        case DoseFrequency.everyOtherDay:
          // Platformda "gün aşırı" tekrar kuralı yok: önümüzdeki
          // [everyOtherDayHorizon] gün için tek tek planlanır.
          for (var offset = 0; offset < everyOtherDayHorizon; offset++) {
            final day = DateTime(reference.year, reference.month,
                    reference.day)
                .add(Duration(days: offset));
            for (final slot in med.scheduleFor(day)) {
              if (!slot.at.isAfter(reference)) continue;
              await _scheduler.scheduleOnce(
                id: nextId(),
                at: slot.at,
                title: loc.l10n.reminderTitle(med.name),
                body: _body(loc, med, slot.amountMg),
              );
            }
          }
      }
    }
  }

  /// Bildirim gövdesi seçili dilde kurulur. Metin planlama anında
  /// sabitlenir: kullanıcı dili değiştirince `syncAll` yeniden planlar.
  String _body(Loc loc, Medication med, double mg) {
    final mgLabel = MedicationLabels.mg(loc, mg);
    final tablet = med.tabletLabel(loc, mg);
    final dose =
        tablet == null ? mgLabel : loc.l10n.doseWithTablets(mgLabel, tablet);
    return med.isAnticoagulant
        ? loc.l10n.reminderBodyAnticoagulant(med.name, dose)
        : loc.l10n.reminderBody(med.name, dose);
  }
}

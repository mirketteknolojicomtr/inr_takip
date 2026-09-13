/// İlaç planı iş mantığı — "bugün ne, ne kadar, ne zaman?" sorusunun
/// tek cevap noktası.
///
/// Saf hesaplama (bkz. [buildDay], [adherence]) ile yan etkiler
/// (bildirim planlama) ayrıştırıldı: hesaplama kısmı birim testlenebilir.
library;

import '../models/medication.dart';
import '../repositories/repositories.dart';

/// Bugünün planındaki tek bir alım.
class ScheduledDose {
  final Medication medication;
  final DateTime scheduledAt;
  final double amountMg;

  /// Kullanıcı bu dozu işaretlediyse kaydı; yoksa null.
  final DoseIntake? intake;

  const ScheduledDose({
    required this.medication,
    required this.scheduledAt,
    required this.amountMg,
    this.intake,
  });

  bool get isTaken => intake?.status == IntakeStatus.taken;
  bool get isSkipped => intake?.status == IntakeStatus.skipped;
  bool get isPending => intake == null;

  /// Saati geçtiği hâlde işaretlenmemiş doz — UI'da kırmızı vurgulanır.
  bool isOverdue(DateTime now) =>
      isPending && now.difference(scheduledAt) > const Duration(minutes: 30);

}

/// Bir günün tam ilaç tablosu.
class MedicationDay {
  final DateTime date;
  final List<ScheduledDose> doses;

  const MedicationDay({required this.date, required this.doses});

  double get totalMg => doses.fold(0, (sum, d) => sum + d.amountMg);

  double get takenMg => doses
      .where((d) => d.isTaken)
      .fold<double>(0, (sum, d) => sum + d.amountMg);

  bool get isComplete =>
      doses.isNotEmpty && doses.every((d) => !d.isPending);

  /// Sıradaki alınmamış doz (varsa).
  ScheduledDose? nextPending(DateTime now) {
    for (final d in doses) {
      if (d.isPending && d.scheduledAt.isAfter(now)) return d;
    }
    for (final d in doses) {
      if (d.isPending) return d; // saati geçmiş ama işaretlenmemiş
    }
    return null;
  }
}

/// Belirli bir dönemin uyum (adherence) özeti.
class AdherenceSummary {
  final int scheduled;
  final int taken;
  final int skipped;
  final int missed;

  const AdherenceSummary({
    required this.scheduled,
    required this.taken,
    required this.skipped,
    required this.missed,
  });

  double get percent => scheduled == 0 ? 0 : 100.0 * taken / scheduled;

  bool get isEmpty => scheduled == 0;
}

/// INR kaydı için önerilen doz ve nereden geldiği.
class DoseSuggestion {
  final Medication medication;
  final double mg;

  /// true: bugünün planından; false: en son doz gününden taşındı.
  final bool fromToday;

  const DoseSuggestion({
    required this.medication,
    required this.mg,
    required this.fromToday,
  });

}

class MedicationService {
  final MedicationRepository _medRepo;
  final DoseIntakeRepository _intakeRepo;

  MedicationService(this._medRepo, this._intakeRepo);

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  /// [day] gününün alım tablosu (kayıtlı "aldım/atladım" bilgisiyle).
  Future<MedicationDay> buildDay(DateTime day) async {
    final meds = await _medRepo.getAll();
    final intakes = await _intakeRepo.getIntakes(
      from: _dayStart(day),
      to: _dayEnd(day),
    );

    final doses = <ScheduledDose>[];
    for (final med in meds) {
      for (final slot in med.scheduleFor(day)) {
        DoseIntake? match;
        for (final i in intakes) {
          if (i.medicationId == med.id &&
              i.scheduledAt.isAtSameMomentAs(slot.at)) {
            match = i;
            break;
          }
        }
        doses.add(ScheduledDose(
          medication: med,
          scheduledAt: slot.at,
          amountMg: slot.amountMg,
          intake: match,
        ));
      }
    }

    doses.sort((a, b) {
      final byTime = a.scheduledAt.compareTo(b.scheduledAt);
      if (byTime != 0) return byTime;
      // Aynı saatte antikoagülan önce gösterilsin.
      if (a.medication.isAnticoagulant != b.medication.isAnticoagulant) {
        return a.medication.isAnticoagulant ? -1 : 1;
      }
      return a.medication.name.compareTo(b.medication.name);
    });

    return MedicationDay(date: _dayStart(day), doses: doses);
  }

  /// Son [days] günün uyum özeti. Bugünün henüz gelmemiş dozları
  /// "kaçırıldı" sayılmaz — sadece geçmiş dozlar değerlendirilir.
  Future<AdherenceSummary> adherence({int days = 7, DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final meds = await _medRepo.getAll();
    if (meds.isEmpty) {
      return const AdherenceSummary(
          scheduled: 0, taken: 0, skipped: 0, missed: 0);
    }

    final from = _dayStart(reference).subtract(Duration(days: days - 1));
    final intakes =
        await _intakeRepo.getIntakes(from: from, to: _dayEnd(reference));

    var scheduled = 0, taken = 0, skipped = 0;
    for (var i = 0; i < days; i++) {
      final day = from.add(Duration(days: i));
      for (final med in meds) {
        for (final slot in med.scheduleFor(day)) {
          if (slot.at.isAfter(reference)) continue; // henüz zamanı gelmedi
          scheduled++;
          for (final intake in intakes) {
            if (intake.medicationId == med.id &&
                intake.scheduledAt.isAtSameMomentAs(slot.at)) {
              if (intake.status == IntakeStatus.taken) {
                taken++;
              } else {
                skipped++;
              }
              break;
            }
          }
        }
      }
    }

    return AdherenceSummary(
      scheduled: scheduled,
      taken: taken,
      skipped: skipped,
      missed: scheduled - taken - skipped,
    );
  }

  /// INR kaydı eklenirken doz alanına önerilecek doz.
  ///
  /// Kullanıcı dozu elle yazmak zorunda kalmasın diye üç kademeli arar:
  ///  1. "Kan sulandırıcı" işaretli ilaç,
  ///  2. işaretli ilaç yoksa ve listede tek ilaç varsa o,
  ///  3. bugün doz yoksa (gün aşırı ya da haftalık şemada boş gün)
  ///     son 14 gün içindeki en yakın doz günü.
  ///
  /// Hiçbiri tutmazsa null döner ve alan boş bırakılır — yanlış bir doz
  /// önermektense boş bırakmak doğrudur.
  Future<DoseSuggestion?> suggestedDose(DateTime day) async {
    final meds = await _medRepo.getAll();
    if (meds.isEmpty) return null;

    Medication? target;
    for (final med in meds) {
      if (med.isAnticoagulant) {
        target = med;
        break;
      }
    }
    // Tek ilaç varsa niyet açıktır: işaret unutulmuş olsa bile onu kullan.
    target ??= meds.length == 1 ? meds.first : null;
    if (target == null) return null;

    final todayMg = target.doseForDay(day);
    if (todayMg > 0) {
      return DoseSuggestion(medication: target, mg: todayMg, fromToday: true);
    }

    for (var back = 1; back <= 14; back++) {
      final previous = day.subtract(Duration(days: back));
      final mg = target.doseForDay(previous);
      if (mg > 0) {
        return DoseSuggestion(medication: target, mg: mg, fromToday: false);
      }
    }
    return null;
  }

  Future<Medication?> primaryAnticoagulant() async {
    final meds = await _medRepo.getAll();
    for (final med in meds) {
      if (med.isAnticoagulant) return med;
    }
    return null;
  }
}

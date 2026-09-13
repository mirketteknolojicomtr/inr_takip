/// [MedicationService] — günlük tablo ve uyum hesabı.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/models/medication.dart';
import 'package:inr_takip/repositories/repositories.dart';
import 'package:inr_takip/services/medication_service.dart';

void main() {
  late InMemoryMedicationRepository medRepo;
  late InMemoryDoseIntakeRepository intakeRepo;
  late MedicationService service;

  final monday = DateTime(2026, 8, 31);

  setUp(() {
    medRepo = InMemoryMedicationRepository();
    intakeRepo = InMemoryDoseIntakeRepository();
    service = MedicationService(medRepo, intakeRepo);
  });

  Medication warfarin() => Medication(
        id: 'warfarin',
        name: 'Coumadin',
        startDate: monday,
        isAnticoagulant: true,
        unitStrengthMg: 5,
        frequency: DoseFrequency.weeklyPattern,
        weeklyDoseMg: const {1: 5, 2: 2.5, 3: 5, 4: 2.5, 5: 5, 6: 5, 7: 2.5},
        times: const [DoseTime(hour: 19, minute: 0, amountMg: 0)],
      );

  test('buildDay bugünün alımlarını sıralı üretir', () async {
    await medRepo.upsert(warfarin());
    await medRepo.upsert(Medication(
      id: 'vitamin',
      name: 'B12',
      startDate: monday,
      times: const [DoseTime(hour: 8, minute: 0, amountMg: 1)],
    ));

    final day = await service.buildDay(monday);

    expect(day.doses.length, 2);
    expect(day.doses.first.medication.name, 'B12'); // 08:00 önce
    expect(day.doses.last.medication.name, 'Coumadin');
    expect(day.totalMg, 6); // 1 + 5
  });

  test('alınan doz işaretlenince takenMg artar', () async {
    await medRepo.upsert(warfarin());
    final day = await service.buildDay(monday);
    final dose = day.doses.single;

    await intakeRepo.upsert(DoseIntake(
      id: 'i1',
      medicationId: dose.medication.id,
      scheduledAt: dose.scheduledAt,
      recordedAt: monday,
      amountMg: dose.amountMg,
    ));

    final updated = await service.buildDay(monday);
    expect(updated.doses.single.isTaken, isTrue);
    expect(updated.takenMg, 5);
    expect(updated.isComplete, isTrue);
  });

  test('uyum yalnızca zamanı gelmiş dozları sayar', () async {
    await medRepo.upsert(Medication(
      id: 'm',
      name: 'Coumadin',
      startDate: monday.subtract(const Duration(days: 10)),
      times: const [DoseTime(hour: 19, minute: 0, amountMg: 5)],
    ));

    // Referans: Pazartesi 12:00 -> bugünün 19:00 dozu henüz sayılmaz.
    final summary =
        await service.adherence(days: 3, now: DateTime(2026, 8, 31, 12));

    expect(summary.scheduled, 2); // Cmt ve Paz
    expect(summary.taken, 0);
    expect(summary.missed, 2);
    expect(summary.percent, 0);
  });

  group('doz önerisi', () {
    test('işaretli antikoagülanın o günkü dozunu önerir', () async {
      await medRepo.upsert(warfarin());

      final monday_ = await service.suggestedDose(monday);
      expect(monday_?.mg, 5);
      expect(monday_?.fromToday, isTrue);
      expect(monday_?.medication.name, 'Coumadin');

      final tuesday =
          await service.suggestedDose(monday.add(const Duration(days: 1)));
      expect(tuesday?.mg, 2.5);
    });

    test('işaret unutulmuşsa tek ilacı kullanır', () async {
      // "Kan sulandırıcı" anahtarı kapalı kalmış bir kayıt.
      await medRepo.upsert(Medication(
        id: 'tek',
        name: 'Orfarin',
        startDate: monday,
        times: const [DoseTime(hour: 19, minute: 0, amountMg: 5)],
      ));

      final suggestion = await service.suggestedDose(monday);
      expect(suggestion?.mg, 5);
      expect(suggestion?.medication.name, 'Orfarin');
    });

    test('bugün doz yoksa son doz gününden taşır', () async {
      await medRepo.upsert(Medication(
        id: 'gunasiri',
        name: 'Coumadin',
        startDate: monday,
        isAnticoagulant: true,
        frequency: DoseFrequency.everyOtherDay,
        times: const [DoseTime(hour: 19, minute: 0, amountMg: 5)],
      ));

      // Salı: ara verilen gün -> Pazartesi'nin dozu önerilir.
      final suggestion =
          await service.suggestedDose(monday.add(const Duration(days: 1)));
      expect(suggestion?.mg, 5);
      expect(suggestion?.fromToday, isFalse);
    });

    test('birden çok ilaç var ve hiçbiri işaretli değilse öneri yok',
        () async {
      await medRepo.upsert(Medication(
        id: 'b12',
        name: 'B12',
        startDate: monday,
        times: const [DoseTime(hour: 8, minute: 0, amountMg: 1)],
      ));
      await medRepo.upsert(Medication(
        id: 'd3',
        name: 'D3',
        startDate: monday,
        times: const [DoseTime(hour: 8, minute: 0, amountMg: 1)],
      ));
      // Yanlış doz önermektense boş bırakmak doğrudur.
      expect(await service.suggestedDose(monday), isNull);
    });

    test('hiç ilaç yoksa öneri boş döner', () async {
      expect(await service.suggestedDose(monday), isNull);
    });
  });
}

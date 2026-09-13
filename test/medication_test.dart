/// İlaç doz/sıklık modelinin saf mantık testleri.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/l10n/domain_labels.dart';
import 'package:inr_takip/models/medication.dart';

import 'l10n_helper.dart';

void main() {
  // 2026-08-31 Pazartesi -- haftanın günü hesapları buna dayanıyor.
  final monday = DateTime(2026, 8, 31);
  DateTime dayOf(int offset) => monday.add(Duration(days: offset));

  Medication base({
    DoseFrequency frequency = DoseFrequency.daily,
    Set<int> weekdays = const {1, 2, 3, 4, 5, 6, 7},
    Map<int, double> weekly = const {},
    List<DoseTime> times = const [
      DoseTime(hour: 19, minute: 0, amountMg: 5),
    ],
    double? strength,
    DateTime? start,
  }) =>
      Medication(
        id: 'm1',
        name: 'Coumadin',
        frequency: frequency,
        weekdays: weekdays,
        weeklyDoseMg: weekly,
        times: times,
        unitStrengthMg: strength,
        startDate: start ?? monday,
      );

  group('sıklık', () {
    test('her gün: tüm günlerde alınır', () {
      final med = base();
      for (var i = 0; i < 7; i++) {
        expect(med.isDueOn(dayOf(i)), isTrue);
      }
      expect(med.doseForDay(monday), 5);
    });

    test('gün aşırı: başlangıçtan itibaren bir gün atlar', () {
      final med = base(frequency: DoseFrequency.everyOtherDay);
      expect(med.isDueOn(dayOf(0)), isTrue);
      expect(med.isDueOn(dayOf(1)), isFalse);
      expect(med.isDueOn(dayOf(2)), isTrue);
      expect(med.isDueOn(dayOf(3)), isFalse);
    });

    test('belirli günler: yalnızca seçili günlerde', () {
      final med = base(
        frequency: DoseFrequency.specificDays,
        weekdays: {1, 3, 5},
      );
      expect(med.isDueOn(dayOf(0)), isTrue); // Pzt
      expect(med.isDueOn(dayOf(1)), isFalse); // Sal
      expect(med.isDueOn(dayOf(2)), isTrue); // Çar
      expect(med.doseForDay(dayOf(1)), 0);
    });

    test('haftalık şema: her günün kendi dozu', () {
      final med = base(
        frequency: DoseFrequency.weeklyPattern,
        weekly: {1: 5, 2: 2.5, 3: 5, 4: 2.5, 5: 5, 6: 5, 7: 2.5},
      );
      expect(med.doseForDay(dayOf(0)), 5); // Pazartesi
      expect(med.doseForDay(dayOf(1)), 2.5); // Salı
      expect(med.weeklyTotalMg, 27.5);
    });

    test('haftalık şemada sıfır dozlu gün "alınmaz" sayılır', () {
      final med = base(
        frequency: DoseFrequency.weeklyPattern,
        weekly: {1: 5, 3: 5, 5: 5},
      );
      expect(med.isDueOn(dayOf(1)), isFalse); // Salı: kayıt yok
      expect(med.scheduleFor(dayOf(1)), isEmpty);
    });
  });

  group('doz gösterimi', () {
    // Model yalnızca KESRİ üretir ("1", "½"); "tablet" kelimesi ve mg
    // biçimi çeviri katmanında eklenir (bkz. l10n/domain_labels.dart).
    test('tablet gücü verilince kesir hesaplanır', () {
      final med = base(strength: 5);
      expect(med.tabletFraction(5), '1');
      expect(med.tabletFraction(2.5), '½');
      expect(med.tabletFraction(7.5), '1½');
      expect(med.tabletFraction(10), '2');
    });

    test('tablet gücü yoksa kesir üretilmez', () {
      expect(base().tabletFraction(5), isNull);
    });

    test('yerelleştirilmiş doz özeti mg ve tableti birleştirir', () async {
      final loc = await testLoc();
      expect(base(strength: 5).doseSummary(loc, monday), '5 mg · 1 tablet');
      expect(base().doseSummary(loc, monday), '5 mg');
    });

    test('İngilizce yerel ayarda ondalık ayracı noktadır', () async {
      final loc = await testLoc('en');
      final med = base(
        times: const [DoseTime(hour: 19, minute: 0, amountMg: 2.5)],
      );
      expect(med.doseSummary(loc, monday), contains('2.5 mg'));
    });

    test('mg biçimi gereksiz sıfır göstermez', () async {
      final loc = await testLoc();
      expect(loc.formats.decimal(5), '5');
      expect(loc.formats.decimal(2.5), '2,5');
    });
  });

  group('sonraki doz', () {
    test('aynı gün içindeki sonraki saati bulur', () {
      final med = base(times: const [
        DoseTime(hour: 9, minute: 0, amountMg: 2.5),
        DoseTime(hour: 21, minute: 0, amountMg: 2.5),
      ]);
      final next = med.nextDose(DateTime(2026, 8, 31, 12));
      expect(next?.at, DateTime(2026, 8, 31, 21));
      expect(next?.amountMg, 2.5);
    });

    test('gün bitince ertesi güne geçer', () {
      final med = base();
      final next = med.nextDose(DateTime(2026, 8, 31, 22));
      expect(next?.at, DateTime(2026, 9, 1, 19));
    });

    test('haftalık şemada dozsuz günleri atlar', () {
      final med = base(
        frequency: DoseFrequency.weeklyPattern,
        weekly: {5: 5}, // yalnızca Cuma
      );
      final next = med.nextDose(DateTime(2026, 8, 31, 8)); // Pazartesi
      expect(next?.at, DateTime(2026, 9, 4, 19)); // Cuma
      expect(next?.amountMg, 5);
    });
  });

  test('JSON gidiş-dönüş tüm alanları korur', () {
    final med = base(
      frequency: DoseFrequency.weeklyPattern,
      weekly: {1: 5, 2: 2.5},
      strength: 5,
    );
    final restored = Medication.fromJson(med.toJson());
    expect(restored.frequency, DoseFrequency.weeklyPattern);
    expect(restored.weeklyDoseMg[2], 2.5);
    expect(restored.unitStrengthMg, 5);
    expect(restored.name, 'Coumadin');
  });
}

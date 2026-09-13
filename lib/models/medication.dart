/// İlaç planı modeli: hangi ilaç, ne kadar doz, hangi sıklıkta.
///
/// Warfarin gibi antikoagülanlarda doz haftanın günlerine göre değişebilir
/// (ör. Pzt-Cum 5 mg, Cmt-Paz 2.5 mg). Bu yüzden tek bir "günlük doz"
/// alanı yetmez; [DoseFrequency.weeklyPattern] her gün için ayrı mg
/// tutar. Diğer ilaçlar için [times] listesi (saat + miktar) kullanılır.
///
/// Model saf Dart'tır: UI, bildirim ve depolama katmanları buna bağımlıdır,
/// tersi değil (bkz. ARCHITECTURE.md).
library;

/// Alım sıklığı.
enum DoseFrequency {
  /// Her gün, [Medication.times] içindeki saatlerde.
  daily,

  /// Gün aşırı — [Medication.startDate] referans alınır.
  everyOtherDay,

  /// Yalnızca seçili haftanın günlerinde ([Medication.weekdays]).
  specificDays,

  /// Haftalık şema: her gün için ayrı mg ([Medication.weeklyDoseMg]).
  /// Warfarin doz ayarının standart gösterimi.
  weeklyPattern,
}

// Gün adları ve saat biçimi artık burada değil: `intl`in CLDR verisinden
// yerel ayara göre üretilir (bkz. l10n/formats.dart). 18 dil için sabit
// listeler tutmak hem hataya açık hem gereksizdi.

/// Günün belirli bir saatinde alınacak miktar.
class DoseTime implements Comparable<DoseTime> {
  final int hour; // 0-23
  final int minute; // 0-59

  /// Bu saatte alınacak miktar (mg).
  final double amountMg;

  const DoseTime({
    required this.hour,
    required this.minute,
    required this.amountMg,
  });

  int get minutesOfDay => hour * 60 + minute;

  DateTime onDay(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  @override
  int compareTo(DoseTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  DoseTime copyWith({int? hour, int? minute, double? amountMg}) => DoseTime(
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        amountMg: amountMg ?? this.amountMg,
      );

  Map<String, dynamic> toJson() =>
      {'hour': hour, 'minute': minute, 'amountMg': amountMg};

  factory DoseTime.fromJson(Map<String, dynamic> json) => DoseTime(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        amountMg: (json['amountMg'] as num).toDouble(),
      );
}

class Medication {
  final String id;
  final String name;

  /// Tablet başına mg (ör. 5.0). Verilirse UI "2 mg = ½ tablet" gibi
  /// tablet adedi de gösterir — yaşlı kullanıcı için mg'den anlaşılır.
  final double? unitStrengthMg;

  final DoseFrequency frequency;

  /// [DoseFrequency.specificDays] için seçili günler (1=Pzt ... 7=Paz).
  final Set<int> weekdays;

  /// [DoseFrequency.weeklyPattern] için gün -> toplam mg.
  /// Sıfır/eksik gün = o gün ilaç yok.
  final Map<int, double> weeklyDoseMg;

  /// Alım saatleri. weeklyPattern'de yalnızca ilk saat kullanılır
  /// (miktar weeklyDoseMg'den gelir).
  final List<DoseTime> times;

  /// [DoseFrequency.everyOtherDay] için referans başlangıç günü.
  final DateTime startDate;

  /// Ana antikoagülan mı? (INR'yi doğrudan etkileyen ilaç)
  /// Ana ekranda öne çıkarılır ve INR kaydına doz olarak önerilir.
  final bool isAnticoagulant;

  /// Bu ilaç için bildirim planlansın mı?
  final bool remindersEnabled;

  final String? note;

  const Medication({
    required this.id,
    required this.name,
    required this.startDate,
    this.unitStrengthMg,
    this.frequency = DoseFrequency.daily,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.weeklyDoseMg = const {},
    this.times = const [],
    this.isAnticoagulant = false,
    this.remindersEnabled = true,
    this.note,
  });

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Bu ilaç [day] gününde alınacak mı?
  bool isDueOn(DateTime day) {
    switch (frequency) {
      case DoseFrequency.daily:
        return true;
      case DoseFrequency.specificDays:
        return weekdays.contains(day.weekday);
      case DoseFrequency.everyOtherDay:
        final diff = _dayOnly(day).difference(_dayOnly(startDate)).inDays;
        return diff >= 0 && diff % 2 == 0;
      case DoseFrequency.weeklyPattern:
        return (weeklyDoseMg[day.weekday] ?? 0) > 0;
    }
  }

  /// [day] gününde alınacak toplam mg (alınmayacaksa 0).
  double doseForDay(DateTime day) {
    if (!isDueOn(day)) return 0;
    if (frequency == DoseFrequency.weeklyPattern) {
      return weeklyDoseMg[day.weekday] ?? 0;
    }
    return times.fold<double>(0, (sum, t) => sum + t.amountMg);
  }

  /// [day] gününde planlanan alım anları (saat + miktar).
  List<({DateTime at, double amountMg})> scheduleFor(DateTime day) {
    if (!isDueOn(day)) return const [];

    if (frequency == DoseFrequency.weeklyPattern) {
      final amount = weeklyDoseMg[day.weekday] ?? 0;
      if (amount <= 0) return const [];
      final time = times.isEmpty
          ? const DoseTime(hour: 19, minute: 0, amountMg: 0)
          : times.first;
      return [(at: time.onDay(day), amountMg: amount)];
    }

    final sorted = [...times]..sort();
    return [
      for (final t in sorted)
        if (t.amountMg > 0) (at: t.onDay(day), amountMg: t.amountMg),
    ];
  }

  /// [now]'dan sonraki ilk alım anı. Sonraki 14 gün taranır; hiçbir
  /// alım yoksa null (ör. tüm günleri sıfırlanmış bir şema).
  ({DateTime at, double amountMg})? nextDose(DateTime now) {
    for (var i = 0; i <= 14; i++) {
      final day = _dayOnly(now).add(Duration(days: i));
      for (final slot in scheduleFor(day)) {
        if (slot.at.isAfter(now)) return slot;
      }
    }
    return null;
  }

  /// Haftalık toplam mg — doktor "haftalık dozunuz kaç mg?" diye sorar.
  double get weeklyTotalMg {
    // Referans olarak bir Pazartesi'den başlayan 7 gün.
    final monday = _dayOnly(startDate)
        .subtract(Duration(days: _dayOnly(startDate).weekday - 1));
    var total = 0.0;
    for (var i = 0; i < 7; i++) {
      total += doseForDay(monday.add(Duration(days: i)));
    }
    return total;
  }

  /// mg -> tablet kesri ("1", "½", "1½"). Tablet gücü bilinmiyorsa null.
  ///
  /// Yalnızca SAYI döndürür; "tablet" kelimesi çeviri katmanında eklenir
  /// (bkz. l10n/domain_labels.dart) — kelime sırası her dilde aynı değildir.
  String? tabletFraction(double mg) {
    final strength = unitStrengthMg;
    if (strength == null || strength <= 0 || mg <= 0) return null;
    // Çeyrek tablete yuvarla; kesirli kısmı çeyrek adedi (0-3) üzerinden
    // etiketle -- double anahtarlı map yerine tam sayı aritmetiği.
    final quarters = (mg / strength * 4).round();
    if (quarters <= 0) return null;
    final whole = quarters ~/ 4;
    const fractions = ['', '¼', '½', '¾'];
    final fraction = fractions[quarters % 4];
    if (whole == 0) return fraction;
    return '$whole$fraction';
  }

  Medication copyWith({
    String? name,
    double? unitStrengthMg,
    bool clearUnitStrength = false,
    DoseFrequency? frequency,
    Set<int>? weekdays,
    Map<int, double>? weeklyDoseMg,
    List<DoseTime>? times,
    DateTime? startDate,
    bool? isAnticoagulant,
    bool? remindersEnabled,
    String? note,
  }) =>
      Medication(
        id: id,
        name: name ?? this.name,
        unitStrengthMg:
            clearUnitStrength ? null : (unitStrengthMg ?? this.unitStrengthMg),
        frequency: frequency ?? this.frequency,
        weekdays: weekdays ?? this.weekdays,
        weeklyDoseMg: weeklyDoseMg ?? this.weeklyDoseMg,
        times: times ?? this.times,
        startDate: startDate ?? this.startDate,
        isAnticoagulant: isAnticoagulant ?? this.isAnticoagulant,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unitStrengthMg': unitStrengthMg,
        'frequency': frequency.name,
        'weekdays': weekdays.toList(),
        'weeklyDoseMg':
            weeklyDoseMg.map((k, v) => MapEntry(k.toString(), v)),
        'times': times.map((t) => t.toJson()).toList(),
        'startDate': startDate.toIso8601String(),
        'isAnticoagulant': isAnticoagulant,
        'remindersEnabled': remindersEnabled,
        'note': note,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        name: json['name'] as String,
        unitStrengthMg: (json['unitStrengthMg'] as num?)?.toDouble(),
        frequency: DoseFrequency.values.byName(json['frequency'] as String),
        weekdays: ((json['weekdays'] as List?) ?? const [])
            .map((e) => e as int)
            .toSet(),
        weeklyDoseMg: ((json['weeklyDoseMg'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(int.parse(k as String), (v as num).toDouble()),
        ),
        times: ((json['times'] as List?) ?? const [])
            .map((e) => DoseTime.fromJson(e as Map<String, dynamic>))
            .toList(),
        startDate: DateTime.parse(json['startDate'] as String),
        isAnticoagulant: json['isAnticoagulant'] as bool? ?? false,
        remindersEnabled: json['remindersEnabled'] as bool? ?? true,
        note: json['note'] as String?,
      );
}

/// Planlanan bir dozun akıbeti — "Aldım" / "Atladım" kaydı.
enum IntakeStatus { taken, skipped }

class DoseIntake {
  final String id;
  final String medicationId;

  /// Planlanan alım anı — aynı gün içindeki farklı saatleri ayırt eder.
  final DateTime scheduledAt;

  /// Kullanıcının işaretlediği an.
  final DateTime recordedAt;

  final double amountMg;
  final IntakeStatus status;

  const DoseIntake({
    required this.id,
    required this.medicationId,
    required this.scheduledAt,
    required this.recordedAt,
    required this.amountMg,
    this.status = IntakeStatus.taken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicationId': medicationId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'recordedAt': recordedAt.toIso8601String(),
        'amountMg': amountMg,
        'status': status.name,
      };

  factory DoseIntake.fromJson(Map<String, dynamic> json) => DoseIntake(
        id: json['id'] as String,
        medicationId: json['medicationId'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        recordedAt: DateTime.parse(json['recordedAt'] as String),
        amountMg: (json['amountMg'] as num).toDouble(),
        status: IntakeStatus.values.byName(json['status'] as String),
      );
}

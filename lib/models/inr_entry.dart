/// INR ölçümü + o günkü doz kaydını temsil eden çekirdek model.
/// Immutable tasarlandı; state management (Riverpod/Bloc) ile uyumludur.
library;

/// Hedef INR aralığı (ör. 2.0 - 3.0). Hasta profiline veya
/// tekil kayda bağlanabilir (doktor aralığı değiştirebilir).
class TargetRange {
  final double lower;
  final double upper;

  const TargetRange({required this.lower, required this.upper})
      : assert(lower < upper, 'Alt sınır üst sınırdan küçük olmalı');

  bool contains(double inr) => inr >= lower && inr <= upper;

  Map<String, dynamic> toJson() => {'lower': lower, 'upper': upper};

  factory TargetRange.fromJson(Map<String, dynamic> json) => TargetRange(
        lower: (json['lower'] as num).toDouble(),
        upper: (json['upper'] as num).toDouble(),
      );

  static const standard = TargetRange(lower: 2.0, upper: 3.0);
}

/// INR değerinin klinik bölgesi. UI renklendirmesi ve
/// uyarı mantığı bu enum üzerinden tek noktadan yönetilir.
enum InrZone {
  criticalLow, // < 1.5  -> pıhtı riski (acil)
  belowRange, // hedef altı
  inRange, // güvenli (yeşil)
  aboveRange, // hedef üstü
  criticalHigh, // > 4.5 -> kanama riski (acil)
}

class InrEntry {
  final String id;
  final DateTime date;

  /// Ölçülen INR değeri (ör. 2.5)
  final double inrValue;

  /// O gün alınan toplam warfarin dozu, mg (ör. 5.0)
  final double doseMg;

  /// Kayıt anındaki hedef aralık (tarihsel doğruluk için kayda gömülür)
  final TargetRange targetRange;

  final String? note;

  const InrEntry({
    required this.id,
    required this.date,
    required this.inrValue,
    required this.doseMg,
    this.targetRange = TargetRange.standard,
    this.note,
  });

  /// Klinik bölge hesabı — kritik eşikler hedef aralıktan bağımsızdır.
  InrZone zoneWith({
    double criticalLow = 1.5,
    double criticalHigh = 4.5,
  }) {
    if (inrValue < criticalLow) return InrZone.criticalLow;
    if (inrValue > criticalHigh) return InrZone.criticalHigh;
    if (inrValue < targetRange.lower) return InrZone.belowRange;
    if (inrValue > targetRange.upper) return InrZone.aboveRange;
    return InrZone.inRange;
  }

  bool get isInRange => targetRange.contains(inrValue);

  InrEntry copyWith({
    DateTime? date,
    double? inrValue,
    double? doseMg,
    TargetRange? targetRange,
    String? note,
  }) =>
      InrEntry(
        id: id,
        date: date ?? this.date,
        inrValue: inrValue ?? this.inrValue,
        doseMg: doseMg ?? this.doseMg,
        targetRange: targetRange ?? this.targetRange,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'inrValue': inrValue,
        'doseMg': doseMg,
        'targetRange': targetRange.toJson(),
        'note': note,
      };

  factory InrEntry.fromJson(Map<String, dynamic> json) => InrEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        inrValue: (json['inrValue'] as num).toDouble(),
        doseMg: (json['doseMg'] as num).toDouble(),
        targetRange: TargetRange.fromJson(
            json['targetRange'] as Map<String, dynamic>),
        note: json['note'] as String?,
      );
}

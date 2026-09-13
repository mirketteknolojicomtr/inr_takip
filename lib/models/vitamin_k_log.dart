/// K vitamini alımını loglayan basit diyet modeli.
/// Amaç kalori takibi değil; INR dalgalanmasıyla korelasyon kurabilmek
/// için "göreli K vitamini yükü" üretmektir.
library;

/// Yaygın yüksek K vitaminli gıdalar için hazır katalog.
/// [relativeK] 1-5 arası göreli yük puanıdır (5 = çok yüksek).
enum VitaminKFood {
  spinach(5),
  kale(5),
  chard(5),
  parsley(4),
  broccoli(3),
  lettuce(3),
  greenBeans(2),
  greenTea(2),
  other(1);

  /// 1-5 arası göreli K vitamini yükü (5 = çok yüksek).
  /// Ad çeviri katmanından gelir (bkz. l10n/domain_labels.dart).
  final int relativeK;
  const VitaminKFood(this.relativeK);
}

/// Porsiyon büyüklüğü çarpanı.
enum PortionSize {
  small(0.5),
  medium(1.0),
  large(1.5);

  final double factor;
  const PortionSize(this.factor);
}

class VitaminKLog {
  final String id;
  final DateTime date;
  final VitaminKFood food;
  final PortionSize portion;
  final String? customName; // food == other ise serbest metin

  const VitaminKLog({
    required this.id,
    required this.date,
    required this.food,
    this.portion = PortionSize.medium,
    this.customName,
  });

  /// Bu öğünün göreli K vitamini yükü.
  double get kLoad => food.relativeK * portion.factor;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'food': food.name,
        'portion': portion.name,
        'customName': customName,
      };

  factory VitaminKLog.fromJson(Map<String, dynamic> json) => VitaminKLog(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        food: VitaminKFood.values.byName(json['food'] as String),
        portion: PortionSize.values.byName(json['portion'] as String),
        customName: json['customName'] as String?,
      );
}

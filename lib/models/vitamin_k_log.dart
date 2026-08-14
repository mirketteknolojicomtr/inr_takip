/// K vitamini alımını loglayan basit diyet modeli.
/// Amaç kalori takibi değil; INR dalgalanmasıyla korelasyon kurabilmek
/// için "göreli K vitamini yükü" üretmektir.
library;

/// Yaygın yüksek K vitaminli gıdalar için hazır katalog.
/// [relativeK] 1-5 arası göreli yük puanıdır (5 = çok yüksek).
enum VitaminKFood {
  spinach('Ispanak', 5),
  kale('Kara lahana', 5),
  chard('Pazı', 5),
  parsley('Maydanoz', 4),
  broccoli('Brokoli', 3),
  lettuce('Marul', 3),
  greenBeans('Taze fasulye', 2),
  greenTea('Yeşil çay', 2),
  other('Diğer', 1);

  final String labelTr;
  final int relativeK;
  const VitaminKFood(this.labelTr, this.relativeK);
}

/// Porsiyon büyüklüğü çarpanı.
enum PortionSize {
  small(0.5, 'Az'),
  medium(1.0, 'Orta'),
  large(1.5, 'Bol');

  final double factor;
  final String labelTr;
  const PortionSize(this.factor, this.labelTr);
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

  String get displayName =>
      food == VitaminKFood.other ? (customName ?? 'Diğer') : food.labelTr;

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

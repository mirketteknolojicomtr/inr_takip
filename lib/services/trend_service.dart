/// Trend & Korelasyon Servisi.
/// - Son 30 günün grafik verisini üretir (yeşil/kırmızı bölgeler dahil).
/// - K vitamini yükü ile INR değişimi arasında basit korelasyon kurar.
/// Grafik kütüphanesinden bağımsız saf veri üretir; UI katmanı
/// (fl_chart vb.) bu veriyi çizer.
library;

import '../models/inr_entry.dart';
import '../models/vitamin_k_log.dart';
import '../repositories/repositories.dart';

/// Grafikteki tek nokta.
class TrendPoint {
  final DateTime date;
  final double inr;
  final InrZone zone;
  const TrendPoint(this.date, this.inr, this.zone);
}

/// Grafik arka planındaki renkli bantlar.
class ChartBand {
  final double from;
  final double to;

  /// 'safe' (yeşil), 'caution' (sarı), 'risk' (kırmızı)
  final String kind;
  const ChartBand(this.from, this.to, this.kind);
}

class InrTrendData {
  final List<TrendPoint> points;
  final List<ChartBand> bands;
  final double minY;
  final double maxY;

  /// Aralıkta kalma oranı (TTR benzeri basit metrik, %).
  final double inRangePercent;

  const InrTrendData({
    required this.points,
    required this.bands,
    required this.minY,
    required this.maxY,
    required this.inRangePercent,
  });
}

/// Yüksek K vitamini alımı ile sonraki INR düşüşü arasındaki
/// olası ilişkiyi kullanıcıya gösterecek basit içgörü.
class DietInsight {
  final DateTime inrDate;
  final double inrDelta; // önceki ölçüme göre değişim
  final double kLoadBefore; // ölçümden önceki 72 saatteki toplam K yükü
  /// İlişkilendirilen öğünler. Metin değil kayıt tutulur: gıda adı
  /// çeviriden gelir, kullanıcının yazdığı serbest ad ise olduğu gibi
  /// kalır (bkz. l10n/domain_labels.dart `dietInsightMessage`).
  final List<VitaminKLog> logs;

  const DietInsight({
    required this.inrDate,
    required this.inrDelta,
    required this.kLoadBefore,
    required this.logs,
  });
}

class TrendService {
  final InrRepository _inrRepo;
  final VitaminKRepository _kRepo;

  TrendService(this._inrRepo, this._kRepo);

  /// Son [days] günün grafik verisi (varsayılan 30).
  Future<InrTrendData> buildTrend({
    int days = 30,
    TargetRange range = TargetRange.standard,
    double criticalLow = 1.5,
    double criticalHigh = 4.5,
  }) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days));
    final entries = await _inrRepo.getEntries(from: from, to: now);

    final points = entries
        .map((e) => TrendPoint(
              e.date,
              e.inrValue,
              e.zoneWith(criticalLow: criticalLow, criticalHigh: criticalHigh),
            ))
        .toList();

    final inRange = entries.where((e) => range.contains(e.inrValue)).length;
    final pct = entries.isEmpty ? 0.0 : 100.0 * inRange / entries.length;

    // Grafik bantları: kırmızı (kritik) / sarı (hedef dışı) / yeşil (hedef)
    final bands = <ChartBand>[
      ChartBand(0.0, criticalLow, 'risk'),
      ChartBand(criticalLow, range.lower, 'caution'),
      ChartBand(range.lower, range.upper, 'safe'),
      ChartBand(range.upper, criticalHigh, 'caution'),
      ChartBand(criticalHigh, 6.0, 'risk'),
    ];

    return InrTrendData(
      points: points,
      bands: bands,
      minY: 0.5,
      maxY: 6.0,
      inRangePercent: pct,
    );
  }

  /// Basit diyet-INR ilişkilendirmesi:
  /// INR belirgin düştüyse (delta <= -0.4) ve önceki 72 saatte
  /// K yükü eşik üstündeyse içgörü üretir.
  Future<List<DietInsight>> correlateDietWithInr({
    int days = 30,
    double dropThreshold = -0.4,
    double kLoadThreshold = 4.0,
  }) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days + 3));
    final entries = await _inrRepo.getEntries(from: from, to: now);
    final logs = await _kRepo.getLogs(from: from, to: now);

    final insights = <DietInsight>[];
    for (var i = 1; i < entries.length; i++) {
      final prev = entries[i - 1];
      final curr = entries[i];
      final delta = curr.inrValue - prev.inrValue;
      if (delta > dropThreshold) continue;

      final windowStart = curr.date.subtract(const Duration(hours: 72));
      final windowLogs = logs
          .where((l) =>
              l.date.isAfter(windowStart) && !l.date.isAfter(curr.date))
          .toList();
      final totalK =
          windowLogs.fold<double>(0, (sum, l) => sum + l.kLoad);

      if (totalK >= kLoadThreshold) {
        insights.add(DietInsight(
          inrDate: curr.date,
          inrDelta: delta,
          kLoadBefore: totalK,
          logs: windowLogs,
        ));
      }
    }
    return insights;
  }
}

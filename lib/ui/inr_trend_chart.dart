/// 30 günlük INR trend grafiği (fl_chart).
/// TrendService'ten gelen saf veriyi çizer; iş mantığı içermez.
/// pubspec: fl_chart: ^0.68.0
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/inr_entry.dart';
import '../services/trend_service.dart';

class InrTrendChart extends StatelessWidget {
  final InrTrendData data;
  const InrTrendChart({super.key, required this.data});

  Color _bandColor(String kind) => switch (kind) {
        'safe' => Colors.green.withOpacity(0.15),
        'caution' => Colors.amber.withOpacity(0.12),
        _ => Colors.red.withOpacity(0.12),
      };

  Color _pointColor(InrZone zone) => switch (zone) {
        InrZone.inRange => Colors.green,
        InrZone.belowRange || InrZone.aboveRange => Colors.amber.shade700,
        _ => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    if (data.points.isEmpty) {
      return const Center(child: Text('Son 30 günde kayıt yok'));
    }

    final firstDay = data.points.first.date;
    double x(DateTime d) => d.difference(firstDay).inHours / 24.0;

    final spots =
        data.points.map((p) => FlSpot(x(p.date), p.inr)).toList();

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          minY: data.minY,
          maxY: data.maxY,
          // Yeşil / sarı / kırmızı arka plan bantları
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              for (final b in data.bands)
                HorizontalRangeAnnotation(
                  y1: b.from,
                  y2: b.to,
                  color: _bandColor(b.kind),
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, index) => FlDotCirclePainter(
                  radius: 4,
                  color: _pointColor(data.points[index].zone),
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(
              sideTitles:
                  SideTitles(showTitles: true, reservedSize: 32, interval: 1),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                getTitlesWidget: (value, meta) {
                  final d = firstDay.add(Duration(days: value.round()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${d.day}/${d.month}',
                        style: const TextStyle(fontSize: 11)),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touched) => touched.map((t) {
                final p = data.points[t.spotIndex];
                return LineTooltipItem(
                  '${p.date.day}/${p.date.month}\nINR ${p.inr.toStringAsFixed(1)}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

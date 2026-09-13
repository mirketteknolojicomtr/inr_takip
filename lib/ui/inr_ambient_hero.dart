/// Güncel INR'yi gösteren ambient kart.
///
/// Tasarım notu: Bu bileşen daha önce neredeyse tam ekran, sabit koyu
/// (#031014) bir glassmorphism bloğuydu. Açık temada kartın üst yarısı
/// katı siyah kalıyordu ve liste kaydırıldığında ekranı baştan aşağı
/// kaplayarak "uygulama siyah ekran verdi" izlenimi yaratıyordu. Ayrıca
/// `BackdropFilter` bir `ListView` içinde hem pahalı hem de bazı
/// cihazlarda hatalı (siyah) rasterize oluyor.
///
/// Yeni hâli: yüksekliği sınırlı, zeminini klinik bölge paletinden
/// ([ZoneColors]) alan, açık/koyu temaya uyan bir kart. Yavaş hareket eden
/// blob'lar korundu — ama artık zeminin üstünde düşük opaklıkta bir doku
/// olarak, okunabilirliği bozmadan.
///
/// Renk hâlâ klinik anlam taşır (yeşil = hedefte, amber = hedef dışı,
/// kırmızı = kritik) ve renk tek başına bırakılmaz: değerin altında her
/// zaman metin + ikon vardır.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';
import '../models/inr_entry.dart';
import 'theme.dart';

class AmbientInrHero extends StatefulWidget {
  final double inrValue;
  final InrZone zone;

  /// Ölçüm tarihi (verilirse "3 gün önce" gibi bağlam gösterilir).
  final DateTime? measuredAt;

  const AmbientInrHero({
    super.key,
    required this.inrValue,
    required this.zone,
    this.measuredAt,
  });

  @override
  State<AmbientInrHero> createState() => _AmbientInrHeroState();
}

class _AmbientInrHeroState extends State<AmbientInrHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _relativeLabel(Loc loc, DateTime? date) {
    if (date == null) return null;
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return loc.l10n.measuredToday;
    if (days == 1) return loc.l10n.measuredYesterday;
    return loc.l10n.measuredDaysAgo(days);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final colors = ZoneColors.of(widget.zone, theme.brightness);
    final measured = _relativeLabel(loc, widget.measuredAt);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        // Sabit ve sınırlı yükseklik: kart hiçbir cihazda ekranı kaplamaz.
        height: 208,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient doku — zeminin üstünde düşük opaklıkta.
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _FluidPainter(
                  t: _controller.value,
                  accent: colors.foreground,
                  border: colors.border,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INR',
                    style: TextStyle(
                      color: colors.foreground.withValues(alpha: 0.75),
                      fontSize: 13,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.inrValue.toStringAsFixed(1),
                    style: TextStyle(
                      color: colors.foreground,
                      fontSize: 68,
                      height: 1.05,
                      fontWeight: FontWeight.w300,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Renk tek başına bilgi taşımasın: ikon + metin.
                  Row(
                    children: [
                      Icon(zoneIcon(widget.zone),
                          size: 20, color: colors.foreground),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          inrZoneLabel(loc, widget.zone),
                          style: TextStyle(
                            color: colors.foreground,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (measured != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      measured,
                      style: TextStyle(
                        color: colors.foreground.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yavaşça birbirinin içine geçen bulanık blob'lar. Kart zemininin
/// üzerine düşük opaklıkta çizilir; metnin kontrastını bozmaz.
class _FluidPainter extends CustomPainter {
  final double t;
  final Color accent;
  final Color border;

  _FluidPainter({required this.t, required this.accent, required this.border});

  void _blob(Canvas canvas, Offset center, double radius, Color color,
      double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final angle = t * 2 * math.pi;

    // Sağ tarafta yoğunlaşır: sol tarafta duran metin okunaklı kalsın.
    _blob(
      canvas,
      Offset(
        w * 0.78 + math.sin(angle) * w * 0.10,
        h * 0.35 + math.cos(angle * 1.3) * h * 0.20,
      ),
      w * 0.40,
      accent,
      0.22,
    );
    _blob(
      canvas,
      Offset(
        w * 0.88 + math.cos(angle * 0.8) * w * 0.12,
        h * 0.70 + math.sin(angle * 1.6) * h * 0.18,
      ),
      w * 0.34,
      border,
      0.45,
    );
    _blob(
      canvas,
      Offset(
        w * 0.62 + math.sin(angle * 1.4 + 1) * w * 0.08,
        h * 0.55 + math.cos(angle * 0.6) * h * 0.15,
      ),
      w * 0.24,
      accent,
      0.14,
    );
  }

  @override
  bool shouldRepaint(covariant _FluidPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.accent != accent ||
      oldDelegate.border != border;
}

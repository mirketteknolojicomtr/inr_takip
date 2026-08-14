/// Ana ekranın üst kısmı için ambient, "fluid dynamics" tarzı görsel özet.
/// Klasik grafik/dashboard yerine yavaşça hareket eden yeşil/camgöbeği
/// blob'lar üzerinde yarı saydam bir glassmorphism kart, güncel INR
/// değerini ve klinik bölgeyi (InrZone) gösterir.
///
/// Renk paleti bölgeye göre değişir (yeşil/camgöbeği = hedefte,
/// amber = hedef dışı, kırmızı/magenta = kritik) — yani estetik seçim
/// aynı zamanda klinik anlamı da taşır, saf dekorasyon değildir.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/inr_entry.dart';

class AmbientInrHero extends StatefulWidget {
  final double inrValue;
  final InrZone zone;

  const AmbientInrHero({
    super.key,
    required this.inrValue,
    required this.zone,
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

  ({Color a, Color b, Color c}) _paletteFor(InrZone zone) {
    switch (zone) {
      case InrZone.inRange:
        return (
          a: const Color(0xFF10D9A0),
          b: const Color(0xFF06B6D4),
          c: const Color(0xFF064E3B),
        );
      case InrZone.belowRange:
      case InrZone.aboveRange:
        return (
          a: const Color(0xFFF5A623),
          b: const Color(0xFF0891B2),
          c: const Color(0xFF7C2D12),
        );
      case InrZone.criticalLow:
      case InrZone.criticalHigh:
        return (
          a: const Color(0xFFEF4444),
          b: const Color(0xFFDB2777),
          c: const Color(0xFF450A0A),
        );
    }
  }

  String _statusTr(InrZone zone) => switch (zone) {
        InrZone.inRange => 'Hedef aralıkta — denge iyi',
        InrZone.belowRange => 'Hedefin altında',
        InrZone.aboveRange => 'Hedefin üstünde',
        InrZone.criticalLow => 'Kritik düşük — acil durum',
        InrZone.criticalHigh => 'Kritik yüksek — acil durum',
      };

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.zone);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF031014)),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _FluidPainter(
                  t: _controller.value,
                  colorA: palette.a,
                  colorB: palette.b,
                  colorC: palette.c,
                ),
              ),
            ),
            Center(
              child: _GlassCard(
                value: widget.inrValue,
                statusText: _statusTr(widget.zone),
                accent: palette.a,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yavaşça birbirinin içine geçen, bulanıklaştırılmış radial gradient
/// blob'larla organik bir "fluid" hareket izlenimi üretir.
class _FluidPainter extends CustomPainter {
  final double t;
  final Color colorA;
  final Color colorB;
  final Color colorC;

  _FluidPainter({
    required this.t,
    required this.colorA,
    required this.colorB,
    required this.colorC,
  });

  void _blob(Canvas canvas, Offset center, double radius, Color color,
      double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(opacity), color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 44);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final angle = t * 2 * math.pi;

    _blob(
      canvas,
      Offset(
        w * 0.5 + math.sin(angle) * w * 0.22,
        h * 0.42 + math.cos(angle * 1.3) * h * 0.18,
      ),
      w * 0.55,
      colorA,
      0.55,
    );
    _blob(
      canvas,
      Offset(
        w * 0.5 + math.cos(angle * 0.8) * w * 0.26,
        h * 0.58 + math.sin(angle * 1.6) * h * 0.2,
      ),
      w * 0.5,
      colorB,
      0.5,
    );
    _blob(
      canvas,
      Offset(
        w * 0.5 + math.sin(angle * 1.4 + 1) * w * 0.15,
        h * 0.5 + math.cos(angle * 0.6) * h * 0.15,
      ),
      w * 0.35,
      colorC,
      0.45,
    );
  }

  @override
  bool shouldRepaint(covariant _FluidPainter oldDelegate) => oldDelegate.t != t;
}

class _GlassCard extends StatelessWidget {
  final double value;
  final String statusText;
  final Color accent;

  const _GlassCard({
    required this.value,
    required this.statusText,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'INR',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

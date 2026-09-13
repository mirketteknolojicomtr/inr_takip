/// "Steady-Touch" — el titremesi (tremor) olan kullanıcılar için
/// mıknatıslı hedef yakalama + mikro-titreme (jitter) filtresi.
///
/// İki bağımsız parça:
///
///  1. [TremorFilter]: ham pointer pozisyonlarını tek-kutuplu bir alçak
///     geçiren filtre (EMA, zaman sabiti ~200ms) ile yumuşatır. Widget/UI
///     bağımlılığı yok -> saf mantık, birim testi trivial.
///
///  2. [SteadyTouchArea] + [SteadyTouchTarget]: bir bölgedeki kritik
///     butonları "mıknatıslı hedef" olarak kaydeder. Parmak bir hedefe
///     yeterince yaklaşınca (temel yarıçap + hedefe doğru hareket yönüne
///     göre büyüyen bir "yönsel bonus" ile) hedef görsel olarak vurgulanır
///     (glow + hafif büyüme) ve parmak tam buton üzerinde olmasa bile
///     bırakıldığında o hedef tetiklenir. Ayrıca art arda çok hızlı
///     (< [SteadyTouchArea.tapCooldown]) tetiklenen ikinci bir onayı
///     -tipik bir tremor "sıçraması"- yok sayar.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ham pointer örneklerini yumuşatan tek-kutuplu alçak geçiren filtre.
///
/// [timeConstant]'tan hızlı gerçekleşen salınımlar (tipik parmak titremesi)
/// büyük ölçüde bastırılır; daha yavaş/kasıtlı hareketler ham veriye yakın
/// hızda takip edilir. Manuel bir "son N örnek" tamponu yerine fiziksel
/// olarak anlamlı, tek parametreli bir filtre tercih edildi.
class TremorFilter {
  final Duration timeConstant;

  TremorFilter({this.timeConstant = const Duration(milliseconds: 200)});

  Offset? _filtered;
  DateTime? _lastTime;
  Offset _velocity = Offset.zero;

  Offset get velocity => _velocity;

  /// Yeni ham örneği besler, yumuşatılmış pozisyonu döndürür.
  Offset addSample(Offset raw, DateTime now) {
    final prev = _filtered;
    final prevTime = _lastTime;
    _lastTime = now;

    if (prev == null || prevTime == null) {
      _filtered = raw;
      return raw;
    }

    final dt = now.difference(prevTime).inMicroseconds / 1e6;
    if (dt <= 0) return prev;

    final tau = timeConstant.inMicroseconds / 1e6;
    final alpha = 1 - math.exp(-dt / tau);

    final next = Offset.lerp(prev, raw, alpha)!;
    _velocity = (next - prev) / dt;
    _filtered = next;
    return next;
  }

  void reset() {
    _filtered = null;
    _lastTime = null;
    _velocity = Offset.zero;
  }
}

class _RegisteredTarget {
  final Object id;
  final VoidCallback onConfirm;
  final double baseRadius;
  final GlobalKey key;

  _RegisteredTarget({
    required this.id,
    required this.onConfirm,
    required this.baseRadius,
    required this.key,
  });

  Rect? get globalRect {
    final ctx = key.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

/// [SteadyTouchArea] tarafından oluşturulan, kayıt/yakalama mantığını
/// tutan denetleyici. Widget'lar bunu doğrudan örneklemez;
/// `SteadyTouchArea.of(context)` ile erişir.
class SteadyTouchController {
  SteadyTouchController({required this.directionalBoost});

  final double directionalBoost;
  final _targets = <Object, _RegisteredTarget>{};

  /// Şu an mıknatıslanmış hedefin id'si (yoksa null). Hedef widget'ları
  /// bunu dinleyip görsel geri bildirim (glow/scale) uygular.
  final ValueNotifier<Object?> activeTargetId = ValueNotifier(null);

  void register(_RegisteredTarget target) => _targets[target.id] = target;

  void unregister(Object id) => _targets.remove(id);

  /// Verilen (filtrelenmiş) pozisyona ve hız vektörüne göre en uygun
  /// mıknatıs hedefini bulur. Hedefe doğru hareket ediliyorsa yakalama
  /// yarıçapı o yönde genişler ("parmağı hedefe çekme" hissi).
  _RegisteredTarget? _findMagnetTarget(Offset position, Offset velocity) {
    _RegisteredTarget? best;
    var bestDistance = double.infinity;

    for (final target in _targets.values) {
      final rect = target.globalRect;
      if (rect == null) continue;

      final toTarget = rect.center - position;
      final distance = toTarget.distance;
      if (distance == 0) return target;

      var effectiveRadius = target.baseRadius;
      final speed = velocity.distance;
      if (speed > 1) {
        final velocityDir = velocity / speed;
        final targetDir = toTarget / distance;
        final alignment =
            (velocityDir.dx * targetDir.dx + velocityDir.dy * targetDir.dy)
                .clamp(0.0, 1.0);
        effectiveRadius += target.baseRadius * directionalBoost * alignment;
      }

      if (distance <= effectiveRadius && distance < bestDistance) {
        bestDistance = distance;
        best = target;
      }
    }
    return best;
  }
}

class _SteadyTouchScope extends InheritedWidget {
  final SteadyTouchController controller;

  const _SteadyTouchScope({
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SteadyTouchScope oldWidget) =>
      oldWidget.controller != controller;
}

/// Kritik butonları içeren bölgeyi sarmalar; ham dokunma olaylarını
/// yakalayıp [TremorFilter]'dan geçirir ve en yakın [SteadyTouchTarget]'ı
/// mıknatıslar.
class SteadyTouchArea extends StatefulWidget {
  final Widget child;

  /// Hedeflerin varsayılan mıknatıs yakalama yarıçapı (mantıksal piksel).
  /// Tek tek hedefler [SteadyTouchTarget.magnetRadius] ile bunu geçersiz
  /// kılabilir.
  final double defaultMagnetRadius;

  /// Hedefe doğru hareket ederken yakalama yarıçapının ne kadar
  /// büyüyebileceği (0 = yönsel bonus yok, 1 = yarıçap iki katına çıkar).
  final double directionalBoost;

  /// Art arda tetiklenen onaylar arasındaki minimum süre. Tremor
  /// sıçramasının (aynı dokunuşun iki kez algılanması) önüne geçer.
  final Duration tapCooldown;

  const SteadyTouchArea({
    super.key,
    required this.child,
    this.defaultMagnetRadius = 56,
    this.directionalBoost = 0.5,
    this.tapCooldown = const Duration(milliseconds: 200),
  });

  static SteadyTouchController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_SteadyTouchScope>();
    assert(scope != null, 'SteadyTouchArea üst ağaçta bulunamadı');
    return scope!.controller;
  }

  @override
  State<SteadyTouchArea> createState() => _SteadyTouchAreaState();
}

class _SteadyTouchAreaState extends State<SteadyTouchArea> {
  late final _controller =
      SteadyTouchController(directionalBoost: widget.directionalBoost);
  final _filter = TremorFilter();
  DateTime? _lastConfirmTime;

  void _onPointerDown(PointerDownEvent event) {
    _filter.reset();
    _updateMagnet(event.position);
  }

  void _onPointerMove(PointerMoveEvent event) => _updateMagnet(event.position);

  void _updateMagnet(Offset rawPosition) {
    final filtered = _filter.addSample(rawPosition, DateTime.now());
    final nearest = _controller._findMagnetTarget(filtered, _filter.velocity);
    _controller.activeTargetId.value = nearest?.id;
  }

  void _onPointerUp(PointerUpEvent event) {
    final filtered = _filter.addSample(event.position, DateTime.now());
    final nearest = _controller._findMagnetTarget(filtered, _filter.velocity);
    _controller.activeTargetId.value = null;

    if (nearest == null) return;

    final now = DateTime.now();
    final last = _lastConfirmTime;
    if (last != null && now.difference(last) < widget.tapCooldown) {
      return; // tremor sıçraması: aynı onayın ikinci kez ateşlenmesini yok say
    }
    _lastConfirmTime = now;
    nearest.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return _SteadyTouchScope(
      controller: _controller,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: widget.child,
      ),
    );
  }
}

/// Bir kritik butonu (ör. "ONAYLA") mıknatıslı hedef olarak kaydeder ve
/// mıknatıslandığında görsel geri bildirim (glow + hafif büyüme) uygular.
class SteadyTouchTarget extends StatefulWidget {
  final Object id;
  final Widget child;
  final VoidCallback onConfirm;

  /// Bu hedefe özel yakalama yarıçapı; verilmezse
  /// `SteadyTouchArea.defaultMagnetRadius` kullanılır.
  final double? magnetRadius;

  const SteadyTouchTarget({
    super.key,
    required this.id,
    required this.child,
    required this.onConfirm,
    this.magnetRadius,
  });

  @override
  State<SteadyTouchTarget> createState() => _SteadyTouchTargetState();
}

class _SteadyTouchTargetState extends State<SteadyTouchTarget> {
  final _key = GlobalKey();
  SteadyTouchController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = SteadyTouchArea.of(context);
    _controller = controller;
    _register(controller);
  }

  @override
  void didUpdateWidget(covariant SteadyTouchTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller != null) {
      if (oldWidget.id != widget.id) controller.unregister(oldWidget.id);
      _register(controller);
    }
  }

  void _register(SteadyTouchController controller) {
    controller.register(_RegisteredTarget(
      id: widget.id,
      onConfirm: widget.onConfirm,
      baseRadius: widget.magnetRadius ??
          (context
                  .findAncestorWidgetOfExactType<SteadyTouchArea>()
                  ?.defaultMagnetRadius ??
              56),
      key: _key,
    ));
  }

  @override
  void dispose() {
    _controller?.unregister(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = SteadyTouchArea.of(context);
    return ValueListenableBuilder<Object?>(
      valueListenable: controller.activeTargetId,
      builder: (context, activeId, child) {
        final isMagnetized = activeId == widget.id;
        return AnimatedScale(
          key: _key,
          scale: isMagnetized ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: isMagnetized
                  ? [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.55),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : const [],
            ),
            child: child,
          ),
        );
      },
      // Child'ın kendi dokunma alanı (ör. FilledButton'ın InkWell'i) devre
      // dışı: onay YALNIZCA SteadyTouchArea'nın mıknatıs mantığından gelir.
      // Aksi hâlde tek bir dokunuş hem butonun `onPressed`'ini hem de
      // [onConfirm]'ü çalıştırıyor, `Navigator.pop` gibi işlemler iki kez
      // koşuyordu (diyalog + altındaki ekran kapanıp siyah ekran kalıyordu).
      child: IgnorePointer(child: widget.child),
    );
  }
}

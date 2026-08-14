/// "Safe-Touch" (Güvenli Dokunuş) sarmalayıcı bileşeni.
///
/// Yaşlı/az gören kullanıcılar yanlışlıkla dokunarak istenmeyen bir işlemi
/// tetikleyebilir. Bu bileşen iki aşamalı bir etkileşim sunar:
///
///   1. Tek dokunma  -> hiçbir işlem çalışmaz; sadece TTS ile butonun
///      ne yaptığı sesli olarak okunur ("Veriyi kaydetmek için çift dokunun").
///   2. Çift dokunma -> asıl [onConfirm] çalışır + dokunsal geri bildirim.
///
/// Flutter'ın `GestureDetector`ında `onTap` ve `onDoubleTap` birlikte
/// tanımlandığında çerçeve otomatik olarak ~300ms (`kDoubleTapTimeout`)
/// bekleyip tek/çift dokunmayı ayırt eder; bu yüzden manuel bir zamanlayıcı
/// yazmaya gerek yoktur — istenen davranış GestureDetector'ın yerleşik
/// disambiguation mantığıyla birebir örtüşüyor.
///
/// Not: Bu bileşen kendi TTS anonsunu okur; VoiceOver/TalkBack gibi sistem
/// ekran okuyucusu zaten açıksa iki anons üst üste binebilir. Ekran okuyucu
/// aktifken bu bileşenin `Semantics` düğümünü `excludeSemantics: true` ile
/// sarmalayıp yalnızca kendi TTS akışına güvenmek ya da tam tersini tercih
/// etmek proje kararına bağlıdır.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SafeTouchButton extends StatefulWidget {
  final Widget child;

  /// Tek dokunuşta TTS ile okunacak metin.
  /// Örn: "Veriyi kaydetmek için çift dokunun."
  final String announcement;

  /// Çift dokunuşta çalışacak asıl işlem.
  final VoidCallback onConfirm;

  /// Onay anındaki dokunsal geri bildirim şiddeti.
  final HapticFeedbackStyle hapticStyle;

  /// TTS dili (BCP-47). Varsayılan Türkçe.
  final String ttsLanguage;

  const SafeTouchButton({
    super.key,
    required this.child,
    required this.announcement,
    required this.onConfirm,
    this.hapticStyle = HapticFeedbackStyle.medium,
    this.ttsLanguage = 'tr-TR',
  });

  @override
  State<SafeTouchButton> createState() => _SafeTouchButtonState();
}

enum HapticFeedbackStyle { light, medium, heavy }

class _SafeTouchButtonState extends State<SafeTouchButton> {
  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage(widget.ttsLanguage);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _announce() async {
    // Önceki anons bitmemişse kesip yenisini başlat; kullanıcı art arda
    // dokunduğunda anonsların kuyrukta birikip gecikmesini önler.
    await _tts.stop();
    await _tts.speak(widget.announcement);
  }

  Future<void> _confirm() async {
    await _tts.stop();
    switch (widget.hapticStyle) {
      case HapticFeedbackStyle.light:
        await HapticFeedback.lightImpact();
      case HapticFeedbackStyle.medium:
        await HapticFeedback.mediumImpact();
      case HapticFeedbackStyle.heavy:
        await HapticFeedback.heavyImpact();
    }
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.announcement,
      onTap: _confirm,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _announce,
        onDoubleTap: _confirm,
        child: widget.child,
      ),
    );
  }
}

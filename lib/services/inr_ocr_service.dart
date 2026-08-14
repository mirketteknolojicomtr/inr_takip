/// INR OCR çıkarım mantığı.
///
/// ML Kit (veya başka bir OCR motoru) taranan görüntüden ham metin üretir;
/// bu servis o ham metni işleyip olası INR değerini çıkarır. Kamera/ML Kit
/// bağımlılığı içermez -> birim testi trivial, `ui/inr_scan_screen.dart`
/// bu servisi tüketir.
library;

class InrOcrService {
  /// Kabul edilecek değer aralığı (varsayılan: klinik hedef bandı 2.0-5.0).
  /// Cihaz ekranındaki saat, pil yüzdesi gibi alakasız sayıları elemek
  /// için kullanılır.
  final double minValue;
  final double maxValue;

  const InrOcrService({this.minValue = 2.0, this.maxValue = 5.0});

  static final RegExp _decimalPattern = RegExp(r'\d+[.,]\d+');

  /// Taranan metindeki tüm ondalıklı sayı adaylarından, [minValue]-[maxValue]
  /// aralığına düşen ve aralık ortasına en yakın olanı döndürür.
  /// Eşleşme yoksa `null`.
  double? extractInrValue(String recognizedText) {
    final candidates = _decimalPattern
        .allMatches(recognizedText)
        .map((m) => double.tryParse(m.group(0)!.replaceAll(',', '.')))
        .whereType<double>()
        .where((v) => v >= minValue && v <= maxValue)
        .toList();

    if (candidates.isEmpty) return null;

    final target = (minValue + maxValue) / 2;
    candidates.sort((a, b) => (a - target).abs().compareTo((b - target).abs()));
    return candidates.first;
  }
}

/// Yerel ayara duyarlı biçimlendirme — sayı, tarih, saat, gün adı ve ağırlık.
///
/// [AppLocalizations] cümleleri, bu sınıf ise **değerleri** yerelleştirir.
/// İkisi ayrıdır çünkü değer biçimi çeviriye değil bölgeye bağlıdır:
/// "2,5 mg" Türkiye'de, "2.5 mg" ABD'de doğrudur; gün adlarını ARB'ye
/// elle yazmak yerine `intl`in CLDR verisinden almak 18 dil için hem
/// daha az iş hem daha doğrudur.
///
/// AĞIRLIK BİRİMİ: ödem taraması kiloyu HealthKit/Health Connect'ten
/// **her zaman kilogram** olarak okur; eşik (1,5 kg) de kg cinsindendir.
/// Yalnızca gösterim çevrilir — ABD yerel ayarında pound. Böylece klinik
/// eşik tek bir birimde kalır, dönüşüm hatası riski gösterimle sınırlıdır.
library;

import 'dart:ui' show Locale;

import 'package:intl/intl.dart';

class AppFormats {
  /// BCP-47 etiketi (ör. "tr", "en_US"). `intl` bunu bekler.
  final String locale;

  /// Ağırlık pound olarak gösterilecek mi.
  final bool usesPounds;

  AppFormats(this.locale, {required this.usesPounds});

  static final _cache = <String, AppFormats>{};

  /// Yerel ayardan türetir. Pound yalnızca ABD'de varsayılandır;
  /// diğer tüm hedef pazarlar (Kanada dahil) metrik kullanır.
  ///
  /// `NumberFormat`/`DateFormat` kurulumu ucuz değildir; her `build()`
  /// çağrısında yeniden kurulmasın diye yerel ayar başına önbelleklenir.
  factory AppFormats.of(Locale locale) {
    final tag = locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    return _cache.putIfAbsent(
      tag,
      () => AppFormats(tag, usesPounds: locale.countryCode == 'US'),
    );
  }

  static const _kgToLb = 2.2046226218;

  /// Gereksiz ".0" göstermeden, yerel ondalık ayracıyla: 5 -> "5",
  /// 2.5 -> "2,5" (tr) / "2.5" (en).
  String decimal(double value, {int maxFractionDigits = 2}) {
    final format = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 0
      ..maximumFractionDigits = maxFractionDigits;
    return format.format(value);
  }

  /// INR değeri her zaman tek ondalıkla gösterilir (klinik gelenek).
  String inr(double value) {
    final format = NumberFormat.decimalPattern(locale)
      ..minimumFractionDigits = 1
      ..maximumFractionDigits = 1;
    return format.format(value);
  }

  String percent(double value) {
    final format = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 0;
    return format.format(value);
  }

  /// Ağırlık farkı/değeri: birim etiketiyle birlikte ("1,5 kg" / "3.3 lb").
  String weightKg(double kg) {
    if (usesPounds) return '${decimal(kg * _kgToLb, maxFractionDigits: 1)} lb';
    return '${decimal(kg, maxFractionDigits: 1)} kg';
  }

  String date(DateTime value) => DateFormat.yMd(locale).format(value);

  String dateLong(DateTime value) => DateFormat.yMMMMd(locale).format(value);

  /// Saat — ABD gibi 12 saatlik bölgelerde "7:00 PM", diğerlerinde "19:00".
  String timeOfDay(int hour, int minute) =>
      DateFormat.jm(locale).format(DateTime(2000, 1, 1, hour, minute));

  /// 1 = Pazartesi … 7 = Pazar (DateTime.weekday ile aynı).
  String weekdayShort(int weekday) =>
      DateFormat.E(locale).format(_anyDateFor(weekday));

  String weekdayLong(int weekday) =>
      DateFormat.EEEE(locale).format(_anyDateFor(weekday));

  /// 2024-01-01 bir Pazartesidir; istenen gün ona eklenerek bulunur.
  static DateTime _anyDateFor(int weekday) =>
      DateTime(2024, 1, 1).add(Duration(days: weekday - 1));
}

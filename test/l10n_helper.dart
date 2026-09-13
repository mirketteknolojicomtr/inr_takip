/// Testlerde çeviri paketi kurmak için ortak yardımcı.
///
/// Servisler artık metni verilen dilde üretir; testler bu yüzden bir [Loc]
/// kurmak zorundadır. Varsayılan Türkçedir — mevcut testlerin beklentileri
/// (ve şablon ARB) Türkçe olduğu için.
library;

import 'package:flutter/material.dart';
import 'package:inr_takip/l10n/app_localizations.dart';
import 'package:inr_takip/l10n/domain_labels.dart';
import 'package:inr_takip/l10n/formats.dart';
import 'package:intl/date_symbol_data_local.dart';

/// `DateFormat` yerel verisi bir kez yüklenir (gün adları, tarih biçimi).
bool _dateFormattingReady = false;

Future<Loc> testLoc([String languageTag = 'tr']) async {
  if (!_dateFormattingReady) {
    initializeDateFormatting();
    _dateFormattingReady = true;
  }
  final locale = Locale(languageTag);
  return Loc(await AppLocalizations.delegate.load(locale), AppFormats.of(locale));
}

/// Widget testleri için: çeviri delegelerini kuran bir [MaterialApp].
///
/// Delegeler olmadan `AppLocalizations.of(context)` null döner ve ekran
/// açılır açılmaz assertion ile patlar — testin gerçek uygulamayla aynı
/// koşulda koşması için gereklidir.
MaterialApp localizedApp(Widget home, {String languageTag = 'tr'}) {
  return MaterialApp(
    locale: Locale(languageTag),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
}

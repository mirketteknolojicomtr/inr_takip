/// Cihaz tercihleri — şu an yalnızca dil.
///
/// Neden profilde değil: dil, hastanın klinik verisi değil cihazın
/// tercihidir. Profil buluta senkronlanır; bir cihazda Türkçe seçmek
/// ötekini de değiştirmemelidir.
///
/// Neden sqflite: planlı bildirimler **arka plan izolatında** çalışır ve
/// orada widget ağacı yoktur. Aynı sqlite dosyası her izolattan
/// okunabildiği için seçili dil oradan da alınabilir.
library;

import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:sqflite/sqflite.dart';

import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import '../repositories/sqflite_repositories.dart';

class AppSettings {
  static const _localeKey = 'locale';

  final Future<Database> _dbFuture;

  AppSettings([Future<Database>? database])
      : _dbFuture = database ?? AppDatabase.open();

  /// Kullanıcının seçtiği dil; `null` ise cihaz dili kullanılır.
  Future<Locale?> locale() async {
    final tag = await _read(_localeKey);
    if (tag == null || tag.isEmpty) return null;
    return parseLocale(tag);
  }

  /// `null` vermek "cihaz dilini kullan"a döner.
  Future<void> setLocale(Locale? locale) =>
      _write(_localeKey, locale == null ? '' : locale.toLanguageTag());

  Future<String?> _read(String key) async {
    final db = await _dbFuture;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> _write(String key, String value) async {
    final db = await _dbFuture;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

/// "pt-BR" / "zh-Hans" gibi etiketleri [Locale]'e çevirir.
Locale parseLocale(String tag) {
  final parts = tag.split(RegExp(r'[-_]'));
  if (parts.length == 1) return Locale(parts.first);
  // İkinci parça 4 harfliyse yazı sistemi (Hans/Hant), değilse ülke.
  if (parts[1].length == 4) {
    return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
  }
  return Locale(parts[0], parts[1]);
}

/// Desteklenen diller arasından en uygununu seçer.
///
/// `supportedLocales`'ın ilki (Türkçe) son çaredir: hiçbir eşleşme yoksa
/// uygulama boş metinle değil, anlaşılır bir dille açılır.
Locale resolveSupportedLocale(Locale? preferred) {
  const supported = AppLocalizations.supportedLocales;
  if (preferred == null) return supported.first;

  for (final locale in supported) {
    if (locale.languageCode == preferred.languageCode &&
        locale.scriptCode == preferred.scriptCode &&
        locale.countryCode == preferred.countryCode) {
      return locale;
    }
  }
  for (final locale in supported) {
    if (locale.languageCode == preferred.languageCode &&
        locale.scriptCode == preferred.scriptCode) {
      return locale;
    }
  }
  for (final locale in supported) {
    if (locale.languageCode == preferred.languageCode) return locale;
  }
  return supported.first;
}

/// Widget ağacı olmayan bağlamlar (bildirim, arka plan taraması, PDF)
/// için çeviri paketi üretir: kayıtlı dil, yoksa cihaz dili.
Future<Loc> resolveLoc([AppSettings? settings]) async {
  final stored = await (settings ?? AppSettings()).locale();
  final device =
      WidgetsBinding.instance.platformDispatcher.locales.firstOrNull;
  return Loc.forLocale(resolveSupportedLocale(stored ?? device));
}

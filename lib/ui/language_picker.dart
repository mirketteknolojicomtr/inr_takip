/// Dil seçici — Profil ekranındaki bölüm.
///
/// Dil adları **kendi dillerinde** yazılır ("Deutsch", "日本語"): kullanıcı
/// yanlış bir dile düşmüşse, anlamadığı bir dildeki liste içinde kendi
/// dilini yine de tanıyabilmelidir. Bu, dil seçicilerinde standart ve
/// erişilebilirlik açısından doğru olan davranıştır.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/domain_labels.dart';
import 'theme.dart';

/// Desteklenen dillerin kendi dillerindeki adları.
const kLanguageNames = <String, String>{
  'tr': 'Türkçe',
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'it': 'Italiano',
  'pt': 'Português',
  'nl': 'Nederlands',
  'pl': 'Polski',
  'ru': 'Русский',
  'zh': '中文',
  'ja': '日本語',
  'ko': '한국어',
  'az': 'Azərbaycanca',
  'kk': 'Қазақша',
  'uz': 'Oʻzbekcha',
  'ky': 'Кыргызча',
  'tk': 'Türkmençe',
};

String languageName(Locale locale) =>
    kLanguageNames[locale.languageCode] ?? locale.toLanguageTag();

class LanguagePicker extends StatelessWidget {
  /// Seçili dil; `null` ise cihaz dili kullanılıyor demektir.
  final Locale? selected;
  final ValueChanged<Locale?> onSelected;

  const LanguagePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: loc.l10n.languageSectionTitle,
          subtitle: loc.l10n.languageSectionSubtitle,
        ),
        DropdownButtonFormField<String>(
          // Boş dize = cihaz dili. `null` değeri DropdownButton'da
          // "seçim yok" anlamına geldiği için sentinel olarak kullanılamaz.
          initialValue: selected?.toLanguageTag() ?? '',
          isExpanded: true,
          items: [
            DropdownMenuItem(
              value: '',
              child: Text(loc.l10n.languageSystemDefault),
            ),
            for (final locale in AppLocalizations.supportedLocales)
              DropdownMenuItem(
                value: locale.toLanguageTag(),
                child: Text(languageName(locale)),
              ),
          ],
          onChanged: (tag) => onSelected(
            tag == null || tag.isEmpty ? null : Locale(tag.split('-').first),
          ),
        ),
      ],
    );
  }
}

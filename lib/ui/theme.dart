/// Uygulama tasarım dili.
///
/// Hedef kitle warfarin kullanan, ağırlıklı olarak 60+ yaş hastalar.
/// Bu üç kural her ekranda geçerlidir:
///
///  1. **Okunabilirlik**: gövde metni 16sp'den küçük olmaz; kullanıcının
///     sistem yazı boyutu ayarına saygı duyulur ama aşırı ölçekte layout
///     bozulmasın diye [clampTextScale] ile 1.0–1.6 arasına sıkıştırılır.
///  2. **Dokunma hedefi**: birincil butonlar en az 56dp yüksekliğinde
///     (Material'ın 48dp minimumunun üstünde — el titremesi olan
///     kullanıcılar için bkz. ui/steady_touch.dart).
///  3. **Renk = klinik anlam**: yeşil/amber/kırmızı yalnızca INR
///     bölgesini anlatır, dekorasyon için kullanılmaz. Renk tek başına
///     bilgi taşımaz; her zaman yanında metin/ikon bulunur (renk körlüğü).
library;

import 'package:flutter/material.dart';

import '../models/inr_entry.dart';

/// Marka rengi — uygulama ikonunun koyu yeşiliyle (#064E3B) aynı aileden.
const kBrandSeed = Color(0xFF0E9F6E);

/// INR bölgesinin semantik rengi (arka plan parlaklığına duyarlı).
class ZoneColors {
  final Color foreground;
  final Color background;
  final Color border;

  const ZoneColors({
    required this.foreground,
    required this.background,
    required this.border,
  });

  static ZoneColors of(InrZone zone, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (zone) {
      case InrZone.inRange:
        return ZoneColors(
          foreground: dark ? const Color(0xFF34D399) : const Color(0xFF047857),
          background: dark ? const Color(0xFF06281F) : const Color(0xFFE6F6EF),
          border: dark ? const Color(0xFF0F6B4F) : const Color(0xFFA7E3CB),
        );
      case InrZone.belowRange:
      case InrZone.aboveRange:
        return ZoneColors(
          foreground: dark ? const Color(0xFFFBBF24) : const Color(0xFF92610A),
          background: dark ? const Color(0xFF2B1F03) : const Color(0xFFFDF3DA),
          border: dark ? const Color(0xFF7A5A0B) : const Color(0xFFF0D69A),
        );
      case InrZone.criticalLow:
      case InrZone.criticalHigh:
        return ZoneColors(
          foreground: dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
          background: dark ? const Color(0xFF2E0B0B) : const Color(0xFFFDECEC),
          border: dark ? const Color(0xFF7F1D1D) : const Color(0xFFF3B4B4),
        );
    }
  }
}

/// Bölgenin kısa Türkçe etiketi — renkle birlikte HER ZAMAN gösterilir.
IconData zoneIcon(InrZone zone) => switch (zone) {
      InrZone.inRange => Icons.check_circle_outline,
      InrZone.belowRange => Icons.trending_down,
      InrZone.aboveRange => Icons.trending_up,
      InrZone.criticalLow || InrZone.criticalHigh => Icons.warning_amber_rounded,
    };

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBrandSeed,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF0B1210)
          : const Color(0xFFF6F8F7),
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 16),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        subtitleTextStyle: TextStyle(fontSize: 15),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(fontSize: 16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
      ),
    );
  }

  /// Gövde metinleri Material varsayılanından bir tık büyük.
  static TextTheme _textTheme(TextTheme base) => base.copyWith(
        headlineSmall:
            base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: base.titleMedium
            ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        titleSmall: base.titleSmall
            ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(fontSize: 17, height: 1.4),
        bodyMedium: base.bodyMedium?.copyWith(fontSize: 16, height: 1.4),
        bodySmall: base.bodySmall?.copyWith(fontSize: 14, height: 1.35),
        labelLarge: base.labelLarge?.copyWith(fontSize: 16),
        labelMedium: base.labelMedium?.copyWith(fontSize: 14),
      );
}

/// Sistem yazı boyutunu makul bir aralığa sıkıştırır: yaşlı kullanıcının
/// büyütmesine izin verir, ama 1.6x üstünde kartlar taşmasın.
Widget clampTextScale(BuildContext context, Widget child) {
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(
      textScaler: media.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.6),
    ),
    child: child,
  );
}

/// Ekran bölümlerinin ortak başlığı — isteğe bağlı bir aksiyon ile.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Veri yokken gösterilen açıklayıcı boş durum. "Grafik yok" demek yerine
/// kullanıcıya ne yapacağını söyler.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        // Kart yalnızca içeriği kadar yer kaplasın; aksi hâlde boş
        // sekmelerde ekranı baştan aşağı dolduran gri bir blok oluyor.
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

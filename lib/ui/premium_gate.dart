/// Premium kilitleme bileşenleri.
///
/// [PremiumScope] abonelik durumunu ağaca yayar; abonelik değiştiğinde
/// (satın alma, iptal, iade, yenileme) kilitli ekranlar kendiliğinden
/// güncellenir.
///
/// Kilit UI'ı iki ilkeye uyar:
///  - Kullanıcı **ne kaybettiğini görür** ama tıklayınca ne alacağını da
///    görür (kör duvar değil, açıklamalı kart).
///  - Güvenlik özellikleri asla buradan geçmez
///    (bkz. entitlement_service.dart `kAlwaysFreeFeatures`).
library;

import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';
import '../services/entitlement_service.dart';
import 'paywall_screen.dart';

class PremiumScope extends InheritedNotifier<EntitlementService> {
  const PremiumScope({
    super.key,
    required EntitlementService service,
    required super.child,
  }) : super(notifier: service);

  static EntitlementService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PremiumScope>();
    assert(scope?.notifier != null, 'PremiumScope üst ağaçta bulunamadı');
    return scope!.notifier!;
  }

  /// Dinlemeden okumak için (callback'ler içinde).
  static EntitlementService read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<PremiumScope>();
    assert(scope?.notifier != null, 'PremiumScope üst ağaçta bulunamadı');
    return scope!.notifier!;
  }
}

/// Premium olmayan kullanıcı bu özelliği kullanmaya çalıştığında paywall'ı
/// açar. Premium ise `true` döner ve çağıran işine devam eder.
///
/// Kullanım:
/// ```dart
/// if (!await ensurePremium(context, PremiumFeature.pdfReport)) return;
/// ```
Future<bool> ensurePremium(
  BuildContext context,
  PremiumFeature feature,
) async {
  final service = PremiumScope.read(context);
  if (service.has(feature)) return true;

  final purchased = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PaywallScreen(service: service, highlight: feature),
    ),
  );
  return purchased ?? service.has(feature);
}

/// Küçük "Premium" rozeti — kilitli aksiyonların yanında.
class PremiumBadge extends StatelessWidget {
  final bool compact;
  const PremiumBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium,
              size: compact ? 13 : 16, color: scheme.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            'Premium',
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w700,
              color: scheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kilitli bir bölümün yerine geçen kart: neyin kilitli olduğunu ve
/// açınca ne kazanılacağını anlatır.
class PremiumLockCard extends StatelessWidget {
  final PremiumFeature feature;
  final IconData icon;
  final String title;
  final String description;

  const PremiumLockCard({
    super.key,
    required this.feature,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ensurePremium(context, feature),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall),
                  ),
                  const PremiumBadge(compact: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.lock_open,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    context.loc.l10n.unlockWithPremium,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bir liste öğesini kilitleyen ince sarmalayıcı: içerik görünür ama
/// soluk, dokununca paywall açılır.
class PremiumLockedTile extends StatelessWidget {
  final PremiumFeature feature;
  final Widget child;

  const PremiumLockedTile({
    super.key,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final service = PremiumScope.of(context);
    if (service.has(feature)) return child;

    return Stack(
      children: [
        Opacity(opacity: 0.45, child: IgnorePointer(child: child)),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => ensurePremium(context, feature),
              child: const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: PremiumBadge(compact: true),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Abonelik (paywall) ekranı.
///
/// Mağaza kuralları gereği bu ekranda bulunması ZORUNLU olanlar:
///  - Abonelik süresi ve fiyatı (fiyat metni **mağazadan** gelir,
///    uygulamada sabit yazılmaz),
///  - Otomatik yenileme açıklaması ve iptal yolu,
///  - "Satın alımları geri yükle",
///  - Kullanım Koşulları (EULA) ve Gizlilik Politikası bağlantıları.
///
/// Tıbbi uygulama olduğu için ayrıca "ücretsiz kalanlar" listesi de
/// gösterilir: kullanıcı, güvenlik uyarılarının paraya bağlı olmadığını
/// satın almadan önce görmelidir.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/inr_entry.dart';
import '../l10n/domain_labels.dart';
import '../services/entitlement_service.dart';
import 'theme.dart';

/// Mağaza sayfalarınızla değiştirin.
const kTermsUrl = 'https://inrtakip.app/kullanim-kosullari';
const kPrivacyUrl = 'https://inrtakip.app/gizlilik';

class PaywallScreen extends StatefulWidget {
  final EntitlementService service;

  /// Kullanıcının hangi kilitli özelliğe dokunduğu — başlıkta vurgulanır.
  final PremiumFeature? highlight;

  const PaywallScreen({super.key, required this.service, this.highlight});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<SubscriptionOffer>? _offers;
  SubscriptionOffer? _selected;
  Object? _loadError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() {
      _offers = null;
      _loadError = null;
    });
    try {
      final offers = await widget.service.offers();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        // Varsayılan seçim: rozetli (yıllık) plan, yoksa ilk plan.
        _selected = offers.isEmpty
            ? null
            : offers.firstWhere(
                (o) => o.savingPercent != null,
                orElse: () => offers.first,
              );
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  /// Paywall'ı kapatır.
  ///
  /// `maybePop`, altta başka bir route yoksa hiçbir şey yapmaz. `pop` ise
  /// Navigator'ı boşaltıp kullanıcıyı siyah ekranda bırakırdı — paywall
  /// normalde bir ekranın üstüne açılsa da (Profil kartı, kilitli özellik)
  /// tek route olarak açıldığı durumlar bu ekranın kontrolünde değil.
  void _close([bool purchased = false]) {
    if (!mounted) return;
    Navigator.of(context).maybePop(purchased);
  }

  Future<void> _purchase() async {
    final offer = _selected;
    if (offer == null || _busy) return;

    setState(() => _busy = true);
    final result = await widget.service.purchase(offer);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result.outcome) {
      case PurchaseOutcome.success:
        _close(true);
      case PurchaseOutcome.cancelled:
        break; // sessizce kapan — kullanıcı vazgeçti
      case PurchaseOutcome.pending:
      case PurchaseOutcome.failed:
        final message = result.message;
        _snack(message == null
            ? context.loc.l10n.purchaseNotCompleted
            : purchaseMessageText(context.loc, message));
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await widget.service.restore();
    if (!mounted) return;
    setState(() => _busy = false);

    final message = result.message;
    _snack(message == null
        ? context.loc.l10n.restoreCompleted
        : purchaseMessageText(context.loc, message));
    if (result.entitlement.isPremium) {
      _close(true);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final offers = _offers;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Kapat',
          onPressed: () => _close(false),
        ),
        title: const Text('INR Takip Premium'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (widget.highlight != null)
              _HighlightBanner(feature: widget.highlight!),
            Text(
              loc.l10n.paywallHeadline,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              loc.l10n.paywallSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            const _FeatureList(),
            const SizedBox(height: 24),

            const _AlwaysFreeCard(),
            const SizedBox(height: 24),

            if (offers == null && _loadError == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_loadError != null || (offers?.isEmpty ?? true))
              _StoreUnavailable(onRetry: _loadOffers)
            else ...[
              for (final offer in offers!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OfferTile(
                    offer: offer,
                    selected: offer.id == _selected?.id,
                    onTap: () => setState(() => _selected = offer),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _purchase,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_selected?.trialDays != null
                        ? loc.l10n.paywallTrialCta(_selected!.trialDays!)
                        : loc.l10n.paywallCta),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _restore,
                child: Text(loc.l10n.paywallRestore),
              ),
            ],

            const SizedBox(height: 16),
            _LegalText(
              selected: _selected,
              onTerms: () => _openUrl(kTermsUrl),
              onPrivacy: () => _openUrl(kPrivacyUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightBanner extends StatelessWidget {
  final PremiumFeature feature;
  const _HighlightBanner({required this.feature});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_open, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.loc.l10n
                  .paywallFeatureIsPremium(premiumFeatureLabel(
                context.loc,
                feature,
              )),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  const _FeatureList();

  /// Liste, premium özellik türlerine bağlıdır: başlık zaten çeviri
  /// katmanında tanımlı (`premiumFeatureLabel`), burada yalnızca ikon ve
  /// açıklama eşlenir. Böylece bir özelliğin adı tek yerde değişir.
  static const _items = <({IconData icon, PremiumFeature feature})>[
    (icon: Icons.picture_as_pdf_outlined, feature: PremiumFeature.pdfReport),
    (icon: Icons.timeline, feature: PremiumFeature.unlimitedHistory),
    (icon: Icons.cloud_done_outlined, feature: PremiumFeature.cloudSync),
    (icon: Icons.center_focus_strong, feature: PremiumFeature.ocrScan),
    (icon: Icons.eco_outlined, feature: PremiumFeature.dietInsights),
    (
      icon: Icons.medication_outlined,
      feature: PremiumFeature.unlimitedMedications
    ),
    (icon: Icons.widgets_outlined, feature: PremiumFeature.lockScreenWidget),
  ];

  static String _subtitle(Loc loc, PremiumFeature feature) => switch (feature) {
        PremiumFeature.pdfReport => loc.l10n.paywallPdfSubtitle,
        PremiumFeature.unlimitedHistory => loc.l10n.paywallHistorySubtitle,
        PremiumFeature.cloudSync => loc.l10n.paywallCloudSubtitle,
        PremiumFeature.ocrScan => loc.l10n.paywallOcrSubtitle,
        PremiumFeature.dietInsights => loc.l10n.paywallDietSubtitle,
        PremiumFeature.unlimitedMedications => loc.l10n.paywallMedsSubtitle,
        _ => loc.l10n.paywallWidgetSubtitle,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    return Column(
      children: [
        for (final item in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        premiumFeatureLabel(loc, item.feature),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _subtitle(loc, item.feature),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Güven kartı: ücretsiz kalanların listesi doğrudan
/// [kAlwaysFreeFeatures]'tan okunur — pazarlama metni ile kod arasında
/// tutarsızlık oluşamaz.
class _AlwaysFreeCard extends StatelessWidget {
  const _AlwaysFreeCard();

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    // "hedefte" yeşili -- güven mesajı klinik palette ile aynı dili konuşur.
    final zone = ZoneColors.of(InrZone.inRange, theme.brightness);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: zone.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: zone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined,
                  color: zone.foreground, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  loc.l10n.paywallAlwaysFreeTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: zone.foreground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final feature in kAlwaysFreeFeatures)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 18, color: zone.foreground),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alwaysFreeFeatureLabel(loc, feature),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: zone.foreground),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final SubscriptionOffer offer;
  final bool selected;
  final VoidCallback onTap;

  const _OfferTile({
    required this.offer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? scheme.primary : scheme.outline,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        subscriptionPlanLabel(loc, offer.period),
                        style: theme.textTheme.titleSmall,
                      ),
                      if (offer.savingPercent != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            loc.l10n.savingBadge(offer.savingPercent!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (offer.trialDays != null)
                        loc.l10n.paywallTrialBadge(offer.trialDays!),
                      if (offer.perMonthString != null && !offer.isLifetime)
                        loc.l10n.paywallPerMonth(offer.perMonthString!),
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  offer.priceString,
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  '/ ${subscriptionPeriodLabel(loc, offer.period)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreUnavailable extends StatelessWidget {
  final VoidCallback onRetry;
  const _StoreUnavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return EmptyState(
      icon: Icons.storefront_outlined,
      title: loc.l10n.paywallPlansErrorTitle,
      message: loc.l10n.paywallPlansErrorMessage,
      actionLabel: loc.l10n.retry,
      onAction: onRetry,
    );
  }
}

class _LegalText extends StatelessWidget {
  final SubscriptionOffer? selected;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  const _LegalText({
    required this.selected,
    required this.onTerms,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final isLifetime = selected?.isLifetime ?? false;

    return Column(
      children: [
        Text(
          isLifetime
              ? loc.l10n.paywallLifetimeTerms
              : loc.l10n.paywallSubscriptionTerms,
          textAlign: TextAlign.center,
          style: style,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onTerms,
              child: Text(loc.l10n.paywallTerms),
            ),
            Text('•', style: style),
            TextButton(
              onPressed: onPrivacy,
              child: Text(loc.l10n.paywallPrivacy),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          loc.l10n.paywallMedicalDisclaimer,
          textAlign: TextAlign.center,
          style: style,
        ),
      ],
    );
  }
}

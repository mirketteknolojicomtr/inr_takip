/// "Profil" sekmesi: hasta bilgileri, hedef aralık, kritik eşikler,
/// acil durum kişisi, yakınla paylaşım ve abonelik durumu.
///
/// İlaç dozu/sıklığı artık burada değil — kendi ekranında
/// (bkz. medications_screen.dart). Profil "kim ve hangi sınırlar",
/// ilaç ekranı "ne, ne kadar, ne zaman" sorusuna cevap verir.
library;

import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';
import '../main.dart' show AppLocaleScope;
import '../models/inr_entry.dart';
import '../models/patient_profile.dart';
import '../services/entitlement_service.dart';
import 'language_picker.dart';
import 'paywall_screen.dart';
import 'premium_gate.dart';
import 'theme.dart';

class ProfileScreen extends StatefulWidget {
  final PatientProfile initialProfile;
  final Future<void> Function(PatientProfile profile) onSave;
  final VoidCallback onSignOut;

  /// Güncel durum özetini acil durum kişisine gönderir (premium).
  /// Özeti main.dart kurar; ekran yalnızca tetikler.
  final Future<void> Function() onShareWithCaregiver;

  const ProfileScreen({
    super.key,
    required this.initialProfile,
    required this.onSave,
    required this.onSignOut,
    required this.onShareWithCaregiver,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _nameCtrl = TextEditingController(text: widget.initialProfile.name);
  late final _targetLowerCtrl = TextEditingController(
      text: widget.initialProfile.targetRange.lower.toStringAsFixed(1));
  late final _targetUpperCtrl = TextEditingController(
      text: widget.initialProfile.targetRange.upper.toStringAsFixed(1));
  late final _criticalLowCtrl = TextEditingController(
      text: widget.initialProfile.criticalLow.toStringAsFixed(1));
  late final _criticalHighCtrl = TextEditingController(
      text: widget.initialProfile.criticalHigh.toStringAsFixed(1));
  late final _contactNameCtrl = TextEditingController(
      text: widget.initialProfile.emergencyContact?.name ?? '');
  late final _contactPhoneCtrl = TextEditingController(
      text: widget.initialProfile.emergencyContact?.phone ?? '');
  late bool _notifyBySms =
      widget.initialProfile.emergencyContact?.notifyBySms ?? true;

  bool _saving = false;
  bool _dirty = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetLowerCtrl.dispose();
    _targetUpperCtrl.dispose();
    _criticalLowCtrl.dispose();
    _criticalHighCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lower = _parse(_targetLowerCtrl.text)!;
    final upper = _parse(_targetUpperCtrl.text)!;
    final criticalLow = _parse(_criticalLowCtrl.text)!;
    final criticalHigh = _parse(_criticalHighCtrl.text)!;

    if (lower >= upper) {
      _snack(context.loc.l10n.profileRangeOrderError);
      return;
    }
    // Kritik eşikler hedef aralığı kapsamalı; aksi hâlde uyarı mantığı
    // anlamsızlaşır (hedefte olan bir değer "kritik" sayılabilir).
    if (criticalLow >= lower || criticalHigh <= upper) {
      _snack(context.loc.l10n.profileThresholdError(
        context.loc.formats.inr(lower),
        context.loc.formats.inr(upper),
      ));
      return;
    }

    final contactName = _contactNameCtrl.text.trim();
    final contactPhone = _contactPhoneCtrl.text.trim();

    final profile = PatientProfile(
      name: _nameCtrl.text.trim(),
      targetRange: TargetRange(lower: lower, upper: upper),
      emergencyContact: contactName.isEmpty && contactPhone.isEmpty
          ? null
          : EmergencyContact(
              name: contactName,
              phone: contactPhone,
              notifyBySms: _notifyBySms,
            ),
      schedule: widget.initialProfile.schedule,
      criticalLow: criticalLow,
      criticalHigh: criticalHigh,
    );

    setState(() => _saving = true);
    try {
      await widget.onSave(profile);
      if (mounted) {
        setState(() => _dirty = false);
        _snack('Profil kaydedildi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Form(
      key: _formKey,
      onChanged: () {
        if (!_dirty) setState(() => _dirty = true);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const _SubscriptionCard(),
          const SizedBox(height: 24),

          // Dil, klinik veriden önce gelir: yanlış dile düşen kullanıcı
          // formun geri kalanını okuyamaz.
          LanguagePicker(
            selected: AppLocaleScope.of(context).value,
            onSelected: AppLocaleScope.of(context).select,
          ),
          const SizedBox(height: 24),

          SectionHeader(title: loc.l10n.profilePatientSection),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: loc.l10n.profileNameLabel),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? loc.l10n.profileInvalidNumber
                : null,
          ),

          const SizedBox(height: 24),
          SectionHeader(
            title: loc.l10n.profileTargetTitle,
            subtitle: loc.l10n.profileTargetSubtitle,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _targetLowerCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: loc.l10n.profileLowerBound),
                  validator: (v) => _validateNumber(loc, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _targetUpperCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: loc.l10n.profileUpperBound),
                  validator: (v) => _validateNumber(loc, v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          SectionHeader(
            title: loc.l10n.profileCriticalTitle,
            subtitle: loc.l10n.profileCriticalSubtitle,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _criticalLowCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: loc.l10n.profileCriticalLow,
                    helperText: loc.l10n.profileClotRisk,
                  ),
                  validator: (v) => _validateNumber(loc, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _criticalHighCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: loc.l10n.profileCriticalHigh,
                    helperText: loc.l10n.profileBleedRisk,
                  ),
                  validator: (v) => _validateNumber(loc, v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          SectionHeader(
            title: loc.l10n.profileContactTitle,
            subtitle: loc.l10n.profileContactSubtitle,
          ),
          TextFormField(
            controller: _contactNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Ad Soyad'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: loc.l10n.profileContactPhone,
              hintText: '+90 5XX XXX XX XX',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _notifyBySms,
            onChanged: (v) => setState(() {
              _notifyBySms = v;
              _dirty = true;
            }),
            title: Text(loc.l10n.profileSmsToggle),
          ),

          const SizedBox(height: 8),
          // Kritik uyarıdaki otomatik SMS ücretsizdir; bu, kullanıcının
          // kendi isteğiyle gönderdiği periyodik durum özetidir (premium).
          _CaregiverShareTile(onShare: widget.onShareWithCaregiver),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_dirty
                    ? loc.l10n.profileSaveChanges
                    : loc.l10n.save),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
            label: Text(loc.l10n.profileSignOut),
          ),
        ],
      ),
    );
  }

  String? _validateNumber(Loc loc, String? v) {
    if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
    if (_parse(v) == null) return loc.l10n.profileInvalidNumber;
    return null;
  }
}

/// Abonelik durumu kartı: aktifse bitiş tarihi ve yönetim bağlantısı,
/// değilse premium'a geçiş.
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard();

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final service = PremiumScope.of(context);
    final entitlement = service.entitlement;

    if (!entitlement.isPremium) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => PaywallScreen(service: service),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.workspace_premium,
                    size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.l10n.subscriptionFreeTitle,
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        loc.l10n.subscriptionFreeMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    }

    final expires = entitlement.expiresAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PremiumBadge(),
                const Spacer(),
                if (entitlement.isTrial)
                  Text(loc.l10n.subscriptionTrialTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w700,
                      )),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              expires == null
                  ? loc.l10n.subscriptionLifetime
                  : entitlement.willRenew
                      ? '${_fmtDate(expires)} tarihinde yenilenecek'
                      : '${_fmtDate(expires)} tarihinde sona erecek',
              style: theme.textTheme.bodyLarge,
            ),
            if (!entitlement.willRenew && expires != null) ...[
              const SizedBox(height: 4),
              Text(
                loc.l10n.subscriptionCancelled,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (expires != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: service.openManagementPage,
                icon: const Icon(Icons.open_in_new),
                label: Text(loc.l10n.subscriptionManage),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Durumumu yakınıma gönder" — son INR, bugünkü doz ve 7 günlük uyum
/// özetini acil durum kişisine iletir. Premium olmayan kullanıcıya kilit
/// yerine ne kazanacağını anlatan kart gösterilir (bkz. premium_gate.dart).
class _CaregiverShareTile extends StatefulWidget {
  final Future<void> Function() onShare;

  const _CaregiverShareTile({required this.onShare});

  @override
  State<_CaregiverShareTile> createState() => _CaregiverShareTileState();
}

class _CaregiverShareTileState extends State<_CaregiverShareTile> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await widget.onShare();
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final premium = PremiumScope.of(context);

    if (!premium.has(PremiumFeature.caregiverSharing)) {
      return PremiumLockCard(
        feature: PremiumFeature.caregiverSharing,
        icon: Icons.family_restroom_outlined,
        title: loc.l10n.caregiverShareTitle,
        description: loc.l10n.caregiverShareDescription,
      );
    }

    return OutlinedButton.icon(
      onPressed: _sharing ? null : _share,
      icon: _sharing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share),
      label: Text(_sharing
          ? loc.l10n.caregiverSharePreparing
          : loc.l10n.caregiverShareAction),
    );
  }
}

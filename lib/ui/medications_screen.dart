/// "İlaçlarım" sekmesi — tüm ilaçlar, dozları, sıklıkları ve uyum özeti.
library;

import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';
import '../models/medication.dart';
import '../repositories/repositories.dart';
import '../services/entitlement_service.dart';
import '../services/medication_service.dart';
import 'medication_card.dart';
import 'medication_editor_screen.dart';
import 'premium_gate.dart';
import 'theme.dart';

class MedicationsScreen extends StatelessWidget {
  final MedicationRepository repository;
  final MedicationService service;

  /// İlaç eklendiğinde/değiştiğinde bildirimlerin yeniden kurulması için.
  final Future<void> Function() onChanged;

  const MedicationsScreen({
    super.key,
    required this.repository,
    required this.service,
    required this.onChanged,
  });

  Future<void> _openEditor(
    BuildContext context, {
    Medication? initial,
    required List<Medication> existing,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicationEditorScreen(
          initial: initial,
          hasOtherAnticoagulant: existing
              .any((m) => m.isAnticoagulant && m.id != initial?.id),
          onSave: (medication) async {
            await repository.upsert(medication);
            await onChanged();
          },
          onDelete: initial == null
              ? null
              : (medication) async {
                  await repository.delete(medication.id);
                  await onChanged();
                },
        ),
      ),
    );
  }

  Future<void> _addMedication(
    BuildContext context,
    List<Medication> existing,
  ) async {
    final entitlements = PremiumScope.read(context);
    if (!entitlements.canAddMedication(existing.length)) {
      final unlocked =
          await ensurePremium(context, PremiumFeature.unlimitedMedications);
      if (!unlocked || !context.mounted) return;
    }
    if (!context.mounted) return;
    await _openEditor(context, existing: existing);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final today = DateTime.now();

    return StreamBuilder<List<Medication>>(
      stream: repository.watchAll(),
      builder: (context, snapshot) {
        final meds = snapshot.data;
        if (meds == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: meds.isEmpty
              ? _EmptyMedications(
                  onAdd: () => _addMedication(context, meds),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    _AdherenceCard(service: service),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: loc.l10n.medsTitle,
                      subtitle: loc.l10n.medsSubtitle,
                    ),
                    Card(
                      child: Column(
                        children: [
                          for (var i = 0; i < meds.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            MedicationSummaryTile(
                              medication: meds[i],
                              today: today,
                              onTap: () => _openEditor(
                                context,
                                initial: meds[i],
                                existing: meds,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final med in meds)
                      if (med.frequency == DoseFrequency.weeklyPattern)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: WeeklyDoseStrip(
                            medication: med,
                            today: today,
                          ),
                        ),
                    _FreeLimitNotice(currentCount: meds.length),
                  ],
                ),
          floatingActionButton: meds.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addMedication(context, meds),
                  icon: const Icon(Icons.add),
                  label: Text(loc.l10n.medsAdd),
                ),
        );
      },
    );
  }
}

class _EmptyMedications extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyMedications({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          icon: Icons.medication_outlined,
          title: loc.l10n.medsEmptyTitle,
          message: loc.l10n.medsEmptyMessage,
          actionLabel: loc.l10n.medsEmptyAction,
          onAction: onAdd,
        ),
      ),
    );
  }
}

/// Son 7 günün uyum özeti — doktora "düzenli kullanıyor musunuz?"
/// sorusuna verilecek somut cevap.
class _AdherenceCard extends StatelessWidget {
  final MedicationService service;
  const _AdherenceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    return FutureBuilder<AdherenceSummary>(
      future: service.adherence(days: 7),
      builder: (context, snapshot) {
        final summary = snapshot.data;
        if (summary == null || summary.isEmpty) return const SizedBox.shrink();

        final percent = summary.percent;
        final color = percent >= 90
            ? theme.colorScheme.primary
            : percent >= 70
                ? theme.colorScheme.tertiary
                : theme.colorScheme.error;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percent / 100,
                        strokeWidth: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      Center(
                        child: Text(
                          '%${percent.round()}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.l10n.medsAdherenceTitle,
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        loc.l10n.medsAdherenceDetail(
                              summary.taken,
                              summary.scheduled,
                            ) +
                            (summary.missed > 0
                                ? loc.l10n.medsAdherenceMissed(summary.missed)
                                : ''),
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
        );
      },
    );
  }
}

/// Ücretsiz katman limitine yaklaşıldığında bilgilendirir.
class _FreeLimitNotice extends StatelessWidget {
  final int currentCount;
  const _FreeLimitNotice({required this.currentCount});

  @override
  Widget build(BuildContext context) {
    final service = PremiumScope.of(context);
    if (service.has(PremiumFeature.unlimitedMedications)) {
      return const SizedBox.shrink();
    }
    if (currentCount < FreeTierLimits.medicationCount) {
      return const SizedBox.shrink();
    }

    return PremiumLockCard(
      feature: PremiumFeature.unlimitedMedications,
      icon: Icons.medication_outlined,
      title: context.loc.l10n.medsLimitTitle,
      description:
          context.loc.l10n.medsLimitMessage(FreeTierLimits.medicationCount),
    );
  }
}

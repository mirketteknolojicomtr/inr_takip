/// "Bugün" sekmesi — kullanıcının günde birkaç kez baktığı ekran.
///
/// Sıralama bilinçlidir: önce **ne yapmam gerekiyor** (sonraki doz,
/// miktarıyla), sonra **durumum ne** (INR), sonra **detay** (bugünün
/// tüm alımları, haftalık şema).
library;

import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';
import '../models/inr_entry.dart';
import '../models/medication.dart';
import '../models/patient_profile.dart';
import '../services/medication_service.dart';
import '../services/trend_service.dart';
import 'inr_ambient_hero.dart';
import 'medication_card.dart';
import 'theme.dart';

class TodayScreen extends StatelessWidget {
  final PatientProfile profile;
  final InrTrendData? trend;
  final MedicationDay? medicationDay;
  final Medication? anticoagulant;

  final Future<void> Function(ScheduledDose dose, IntakeStatus status) onMark;
  final VoidCallback onAddMeasurement;
  final VoidCallback onOpenMedications;

  const TodayScreen({
    super.key,
    required this.profile,
    required this.trend,
    required this.medicationDay,
    required this.anticoagulant,
    required this.onMark,
    required this.onAddMeasurement,
    required this.onOpenMedications,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final day = medicationDay;
    final nextDose = day?.nextPending(now);
    final latest = trend?.points.isNotEmpty == true ? trend!.points.last : null;

    return ListView(
      // Alt boşluk, iki katlı FAB yığınını (kamera + "Ölçüm ekle") temizler;
      // aksi hâlde listenin son öğesi FAB'ın altında kalıp dokunulamıyor.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 168),
      children: [
        _Greeting(name: profile.name),
        const SizedBox(height: 16),

        // 1) Yapılacak iş: sonraki doz ve MİKTARI.
        if (nextDose != null)
          NextDoseCard(dose: nextDose, onMark: onMark)
        else if (day != null && day.doses.isNotEmpty)
          _AllDoneCard(day: day)
        else
          EmptyState(
            icon: Icons.medication_outlined,
            title: loc.l10n.todayNoMedicationTitle,
            message: loc.l10n.todayNoMedicationMessage,
            actionLabel: loc.l10n.todayAddMedication,
            onAction: onOpenMedications,
          ),
        const SizedBox(height: 24),

        // 2) Durum: güncel INR.
        SectionHeader(
          title: loc.l10n.todayCurrentInr,
          subtitle: loc.l10n.todayTargetRange(
            loc.formats.inr(profile.targetRange.lower),
            loc.formats.inr(profile.targetRange.upper),
          ),
        ),
        if (latest != null)
          AmbientInrHero(
            inrValue: latest.inr,
            zone: latest.zone,
            measuredAt: latest.date,
          )
        else
          EmptyState(
            icon: Icons.science_outlined,
            title: loc.l10n.todayNoMeasurementTitle,
            message: loc.l10n.todayNoMeasurementMessage,
            actionLabel: loc.l10n.todayAddMeasurement,
            onAction: onAddMeasurement,
          ),
        if (latest != null) ...[
          const SizedBox(height: 12),
          _ZoneNote(zone: latest.zone, profile: profile),
        ],
        const SizedBox(height: 24),

        // 3) Detay: bugünün tüm alımları ve haftalık şema.
        if (day != null && day.doses.isNotEmpty) ...[
          SectionHeader(
            title: loc.l10n.todayMedicationsTitle,
            subtitle: loc.l10n.todayMedicationsSubtitle(
              day.doses.length,
              MedicationLabels.mg(loc, day.totalMg),
            ),
            trailing: TextButton(
              onPressed: onOpenMedications,
              child: Text(loc.l10n.todayEditPlan),
            ),
          ),
          TodayDosesCard(day: day, onMark: onMark),
          const SizedBox(height: 20),
        ],

        if (anticoagulant != null &&
            anticoagulant!.frequency == DoseFrequency.weeklyPattern) ...[
          WeeklyDoseStrip(medication: anticoagulant!, today: now),
          const SizedBox(height: 20),
        ],

        Text(
          loc.l10n.todayDisclaimer,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final loc = context.loc;
    // 00:00-04:59 gecedir: "Günaydın" değil akşam selamı gösterilir.
    final greeting = hour < 5
        ? loc.l10n.greetingEvening
        : hour < 11
            ? loc.l10n.greetingMorning
            : hour < 18
                ? loc.l10n.greetingDay
                : loc.l10n.greetingEvening;
    final firstName = name.trim().split(' ').first;

    return Text(
      '$greeting, $firstName',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  final MedicationDay day;
  const _AllDoneCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final zone = ZoneColors.of(InrZone.inRange, theme.brightness);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: zone.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zone.border),
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt, size: 36, color: zone.foreground),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.l10n.todayAllDoneTitle,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: zone.foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.l10n.todayAllDoneSubtitle(
                    MedicationLabels.mg(loc, day.takenMg),
                  ),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: zone.foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// INR bölgesinin ne anlama geldiğini düz Türkçe anlatır — renk tek
/// başına bilgi taşımasın diye (renk körlüğü + sağlık okuryazarlığı).
class _ZoneNote extends StatelessWidget {
  final InrZone zone;
  final PatientProfile profile;

  const _ZoneNote({required this.zone, required this.profile});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final colors = ZoneColors.of(zone, theme.brightness);

    final message = switch (zone) {
      InrZone.inRange => loc.l10n.zoneNoteInRange,
      InrZone.belowRange => loc.l10n.zoneNoteBelow,
      InrZone.aboveRange => loc.l10n.zoneNoteAbove,
      InrZone.criticalLow =>
        loc.l10n.zoneNoteCriticalLow(loc.formats.inr(profile.criticalLow)),
      InrZone.criticalHigh =>
        loc.l10n.zoneNoteCriticalHigh(loc.formats.inr(profile.criticalHigh)),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(zoneIcon(zone), color: colors.foreground, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inrZoneLabel(loc, zone),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: colors.foreground),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colors.foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

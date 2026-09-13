/// İlaç dozu ve sıklığını görünür kılan ana ekran bileşenleri.
///
///  - [NextDoseCard]: sonraki doza geri sayım + O DOZUN MİKTARI
///    ("5 mg · 1 tablet") + sıklık etiketi. Kullanıcı ekrana bakınca
///    "ne zaman, ne kadar" sorusunun ikisini birden görür.
///  - [TodayDosesCard]: bugünün tüm alımları, "Aldım/Atladım" ile.
///  - [WeeklyDoseStrip]: haftalık doz şeması — warfarin dozu günden güne
///    değiştiği için tek satırlık bu şerit klinik olarak en kritik görsel.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';
import '../models/medication.dart';
import '../services/medication_service.dart';
import 'safe_touch.dart';

class NextDoseCard extends StatefulWidget {
  final ScheduledDose dose;
  final Future<void> Function(ScheduledDose dose, IntakeStatus status) onMark;

  const NextDoseCard({super.key, required this.dose, required this.onMark});

  @override
  State<NextDoseCard> createState() => _NextDoseCardState();
}

class _NextDoseCardState extends State<NextDoseCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tick();
    // Saniye saniye geri sayım: ilaç saatine dakikalar kala kullanıcı
    // hareketi hissedebilsin.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant NextDoseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dose.scheduledAt != widget.dose.scheduledAt) _tick();
  }

  void _tick() {
    final next = widget.dose.scheduledAt.difference(DateTime.now());
    if (mounted) setState(() => _remaining = next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final abs = d.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    final s = (abs.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _mark(IntakeStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onMark(widget.dose, status);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dose = widget.dose;

    final overdue = _remaining.isNegative;
    final soon = !overdue && _remaining < const Duration(hours: 1);

    final accent = overdue
        ? scheme.error
        : soon
            ? scheme.tertiary
            : scheme.primary;
    final background = overdue
        ? scheme.errorContainer
        : soon
            ? scheme.tertiaryContainer
            : scheme.primaryContainer;
    final onBackground = overdue
        ? scheme.onErrorContainer
        : soon
            ? scheme.onTertiaryContainer
            : scheme.onPrimaryContainer;

    final takeButton = FilledButton.icon(
      onPressed: _busy ? null : () => _mark(IntakeStatus.taken),
      icon: const Icon(Icons.check),
      label: Text(loc.l10n.doseTake),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overdue ? Icons.notifications_active : Icons.medication_rounded,
                color: accent,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  overdue ? loc.l10n.doseOverdue : loc.l10n.doseCountdown,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: onBackground,
                  ),
                ),
              ),
              Text(
                TimeOfDay.fromDateTime(dose.scheduledAt).format(context),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: onBackground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _fmt(_remaining),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: onBackground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),

          // --- DOZ: kartın asıl bilgisi ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dose.medication.name,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dose.amountLabel(loc),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dose.medication.frequencyLabel(loc),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tek dokunuş sesli okur, çift dokunuş onaylar
                // (el titremesi olan kullanıcılar için).
                SafeTouchButton(
                  announcement: loc.l10n.doseConfirmAnnouncement(
                    dose.medication.name,
                    dose.amountLabel(loc),
                  ),
                  onConfirm: () => _mark(IntakeStatus.taken),
                  child: takeButton,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : () => _mark(IntakeStatus.skipped),
              child: Text(
                loc.l10n.doseSkip,
                style: TextStyle(color: onBackground),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bugünün tüm alımları — birden fazla ilaç/saat varsa hepsi tek listede.
class TodayDosesCard extends StatelessWidget {
  final MedicationDay day;
  final Future<void> Function(ScheduledDose dose, IntakeStatus status) onMark;

  const TodayDosesCard({super.key, required this.day, required this.onMark});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < day.doses.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _DoseRow(
                dose: day.doses[i],
                now: now,
                onMark: onMark,
              ),
            ],
            if (day.doses.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.summarize_outlined,
                        size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        loc.l10n.doseTodayTotal(
                          MedicationLabels.mg(loc, day.totalMg),
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      loc.l10n.doseTakenTotal(
                        MedicationLabels.mg(loc, day.takenMg),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoseRow extends StatelessWidget {
  final ScheduledDose dose;
  final DateTime now;
  final Future<void> Function(ScheduledDose dose, IntakeStatus status) onMark;

  const _DoseRow({
    required this.dose,
    required this.now,
    required this.onMark,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = dose.isOverdue(now);

    final (IconData icon, Color color, String label) = switch (dose) {
      _ when dose.isTaken =>
        (Icons.check_circle, scheme.primary, loc.l10n.intakeTaken),
      _ when dose.isSkipped => (
          Icons.remove_circle_outline,
          scheme.onSurfaceVariant,
          loc.l10n.intakeSkipped
        ),
      _ when overdue =>
        (Icons.error_outline, scheme.error, loc.l10n.doseStateLate),
      _ => (Icons.schedule, scheme.onSurfaceVariant, loc.l10n.doseStateWaiting),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      TimeOfDay.fromDateTime(dose.scheduledAt).format(context),
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dose.medication.name,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${dose.amountLabel(loc)} · $label',
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (dose.isPending)
            IconButton.filledTonal(
              tooltip: loc.l10n.doseTakeTooltip(dose.medication.name),
              onPressed: () => onMark(dose, IntakeStatus.taken),
              icon: const Icon(Icons.check),
            )
          else
            IconButton(
              tooltip: loc.l10n.doseUndoTooltip,
              // Aynı durumu tekrar göndermek kaydı siler (bkz. _markDose)
              // -- yanlış dokunuşu düzeltmenin tek adımlı yolu.
              onPressed: () => onMark(dose, dose.intake!.status),
              icon: Icon(Icons.undo, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

/// Haftalık doz şeması şeridi. Warfarin dozu günden güne değişebildiği
/// için ("Pzt 5 mg, Sal 2.5 mg...") bu şerit uygulamanın en çok bakılan
/// görselidir; bugün vurgulanır.
class WeeklyDoseStrip extends StatelessWidget {
  final Medication medication;
  final DateTime today;

  const WeeklyDoseStrip({
    super.key,
    required this.medication,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final monday = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: today.weekday - 1));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.l10n.weeklyStripTitle(medication.name),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  'Toplam ${loc.formats.decimal(medication.weeklyTotalMg)} mg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _DayCell(
                      day: monday.add(Duration(days: i)),
                      medication: medication,
                      isToday: monday.add(Duration(days: i)).day == today.day &&
                          monday.add(Duration(days: i)).month == today.month,
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

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Medication medication;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.medication,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mg = medication.doseForDay(day);
    final hasDose = mg > 0;

    return Semantics(
      label: loc.l10n.weeklyStripDayLabel(
        loc.formats.weekdayLong(day.weekday),
        hasDose
            ? MedicationLabels.mg(loc, mg)
            : loc.l10n.weeklyStripNoDose,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isToday
              ? scheme.primaryContainer
              : hasDose
                  ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isToday ? Border.all(color: scheme.primary, width: 2) : null,
        ),
        child: Column(
          children: [
            Text(
              loc.formats.weekdayShort(day.weekday),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasDose ? loc.formats.decimal(mg) : '—',
              style: theme.textTheme.titleSmall?.copyWith(
                color: hasDose ? scheme.onSurface : scheme.outline,
              ),
            ),
            Text(
              hasDose ? 'mg' : '',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// İlaç listesi satırı: adı, dozu ve sıklığı tek bakışta.
class MedicationSummaryTile extends StatelessWidget {
  final Medication medication;
  final DateTime today;
  final VoidCallback? onTap;

  const MedicationSummaryTile({
    super.key,
    required this.medication,
    required this.today,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: medication.isAnticoagulant
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        child: Icon(
          medication.isAnticoagulant
              ? Icons.water_drop_outlined
              : Icons.medication_outlined,
          color: medication.isAnticoagulant
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(medication.name)),
          if (medication.isAnticoagulant) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                loc.l10n.anticoagulantBadge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Doz: bugünün miktarı; şema değişkense haftalık toplam da yazılır.
              medication.frequency == DoseFrequency.weeklyPattern
                  ? loc.l10n.doseSummaryToday(
                      medication.doseSummary(loc, today),
                    )
                  : medication.doseSummary(loc, today),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.repeat, size: 15, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    medication.frequencyLabel(loc),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (!medication.remindersEnabled)
                  Icon(Icons.notifications_off_outlined,
                      size: 16, color: scheme.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    );
  }
}

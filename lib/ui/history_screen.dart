/// "Geçmiş" sekmesi — trend grafiği, ölçüm listesi, PDF rapor, K vitamini
/// günlüğü ve diyet içgörüleri.
///
/// Günlüğe kayıt **ücretsizdir** (veri girişi hiçbir zaman kilitlenmez);
/// kilitli olan, o kayıtlardan üretilen korelasyon içgörüleridir.
///
/// Ücretsiz katmanda pencere son 30 günle sınırlıdır; sınır bir duvar
/// değil, ne kazanılacağını anlatan bir kartla gösterilir
/// (bkz. premium_gate.dart).
library;

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../l10n/domain_labels.dart';
import '../models/inr_entry.dart';
import '../models/patient_profile.dart';
import '../models/vitamin_k_log.dart';
import '../repositories/repositories.dart';
import '../services/entitlement_service.dart';
import '../services/pdf_report_service.dart';
import '../services/trend_service.dart';
import 'inr_trend_chart.dart';
import 'premium_gate.dart';
import 'theme.dart';
import 'vitamin_k_dialog.dart';

class HistoryScreen extends StatefulWidget {
  final PatientProfile profile;
  final InrRepository inrRepo;
  final VitaminKRepository vitaminKRepo;
  final TrendService trendService;
  final PdfReportService pdfService;

  const HistoryScreen({
    super.key,
    required this.profile,
    required this.inrRepo,
    required this.vitaminKRepo,
    required this.trendService,
    required this.pdfService,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// Ücretsiz katmanda yalnızca 30 gün seçilebilir.
  static const _windows = <int>[30, 90, 180, 365];

  int _days = 30;
  InrTrendData? _trend;
  List<DietInsight> _insights = const [];
  List<VitaminKLog> _kLogs = const [];
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final trend = await widget.trendService.buildTrend(
      days: _days,
      range: widget.profile.targetRange,
      criticalLow: widget.profile.criticalLow,
      criticalHigh: widget.profile.criticalHigh,
    );
    final insights =
        await widget.trendService.correlateDietWithInr(days: _days);
    final logs = await widget.vitaminKRepo.getLogs(
      from: DateTime.now().subtract(Duration(days: _days)),
    );
    if (!mounted) return;
    setState(() {
      _trend = trend;
      _insights = insights;
      _kLogs = logs;
    });
  }

  Future<void> _addVitaminKLog() async {
    VitaminKLog? created;
    await showDialog<void>(
      context: context,
      builder: (_) => VitaminKDialog(onSave: (log) => created = log),
    );
    final log = created;
    if (log == null) return;
    await widget.vitaminKRepo.upsert(log);
    await _load();
  }

  Future<void> _deleteVitaminKLog(VitaminKLog log) async {
    await widget.vitaminKRepo.delete(log.id);
    await _load();
  }

  Future<void> _selectWindow(int days) async {
    if (days == _days) return;
    if (days > FreeTierLimits.historyDays) {
      final unlocked =
          await ensurePremium(context, PremiumFeature.unlimitedHistory);
      if (!unlocked || !mounted) return;
    }
    setState(() => _days = days);
    await _load();
  }

  Future<void> _exportPdf() async {
    if (!await ensurePremium(context, PremiumFeature.pdfReport)) return;
    if (!mounted || _exporting) return;

    setState(() => _exporting = true);
    try {
      final months = (_days / 30).ceil().clamp(1, 12);
      final loc = context.loc;
      final bytes = await widget.pdfService
          .buildReport(loc, widget.profile, months: months);
      await Printing.sharePdf(bytes: bytes, filename: loc.l10n.pdfFileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.loc.l10n.historyReportFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final trend = _trend;
    final premium = PremiumScope.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _WindowSelector(
            windows: _windows,
            selected: _days,
            freeLimit: premium.has(PremiumFeature.unlimitedHistory)
                ? null
                : FreeTierLimits.historyDays,
            onSelected: _selectWindow,
          ),
          const SizedBox(height: 20),

          if (trend == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              ),
            )
          else if (trend.points.isEmpty)
            EmptyState(
              icon: Icons.show_chart,
              title: loc.l10n.historyEmptyTitle,
              message: loc.l10n.historyEmptyMessage,
            )
          else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
                child: InrTrendChart(data: trend),
              ),
            ),
            const SizedBox(height: 12),
            _InRangeSummary(trend: trend),
            const SizedBox(height: 24),

            SectionHeader(
              title: loc.l10n.historyReportTitle,
              subtitle: loc.l10n.historyReportSubtitle,
              trailing: premium.has(PremiumFeature.pdfReport)
                  ? null
                  : const PremiumBadge(compact: true),
            ),
            OutlinedButton.icon(
              onPressed: _exporting ? null : _exportPdf,
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                _exporting
                    ? loc.l10n.historyReportPreparing
                    : loc.l10n.historyReportShare,
              ),
            ),
            const SizedBox(height: 24),

            _VitaminKJournal(
              logs: _kLogs,
              onAdd: _addVitaminKLog,
              onDelete: _deleteVitaminKLog,
            ),
            const SizedBox(height: 24),

            _DietInsights(insights: _insights),
            const SizedBox(height: 24),

            SectionHeader(
              title: loc.l10n.historyMeasurements,
              subtitle: loc.l10n.historyRecordCount(trend.points.length),
            ),
            _EntryList(
              profile: widget.profile,
              inrRepo: widget.inrRepo,
              days: _days,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            loc.l10n.historyDisclaimer,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowSelector extends StatelessWidget {
  final List<int> windows;
  final int selected;

  /// Bu günden büyük pencereler kilitli (null = kilit yok).
  final int? freeLimit;
  final ValueChanged<int> onSelected;

  const _WindowSelector({
    required this.windows,
    required this.selected,
    required this.freeLimit,
    required this.onSelected,
  });

  String _label(Loc loc, int days) => switch (days) {
        30 => loc.l10n.windowDays(30),
        90 => loc.l10n.windowMonths(3),
        180 => loc.l10n.windowMonths(6),
        _ => loc.l10n.windowYear,
      };

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final days in windows)
          ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_label(loc, days)),
                if (freeLimit != null && days > freeLimit!) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.lock, size: 14),
                ],
              ],
            ),
            selected: days == selected,
            onSelected: (_) => onSelected(days),
          ),
      ],
    );
  }
}

class _InRangeSummary extends StatelessWidget {
  final InrTrendData trend;
  const _InRangeSummary({required this.trend});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final percent = trend.inRangePercent;
    // TTR benzeri metrik: %70 klinik olarak iyi kabul edilen eşiktir.
    final zone = percent >= 70
        ? InrZone.inRange
        : percent >= 50
            ? InrZone.aboveRange
            : InrZone.criticalHigh;
    final colors = ZoneColors.of(zone, theme.brightness);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Text(
            '%${percent.toStringAsFixed(0)}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.l10n.inRangeTitle,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: colors.foreground)),
                const SizedBox(height: 2),
                Text(
                  percent >= 70
                      ? loc.l10n.inRangeGood
                      : loc.l10n.inRangePoor,
                  style: theme.textTheme.bodySmall
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

/// K vitamini günlüğü: kayıt ekleme + son kayıtlar.
///
/// Kilit yok — veri girişi ücretsizdir (bkz. `kAlwaysFreeFeatures`).
/// Kullanıcı, içgörüler kilitliyken bile kayıt tutabilir; abonelik
/// açıldığında geçmiş veri hazır olur.
class _VitaminKJournal extends StatelessWidget {
  final List<VitaminKLog> logs;
  final VoidCallback onAdd;
  final ValueChanged<VitaminKLog> onDelete;

  const _VitaminKJournal({
    required this.logs,
    required this.onAdd,
    required this.onDelete,
  });

  /// Toplam K yükü — kullanıcıya "bu dönemde ne kadar yüklendim" der.
  double get _totalLoad =>
      logs.fold<double>(0, (sum, log) => sum + log.kLoad);

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: loc.l10n.vitaminKJournalTitle,
          subtitle: logs.isEmpty
              ? loc.l10n.vitaminKJournalEmptyHint
              : loc.l10n.vitaminKJournalSummary(
                  logs.length,
                  loc.formats.decimal(_totalLoad, maxFractionDigits: 1),
                ),
        ),
        if (logs.isNotEmpty)
          Card(
            child: Column(
              children: [
                for (var i = logs.length - 1; i >= 0; i--) ...[
                  if (i < logs.length - 1) const Divider(height: 1),
                  _VitaminKRow(
                    log: logs[i],
                    theme: theme,
                    onDelete: () => onDelete(logs[i]),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text(loc.l10n.vitaminKAddMeal),
        ),
      ],
    );
  }
}

class _VitaminKRow extends StatelessWidget {
  final VitaminKLog log;
  final ThemeData theme;
  final VoidCallback onDelete;

  const _VitaminKRow({
    required this.log,
    required this.theme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final name = log.displayName(loc);

    return ListTile(
      leading: Icon(Icons.eco_outlined, color: theme.colorScheme.primary),
      title: Text(name),
      subtitle: Text(loc.l10n.vitaminKEntrySubtitle(
        loc.formats.date(log.date),
        portionLabel(loc, log.portion),
        loc.formats.decimal(log.kLoad, maxFractionDigits: 1),
      )),
      trailing: IconButton(
        tooltip: loc.l10n.vitaminKDeleteTooltip(name),
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
    );
  }
}

class _DietInsights extends StatelessWidget {
  final List<DietInsight> insights;
  const _DietInsights({required this.insights});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final premium = PremiumScope.of(context);

    if (!premium.has(PremiumFeature.dietInsights)) {
      return PremiumLockCard(
        feature: PremiumFeature.dietInsights,
        icon: Icons.eco_outlined,
        title: loc.l10n.dietLockTitle,
        description: loc.l10n.dietLockDescription,
      );
    }

    if (insights.isEmpty) {
      return EmptyState(
        icon: Icons.eco_outlined,
        title: loc.l10n.dietEmptyTitle,
        message: loc.l10n.dietEmptyMessage,
      );
    }

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: loc.l10n.dietInsightsTitle),
        for (final insight in insights)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.eco_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _insightText(context, insight),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// İçgörü cümlesi: servis yapısal veri döndürür, metin burada kurulur.
String _insightText(BuildContext context, DietInsight insight) {
  final loc = context.loc;
  final foods =
      insight.logs.map((l) => l.displayName(loc)).toSet().join(', ');
  return loc.l10n.dietInsightText(
    loc.formats.decimal(insight.inrDelta.abs(), maxFractionDigits: 1),
    foods,
  );
}

class _EntryList extends StatelessWidget {
  final PatientProfile profile;
  final InrRepository inrRepo;
  final int days;

  const _EntryList({
    required this.profile,
    required this.inrRepo,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final from = DateTime.now().subtract(Duration(days: days));

    return FutureBuilder<List<InrEntry>>(
      future: inrRepo.getEntries(from: from),
      builder: (context, snapshot) {
        final entries = snapshot.data;
        if (entries == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (entries.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return Card(
          child: Column(
            children: [
              for (var i = entries.length - 1; i >= 0; i--) ...[
                if (i < entries.length - 1) const Divider(height: 1),
                _EntryRow(entry: entries[i], profile: profile, theme: theme),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EntryRow extends StatelessWidget {
  final InrEntry entry;
  final PatientProfile profile;
  final ThemeData theme;

  const _EntryRow({
    required this.entry,
    required this.profile,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final zone = entry.zoneWith(
      criticalLow: profile.criticalLow,
      criticalHigh: profile.criticalHigh,
    );
    final colors = ZoneColors.of(zone, theme.brightness);

    return ListTile(
      leading: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          entry.inrValue.toStringAsFixed(1),
          style: theme.textTheme.titleSmall?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        '${entry.date.day}.${entry.date.month}.${entry.date.year}',
      ),
      subtitle: Text(
        loc.l10n.entryRowSubtitle(
          loc.formats.decimal(entry.doseMg, maxFractionDigits: 1),
          inrZoneLabel(loc, zone),
        ),
      ),
      trailing: Icon(zoneIcon(zone), color: colors.foreground),
    );
  }
}

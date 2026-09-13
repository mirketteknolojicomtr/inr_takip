/// İlaç ekleme/düzenleme formu — dozun ve sıklığın girildiği yer.
///
/// Sıklık seçimi formun geri kalanını değiştirir:
///  - Her gün / Gün aşırı / Belirli günler -> saat + miktar satırları
///  - Haftalık şema -> tek saat + 7 gün için ayrı mg alanı
///    (warfarin doz şemasının doktordan geldiği hâli)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../l10n/domain_labels.dart';
import '../models/medication.dart';
import 'theme.dart';

class MedicationEditorScreen extends StatefulWidget {
  /// null ise yeni ilaç eklenir.
  final Medication? initial;

  /// Listede zaten bir antikoagülan var mı? (varsa uyarı gösterilir)
  final bool hasOtherAnticoagulant;

  final Future<void> Function(Medication medication) onSave;
  final Future<void> Function(Medication medication)? onDelete;

  const MedicationEditorScreen({
    super.key,
    this.initial,
    this.hasOtherAnticoagulant = false,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<MedicationEditorScreen> createState() => _MedicationEditorScreenState();
}

class _MedicationEditorScreenState extends State<MedicationEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final _nameCtrl =
      TextEditingController(text: widget.initial?.name ?? '');
  final _strengthCtrl = TextEditingController();
  late final _noteCtrl =
      TextEditingController(text: widget.initial?.note ?? '');

  late DoseFrequency _frequency =
      widget.initial?.frequency ?? DoseFrequency.daily;
  late Set<int> _weekdays =
      {...(widget.initial?.weekdays ?? const {1, 2, 3, 4, 5, 6, 7})};
  /// Yeni ilaç eklenirken varsayılan olarak AÇIK gelir (listede zaten bir
  /// kan sulandırıcı yoksa). Bu bir warfarin takip uygulaması; eklenen ilk
  /// ilaç neredeyse her zaman antikoagülandır ve bu işaret INR kaydındaki
  /// doz önerisini besler. Kapalı varsayılan, kullanıcının farkında bile
  /// olmadığı bir anahtar yüzünden doz otomatik dolmamasına yol açıyordu.
  late bool _isAnticoagulant = widget.initial?.isAnticoagulant ??
      !widget.hasOtherAnticoagulant;
  late bool _reminders = widget.initial?.remindersEnabled ?? true;
  late DateTime _startDate = widget.initial?.startDate ?? DateTime.now();

  /// daily / everyOtherDay / specificDays için saat+miktar satırları.
  late List<DoseTime> _times = widget.initial?.times.isNotEmpty == true
      ? [...widget.initial!.times]
      : [const DoseTime(hour: 19, minute: 0, amountMg: 5)];

  /// weeklyPattern için gün -> mg metin alanları.
  final Map<int, TextEditingController> _weeklyCtrls = {
    for (var d = 1; d <= 7; d++) d: TextEditingController(),
  };

  /// Sayı alanlarının ön-dolumu yerel ondalık ayracına bağlı ("2,5"/"2.5"),
  /// bu da ancak context hazırken bilinir.
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final formats = context.loc.formats;
    final strength = widget.initial?.unitStrengthMg;
    if (strength != null) _strengthCtrl.text = formats.decimal(strength);
    for (var d = 1; d <= 7; d++) {
      final mg = widget.initial?.weeklyDoseMg[d];
      if (mg != null && mg != 0) _weeklyCtrls[d]!.text = formats.decimal(mg);
    }
  }

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _strengthCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _weeklyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _pickTime(int index) async {
    final current = _times[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) return;
    setState(() => _times[index] =
        current.copyWith(hour: picked.hour, minute: picked.minute));
  }

  Future<void> _editAmount(int index) async {
    final loc = context.loc;
    final current = _times[index];
    final ctrl = TextEditingController(
      text: context.loc.formats.decimal(current.amountMg),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.l10n.editorDoseAmountTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: loc.l10n.editorAmountLabel,
            suffixText: 'mg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _parse(ctrl.text)),
            child: Text(loc.l10n.ok),
          ),
        ],
      ),
    );
    if (value != null && value > 0) {
      setState(() => _times[index] = current.copyWith(amountMg: value));
    }
  }

  String? _validate(Loc loc) {
    if (_nameCtrl.text.trim().isEmpty) return loc.l10n.editorNameRequired;

    if (_frequency == DoseFrequency.weeklyPattern) {
      final total = _weeklyCtrls.values
          .map((c) => _parse(c.text) ?? 0)
          .fold<double>(0, (a, b) => a + b);
      if (total <= 0) {
        return loc.l10n.editorWeeklyNeedsDose;
      }
    } else {
      if (_times.isEmpty) return loc.l10n.editorNeedsTime;
      if (_times.every((t) => t.amountMg <= 0)) {
        return loc.l10n.editorNeedsAmount;
      }
      if (_frequency == DoseFrequency.specificDays && _weekdays.isEmpty) {
        return loc.l10n.editorNeedsDay;
      }
    }
    return null;
  }

  Future<void> _save() async {
    final error = _validate(context.loc);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final weekly = <int, double>{};
    if (_frequency == DoseFrequency.weeklyPattern) {
      _weeklyCtrls.forEach((day, ctrl) {
        final mg = _parse(ctrl.text) ?? 0;
        if (mg > 0) weekly[day] = mg;
      });
    }

    final medication = Medication(
      id: widget.initial?.id ?? _uuid.v4(),
      name: _nameCtrl.text.trim(),
      unitStrengthMg: _parse(_strengthCtrl.text),
      frequency: _frequency,
      weekdays: _frequency == DoseFrequency.specificDays
          ? _weekdays
          : const {1, 2, 3, 4, 5, 6, 7},
      weeklyDoseMg: weekly,
      times: [..._times]..sort(),
      startDate: _startDate,
      isAnticoagulant: _isAnticoagulant,
      remindersEnabled: _reminders,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    setState(() => _saving = true);
    try {
      await widget.onSave(medication);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final loc = context.loc;
    final medication = widget.initial;
    final onDelete = widget.onDelete;
    if (medication == null || onDelete == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.l10n.editorDeleteTitle(medication.name)),
        content: Text(loc.l10n.editorDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.l10n.editorDiscard),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await onDelete(medication);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final isEdit = widget.initial != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEdit ? loc.l10n.editorEditTitle : loc.l10n.editorAddTitle),
        actions: [
          if (isEdit && widget.onDelete != null)
            IconButton(
              tooltip: 'Sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            SectionHeader(title: loc.l10n.editorMedicationSection),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: loc.l10n.editorNameLabel,
                hintText: loc.l10n.editorNameHint,
              ),
            ),
            const SizedBox(height: 10),
            _NameSuggestions(
              onSelected: (name) => setState(() {
                _nameCtrl.text = name;
                _isAnticoagulant = true;
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _strengthCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: loc.l10n.editorStrengthLabel,
                helperText: loc.l10n.editorStrengthHelper,
                suffixText: 'mg',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isAnticoagulant,
              onChanged: (v) => setState(() => _isAnticoagulant = v),
              title: Text(loc.l10n.editorAnticoagulantToggle),
              subtitle: Text(
                _isAnticoagulant && widget.hasOtherAnticoagulant
                    ? loc.l10n.editorAnticoagulantConflict
                    : loc.l10n.editorAnticoagulantHelp,
                style: TextStyle(
                  color: _isAnticoagulant && widget.hasOtherAnticoagulant
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 24),
            SectionHeader(
              title: loc.l10n.editorFrequencySection,
              subtitle: loc.l10n.editorFrequencySubtitle,
            ),
            _FrequencySelector(
              value: _frequency,
              onChanged: (v) => setState(() => _frequency = v),
            ),
            const SizedBox(height: 16),

            if (_frequency == DoseFrequency.specificDays) ...[
              _WeekdayPicker(
                selected: _weekdays,
                onChanged: (days) => setState(() => _weekdays = days),
              ),
              const SizedBox(height: 16),
            ],

            if (_frequency == DoseFrequency.everyOtherDay) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text(loc.l10n.editorStartDay),
                subtitle: Text(loc.l10n.editorStartDayHelp),
                trailing: Text(
                  '${_startDate.day}.${_startDate.month}.${_startDate.year}',
                  style: theme.textTheme.titleSmall,
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 365)),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              const SizedBox(height: 8),
            ],

            SectionHeader(
              title: loc.l10n.editorDoseSection,
              subtitle: loc.l10n.editorAmountSubtitle,
            ),
            if (_frequency == DoseFrequency.weeklyPattern)
              _WeeklyDoseEditor(
                controllers: _weeklyCtrls,
                time: _times.isEmpty
                    ? const DoseTime(hour: 19, minute: 0, amountMg: 0)
                    : _times.first,
                onPickTime: () async {
                  final current = _times.isEmpty
                      ? const DoseTime(hour: 19, minute: 0, amountMg: 0)
                      : _times.first;
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                        hour: current.hour, minute: current.minute),
                  );
                  if (picked == null) return;
                  setState(() {
                    final updated = current.copyWith(
                        hour: picked.hour, minute: picked.minute);
                    if (_times.isEmpty) {
                      _times = [updated];
                    } else {
                      _times[0] = updated;
                    }
                  });
                },
                onChanged: () => setState(() {}),
              )
            else
              _TimesEditor(
                times: _times,
                onPickTime: _pickTime,
                onEditAmount: _editAmount,
                onRemove: _times.length <= 1
                    ? null
                    : (i) => setState(() => _times.removeAt(i)),
                onAdd: () => setState(() => _times.add(
                      const DoseTime(hour: 9, minute: 0, amountMg: 5),
                    )),
                tabletStrength: _parse(_strengthCtrl.text),
              ),

            const SizedBox(height: 24),
            SectionHeader(title: loc.l10n.editorOtherSection),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _reminders,
              onChanged: (v) => setState(() => _reminders = v),
              title: Text(loc.l10n.editorReminderToggle),
              subtitle: Text(loc.l10n.editorReminderHelp),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: loc.l10n.editorNoteLabel,
                hintText: loc.l10n.editorNoteHint,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Kaydet'),
        ),
      ),
    );
  }
}

/// Türkiye'de yaygın antikoagülan marka adları — yazım hatasını azaltır.
class _NameSuggestions extends StatelessWidget {
  final ValueChanged<String> onSelected;
  const _NameSuggestions({required this.onSelected});

  static const _names = ['Coumadin', 'Orfarin', 'Warfarin', 'Sintrom'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final name in _names)
          ActionChip(
            label: Text(name),
            onPressed: () => onSelected(name),
          ),
      ],
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final DoseFrequency value;
  final ValueChanged<DoseFrequency> onChanged;

  const _FrequencySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return RadioGroup<DoseFrequency>(
      groupValue: value,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      child: Column(
        children: [
          for (final option in DoseFrequency.values)
            RadioListTile<DoseFrequency>(
              contentPadding: EdgeInsets.zero,
              value: option,
              title: Text(doseFrequencyLabel(loc, option)),
              subtitle: Text(
                switch (option) {
                  DoseFrequency.daily => loc.l10n.freqDailyHelp,
                  DoseFrequency.everyOtherDay =>
                    loc.l10n.freqEveryOtherDayHelp,
                  DoseFrequency.specificDays =>
                    loc.l10n.freqSpecificDaysHelp,
                  DoseFrequency.weeklyPattern =>
                    loc.l10n.freqWeeklyPatternHelp,
                },
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const _WeekdayPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var day = 1; day <= 7; day++)
          FilterChip(
            label: Text(loc.formats.weekdayShort(day)),
            selected: selected.contains(day),
            onSelected: (on) {
              final next = {...selected};
              if (on) {
                next.add(day);
              } else {
                next.remove(day);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

/// Saat + miktar satırları (her gün / gün aşırı / belirli günler).
class _TimesEditor extends StatelessWidget {
  final List<DoseTime> times;
  final ValueChanged<int> onPickTime;
  final ValueChanged<int> onEditAmount;
  final ValueChanged<int>? onRemove;
  final VoidCallback onAdd;
  final double? tabletStrength;

  const _TimesEditor({
    required this.times,
    required this.onPickTime,
    required this.onEditAmount,
    required this.onRemove,
    required this.onAdd,
    this.tabletStrength,
  });

  /// Tablet adedi etiketi -- [Medication.tabletLabel] ile aynı kural,
  /// burada henüz bir Medication nesnesi yokken kullanılır.
  String? _tablet(double mg) {
    final strength = tabletStrength;
    if (strength == null || strength <= 0) return null;
    final quarters = (mg / strength * 4).round();
    if (quarters <= 0) return null;
    final whole = quarters ~/ 4;
    const fractions = ['', '¼', '½', '¾'];
    final fraction = fractions[quarters % 4];
    return whole == 0 ? '$fraction tablet' : '$whole$fraction tablet';
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < times.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      leading: const Icon(Icons.schedule),
                      title: Text(times[i].label(loc)),
                      subtitle: const Text('Saat'),
                      onTap: () => onPickTime(i),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      title: Text('${loc.formats.decimal(times[i].amountMg)} mg'),
                      subtitle: Text(
                        _tablet(times[i].amountMg) ?? 'Miktar',
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () => onEditAmount(i),
                    ),
                  ),
                  if (onRemove != null)
                    IconButton(
                      tooltip: loc.l10n.editorRemoveTime,
                      onPressed: () => onRemove!(i),
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(loc.l10n.editorAddTime),
          ),
        ),
      ],
    );
  }
}

/// Haftalık şema editörü: tek saat + 7 gün için ayrı mg.
class _WeeklyDoseEditor extends StatelessWidget {
  final Map<int, TextEditingController> controllers;
  final DoseTime time;
  final VoidCallback onPickTime;
  final VoidCallback onChanged;

  const _WeeklyDoseEditor({
    required this.controllers,
    required this.time,
    required this.onPickTime,
    required this.onChanged,
  });

  double get _total => controllers.values
      .map((c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0)
      .fold<double>(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(loc.l10n.editorTimeTitle),
            subtitle: Text(loc.l10n.editorTimeHelp),
            trailing: Text(time.label(loc), style: theme.textTheme.titleMedium),
            onTap: onPickTime,
          ),
        ),
        const SizedBox(height: 12),
        for (var day = 1; day <= 7; day++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    loc.formats.weekdayLong(day),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controllers[day],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      hintText: '0',
                      suffixText: 'mg',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            loc.l10n.editorWeeklyTotal(MedicationLabels.mg(loc, _total)),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

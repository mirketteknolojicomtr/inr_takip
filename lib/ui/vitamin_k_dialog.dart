/// K vitamini öğünü ekleme diyaloğu.
///
/// Warfarin etkisini K vitamini alımı doğrudan zayıflatır; bu yüzden
/// [TrendService.correlateDietWithInr] ölçümden önceki 72 saatin K yükünü
/// INR düşüşleriyle eşleştirir. O korelasyonun girdisi burada üretilir —
/// giriş ekranı olmadan model, depolama ve korelasyon katmanı boşta kalıyordu.
///
/// Amaç kalori/porsiyon defteri tutmak değil: kullanıcı iki dokunuşla
/// "ıspanak yedim, bol" diyebilmeli. Bu yüzden serbest metin yerine hazır
/// katalog ([VitaminKFood]) + üç kademeli porsiyon kullanılır.
///
/// "Kaydet"/"İptal" [SteadyTouchArea] içinde mıknatıslı hedeflerdir
/// (bkz. add_measurement_dialog.dart'taki aynı gerekçe).
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/domain_labels.dart';
import '../models/vitamin_k_log.dart';
import 'steady_touch.dart';

class VitaminKDialog extends StatefulWidget {
  /// Doğrulama geçtiğinde çağrılır; diyalog kapandıktan sonra koşar.
  final void Function(VitaminKLog log) onSave;

  /// Testlerde sabitlenebilsin diye dışarıdan verilebilir.
  final DateTime? now;

  const VitaminKDialog({super.key, required this.onSave, this.now});

  @override
  State<VitaminKDialog> createState() => _VitaminKDialogState();
}

class _VitaminKDialogState extends State<VitaminKDialog> {
  static const _uuid = Uuid();

  VitaminKFood _food = VitaminKFood.spinach;
  PortionSize _portion = PortionSize.medium;
  late DateTime _date = widget.now ?? DateTime.now();
  final _customCtrl = TextEditingController();

  String? _error;

  /// Diyalog yalnızca bir kez kapanmalı (bkz. add_measurement_dialog.dart:
  /// ikinci `Navigator.pop` alttaki ekranı da kapatıyordu).
  bool _closed = false;

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final now = widget.now ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // Korelasyon penceresi geçmişe bakar; ileri tarihli öğün anlamsızdır.
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      helpText: context.loc.l10n.vitaminKDatePickerHelp,
    );
    if (picked == null || !mounted) return;
    setState(() {
      // Saat bilgisi korunur: 72 saatlik pencere saat hassasiyetinde çalışır.
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  void _trySave() {
    if (_closed) return;

    final custom = _customCtrl.text.trim();
    if (_food == VitaminKFood.other && custom.isEmpty) {
      setState(() => _error = context.loc.l10n.vitaminKFoodNameRequired);
      return;
    }

    _close();
    widget.onSave(VitaminKLog(
      id: _uuid.v4(),
      date: _date,
      food: _food,
      portion: _portion,
      customName: _food == VitaminKFood.other ? custom : null,
    ));
  }

  String _dateLabelFor(Loc loc) {
    final now = widget.now ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(_date.year, _date.month, _date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return loc.l10n.dateToday;
    if (diff == 1) return loc.l10n.dateYesterday;
    return '${_date.day}.${_date.month}.${_date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;

    return AlertDialog(
      title: Text(loc.l10n.vitaminKDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.l10n.vitaminKWhatQuestion,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final food in VitaminKFood.values)
                  ChoiceChip(
                    label: Text(vitaminKFoodLabel(loc, food)),
                    selected: _food == food,
                    onSelected: (_) => setState(() {
                      _food = food;
                      _error = null;
                    }),
                  ),
              ],
            ),
            if (_food == VitaminKFood.other) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: loc.l10n.vitaminKFoodNameLabel,
                  hintText: loc.l10n.vitaminKFoodNameHint,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(loc.l10n.vitaminKPortionLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<PortionSize>(
              segments: [
                for (final portion in PortionSize.values)
                  ButtonSegment(
                    value: portion,
                    label: Text(portionLabel(loc, portion)),
                  ),
              ],
              selected: {_portion},
              onSelectionChanged: (s) => setState(() => _portion = s.first),
            ),
            const SizedBox(height: 20),
            Text(loc.l10n.vitaminKWhenQuestion, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(_dateLabelFor(loc)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        SteadyTouchArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SteadyTouchTarget(
                id: 'iptal',
                onConfirm: _close,
                child: TextButton(
                  onPressed: _close,
                  child: Text(loc.l10n.cancel),
                ),
              ),
              const SizedBox(width: 8),
              SteadyTouchTarget(
                id: 'kaydet',
                onConfirm: _trySave,
                child: FilledButton(
                  onPressed: _trySave,
                  child: Text(loc.l10n.save),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

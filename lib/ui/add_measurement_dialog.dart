/// Yeni INR ölçümü ekleme diyaloğu.
///
/// `main.dart` içine gömülüydü; buraya alındı çünkü (a) uygulamanın en
/// kritik veri girişi burası, (b) test edilebilir olması gerekiyor.
///
/// Doz alanı [DoseSuggestion] ile önceden doldurulur — kullanıcı her
/// ölçümde dozu elle yazmak zorunda kalmaz. Öneri yoksa alan boş kalır;
/// yanlış bir doz önermektense boş bırakmak doğrudur.
///
/// "Kaydet"/"İptal" [SteadyTouchArea] içinde mıknatıslı hedeflerdir
/// (el titremesi olan kullanıcılar için). Mıknatıs bölgesi bilinçli olarak
/// yalnızca aksiyon satırını kapsar: tüm diyaloğu sarınca metin alanına
/// dokunup parmağını kaldırmak da "Kaydet"i tetikleyebiliyordu.
library;

import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';
import '../services/medication_service.dart';
import 'steady_touch.dart';

class AddMeasurementDialog extends StatefulWidget {
  /// Kameradan okunmuşsa INR alanı bununla dolu gelir.
  final double? prefillInr;

  /// İlaç planından gelen doz önerisi (yoksa alan boş kalır).
  final DoseSuggestion? suggestion;

  /// Doğrulama geçtiğinde çağrılır; diyalog kapandıktan sonra koşar.
  final void Function(double inr, double doseMg) onSave;

  const AddMeasurementDialog({
    super.key,
    required this.onSave,
    this.prefillInr,
    this.suggestion,
  });

  @override
  State<AddMeasurementDialog> createState() => _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends State<AddMeasurementDialog> {
  final _inrCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();

  /// Alanların ön-dolumu yerel ayara bağlıdır ("2,5" / "2.5"), yerel ayar
  /// ise ancak context hazırken bilinir — bu yüzden initState değil
  /// didChangeDependencies. Kullanıcı yazmaya başladıysa üzerine yazılmaz.
  bool _prefilled = false;

  String? _error;

  /// Diyalog yalnızca bir kez kapanmalı: aynı dokunuş birden fazla yoldan
  /// gelirse ikinci `Navigator.pop` altındaki ekranı da kapatır ve
  /// uygulama boş bir Navigator'da (siyah ekran) kalır.
  bool _closed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final formats = context.loc.formats;
    final inr = widget.prefillInr;
    if (inr != null) _inrCtrl.text = formats.inr(inr);
    final suggestion = widget.suggestion;
    if (suggestion != null) _doseCtrl.text = formats.decimal(suggestion.mg);
  }

  @override
  void dispose() {
    _inrCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  /// Kullanıcı hangi ondalık ayracını yazarsa yazsın kabul edilir:
  /// Türkçe klavyede virgül, İngilizce klavyede nokta gelir ve yaşlı
  /// kullanıcıyı "yanlış ayraç" hatasıyla uğraştırmak kabul edilemez.
  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _close() {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  void _trySave() {
    if (_closed) return;

    final inr = _parse(_inrCtrl.text);
    if (inr == null || inr <= 0 || inr > 20) {
      setState(() => _error = context.loc.l10n.inrOutOfBounds);
      return;
    }
    final dose = _parse(_doseCtrl.text);
    if (dose == null || dose < 0) {
      setState(() => _error = context.loc.l10n.doseInvalid);
      return;
    }

    _close();
    widget.onSave(inr, dose);
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = widget.suggestion;
    final loc = context.loc;

    return AlertDialog(
      title: Text(loc.l10n.measurementDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _inrCtrl,
            autofocus: widget.prefillInr == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: loc.l10n.inrFieldLabel,
              hintText: loc.l10n.inrFieldHint,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _doseCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: loc.l10n.doseFieldLabel,
              suffixText: 'mg',
              helperText: suggestion == null
                  ? loc.l10n.doseFieldHelper
                  : (suggestion.fromToday
                      ? loc.l10n.doseSourceToday(suggestion.medication.name)
                      : loc.l10n
                          .doseSourceLastDay(suggestion.medication.name)),
              helperMaxLines: 2,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        SteadyTouchArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // İptal de bir hedef olmalı: aksi hâlde ona dokunulduğunda
              // en yakın hedef "Kaydet" seçilip ölçüm istemeden
              // kaydediliyordu.
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

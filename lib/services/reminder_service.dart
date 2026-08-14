/// İlaç Saati Hatırlatıcısı.
/// 1) ReminderService: her gün aynı saate yerel bildirim planlar
///    (flutter_local_notifications soyutlanmıştır).
/// 2) DoseCountdownWidget: ana ekranda saniye saniye geri sayan widget.
/// pubspec: flutter_local_notifications: ^17.0.0
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/patient_profile.dart';
import '../ui/safe_touch.dart';

/// Platform bildirim soyutlaması — testte mock'lanır.
abstract interface class ReminderScheduler {
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  });
  Future<void> cancel(int id);
}

class ReminderService {
  static const _doseReminderId = 1001;
  final ReminderScheduler _scheduler;

  ReminderService(this._scheduler);

  Future<void> syncWithProfile(PatientProfile profile) async {
    await _scheduler.cancel(_doseReminderId);
    await _scheduler.scheduleDaily(
      id: _doseReminderId,
      hour: profile.schedule.hour,
      minute: profile.schedule.minute,
      title: 'İlaç saati',
      body:
          '${profile.schedule.medicationName} dozunuzu alma vakti. '
          'Her gün aynı saatte almak INR stabilitesi için önemlidir.',
    );
  }
}

/// Ana ekran geri sayım widget'ı.
/// Her saniye kalan süreyi günceller; ilaç saatine 1 saatten az kaldıysa
/// vurgu rengine geçer.
class DoseCountdownWidget extends StatefulWidget {
  final MedicationSchedule schedule;
  final VoidCallback? onTakenPressed; // "Aldım" butonu

  const DoseCountdownWidget({
    super.key,
    required this.schedule,
    this.onTakenPressed,
  });

  @override
  State<DoseCountdownWidget> createState() => _DoseCountdownWidgetState();
}

class _DoseCountdownWidgetState extends State<DoseCountdownWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.schedule.timeUntilNextDose(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining = widget.schedule.timeUntilNextDose(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final soon = _remaining < const Duration(hours: 1);
    final scheme = Theme.of(context).colorScheme;

    final onTaken = widget.onTakenPressed;
    final takenButton = FilledButton(
      onPressed: onTaken,
      child: const Text('Aldım'),
    );
    // El titremesi olan kullanıcılar için: tek dokunuş sesli okur,
    // çift dokunuş onaylar (bkz. ui/safe_touch.dart).
    final safeTakenButton = onTaken == null
        ? takenButton
        : SafeTouchButton(
            announcement: 'Dozunuzu aldıysanız onaylamak için çift dokunun.',
            onConfirm: onTaken,
            child: takenButton,
          );

    return Card(
      color: soon ? scheme.errorContainer : scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.medication_outlined,
                size: 36,
                color: soon ? scheme.error : scheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sonraki doza kalan',
                      style: Theme.of(context).textTheme.labelMedium),
                  Text(
                    _fmt(_remaining),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '${widget.schedule.medicationName} • her gün '
                    '${widget.schedule.hour.toString().padLeft(2, '0')}:'
                    '${widget.schedule.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            safeTakenButton,
          ],
        ),
      ),
    );
  }
}

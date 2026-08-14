/// Hasta profili düzenleme ekranı: ad, hedef INR aralığı, acil durum
/// kişisi ve ilaç saati. "Kaydet" [onSave] callback'ini çağırır -- gerçek
/// kaydetme (yerel sqflite + Firestore push) main.dart'ta yapılır, bu
/// ekran yalnızca formu ve doğrulamayı yönetir.
library;

import 'package:flutter/material.dart';

import '../models/inr_entry.dart';
import '../models/patient_profile.dart';

class ProfileScreen extends StatefulWidget {
  final PatientProfile initialProfile;
  final Future<void> Function(PatientProfile profile) onSave;

  const ProfileScreen({
    super.key,
    required this.initialProfile,
    required this.onSave,
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
  late final _contactNameCtrl =
      TextEditingController(text: widget.initialProfile.emergencyContact?.name ?? '');
  late final _contactPhoneCtrl =
      TextEditingController(text: widget.initialProfile.emergencyContact?.phone ?? '');
  late final _medicationNameCtrl =
      TextEditingController(text: widget.initialProfile.schedule.medicationName);

  late TimeOfDay _doseTime = TimeOfDay(
    hour: widget.initialProfile.schedule.hour,
    minute: widget.initialProfile.schedule.minute,
  );

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetLowerCtrl.dispose();
    _targetUpperCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _medicationNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _doseTime);
    if (picked != null) setState(() => _doseTime = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lower = double.parse(_targetLowerCtrl.text.replaceAll(',', '.'));
    final upper = double.parse(_targetUpperCtrl.text.replaceAll(',', '.'));

    if (lower >= upper) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alt sınır, üst sınırdan küçük olmalı.')),
      );
      return;
    }

    final contactName = _contactNameCtrl.text.trim();
    final contactPhone = _contactPhoneCtrl.text.trim();

    final profile = PatientProfile(
      name: _nameCtrl.text.trim(),
      targetRange: TargetRange(lower: lower, upper: upper),
      emergencyContact: contactName.isEmpty && contactPhone.isEmpty
          ? null
          : EmergencyContact(name: contactName, phone: contactPhone),
      schedule: MedicationSchedule(
        hour: _doseTime.hour,
        minute: _doseTime.minute,
        medicationName: _medicationNameCtrl.text.trim().isEmpty
            ? 'Warfarin'
            : _medicationNameCtrl.text.trim(),
      ),
      criticalLow: widget.initialProfile.criticalLow,
      criticalHigh: widget.initialProfile.criticalHigh,
    );

    setState(() => _saving = true);
    try {
      await widget.onSave(profile);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null,
            ),
            const SizedBox(height: 16),
            Text('Hedef INR Aralığı', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _targetLowerCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Alt sınır'),
                    validator: _validateRangeBound,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _targetUpperCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Üst sınır'),
                    validator: _validateRangeBound,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Acil Durum Kişisi', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contactNameCtrl,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
            const SizedBox(height: 16),
            Text('İlaç', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _medicationNameCtrl,
              decoration: const InputDecoration(labelText: 'İlaç adı'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Doz saati'),
              trailing: Text(
                _doseTime.format(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: _pickTime,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateRangeBound(String? v) {
    if (v == null || v.trim().isEmpty) return 'Zorunlu alan';
    final parsed = double.tryParse(v.replaceAll(',', '.'));
    if (parsed == null) return 'Geçersiz sayı';
    return null;
  }
}

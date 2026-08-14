/// Hasta profili: hedef aralık, acil durum kişisi ve ilaç saati.
library;

import 'inr_entry.dart';

class EmergencyContact {
  final String name;
  final String phone;

  /// SMS ile bilgilendirilsin mi? (izin bazlı)
  final bool notifyBySms;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.notifyBySms = true,
  });

  Map<String, dynamic> toJson() =>
      {'name': name, 'phone': phone, 'notifyBySms': notifyBySms};

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] as String,
        phone: json['phone'] as String,
        notifyBySms: json['notifyBySms'] as bool? ?? true,
      );
}

/// Günlük ilaç saati (kan sulandırıcılar her gün aynı saatte alınmalı).
class MedicationSchedule {
  final int hour; // 0-23
  final int minute; // 0-59
  final String medicationName;

  const MedicationSchedule({
    required this.hour,
    required this.minute,
    this.medicationName = 'Warfarin',
  });

  /// [now] itibarıyla bir sonraki alım zamanı.
  DateTime nextDose(DateTime now) {
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// Geri sayım widget'ının kaynağı.
  Duration timeUntilNextDose(DateTime now) => nextDose(now).difference(now);

  Map<String, dynamic> toJson() =>
      {'hour': hour, 'minute': minute, 'medicationName': medicationName};

  factory MedicationSchedule.fromJson(Map<String, dynamic> json) =>
      MedicationSchedule(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        medicationName: json['medicationName'] as String? ?? 'Warfarin',
      );
}

class PatientProfile {
  final String name;
  final TargetRange targetRange;
  final EmergencyContact? emergencyContact;
  final MedicationSchedule schedule;

  /// Kritik eşikler (doktor önerisine göre değiştirilebilir).
  final double criticalLow;
  final double criticalHigh;

  const PatientProfile({
    required this.name,
    this.targetRange = TargetRange.standard,
    this.emergencyContact,
    this.schedule = const MedicationSchedule(hour: 19, minute: 0),
    this.criticalLow = 1.5,
    this.criticalHigh = 4.5,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'targetRange': targetRange.toJson(),
        'emergencyContact': emergencyContact?.toJson(),
        'schedule': schedule.toJson(),
        'criticalLow': criticalLow,
        'criticalHigh': criticalHigh,
      };

  factory PatientProfile.fromJson(Map<String, dynamic> json) => PatientProfile(
        name: json['name'] as String,
        targetRange:
            TargetRange.fromJson(json['targetRange'] as Map<String, dynamic>),
        emergencyContact: json['emergencyContact'] == null
            ? null
            : EmergencyContact.fromJson(
                json['emergencyContact'] as Map<String, dynamic>),
        schedule: MedicationSchedule.fromJson(
            json['schedule'] as Map<String, dynamic>),
        criticalLow: (json['criticalLow'] as num?)?.toDouble() ?? 1.5,
        criticalHigh: (json['criticalHigh'] as num?)?.toDouble() ?? 4.5,
      );
}

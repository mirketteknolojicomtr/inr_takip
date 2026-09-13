import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/models/inr_entry.dart';
import 'package:inr_takip/models/patient_profile.dart';
import 'package:inr_takip/services/alert_service.dart';

import 'l10n_helper.dart';

class _NoopNotifications implements NotificationGateway {
  int callCount = 0;
  @override
  Future<void> showLocalAlert({
    required String title,
    required String body,
    required AlertSeverity severity,
  }) async =>
      callCount++;
}

class _NoopEmergency implements EmergencyGateway {
  int callCount = 0;
  @override
  Future<void> notifyContact(
    EmergencyContact c, {
    required String title,
    required String body,
  }) async =>
      callCount++;
}

InrEntry _entry(double inr) => InrEntry(
      id: 't',
      date: DateTime(2026, 1, 1),
      inrValue: inr,
      doseMg: 5.0,
    );

void main() {
  const profile = PatientProfile(
    name: 'Test',
    emergencyContact: EmergencyContact(name: 'Yakın', phone: '+900000000000'),
  );

  group('AlertService.evaluate', () {
    final service =
        AlertService(_NoopNotifications(), _NoopEmergency(), testLoc);

    test('hedef aralıkta uyarı üretmez', () {
      expect(service.evaluate(_entry(2.5), profile), isNull);
    });

    test('kritik düşük INR acil uyarı üretir', () {
      final alert = service.evaluate(_entry(1.2), profile)!;
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.notifyEmergencyContact, isTrue);
    });

    test('kritik yüksek INR acil uyarı üretir', () {
      final alert = service.evaluate(_entry(5.0), profile)!;
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.notifyEmergencyContact, isTrue);
    });

    test('hedef dışı ama kritik olmayan değer warning üretir', () {
      final alert = service.evaluate(_entry(1.8), profile)!;
      expect(alert.severity, AlertSeverity.warning);
      expect(alert.notifyEmergencyContact, isFalse);
    });
  });

  group('AlertService.processNewEntry yan etkiler', () {
    test('kritik değerde bildirim + acil kişi SMS tetiklenir', () async {
      final notif = _NoopNotifications();
      final emergency = _NoopEmergency();
      final service = AlertService(notif, emergency, testLoc);

      await service.processNewEntry(_entry(5.2), profile);

      expect(notif.callCount, 1);
      expect(emergency.callCount, 1);
    });

    test('warning seviyesinde acil kişi aranmaz', () async {
      final notif = _NoopNotifications();
      final emergency = _NoopEmergency();
      final service = AlertService(notif, emergency, testLoc);

      await service.processNewEntry(_entry(3.4), profile);

      expect(notif.callCount, 1);
      expect(emergency.callCount, 0);
    });
  });

  group('MedicationSchedule', () {
    const schedule = MedicationSchedule(hour: 19, minute: 0);

    test('ilaç saati geçmediyse aynı günü döner', () {
      final now = DateTime(2026, 1, 1, 10, 0);
      expect(schedule.nextDose(now), DateTime(2026, 1, 1, 19, 0));
    });

    test('ilaç saati geçtiyse ertesi günü döner', () {
      final now = DateTime(2026, 1, 1, 20, 0);
      expect(schedule.nextDose(now), DateTime(2026, 1, 2, 19, 0));
    });
  });
}

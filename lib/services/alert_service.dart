/// Akıllı Uyarı Sistemi.
/// Saf iş mantığı (evaluate) ile yan etkiler (bildirim, SMS) ayrıştırıldı:
/// evaluate() birim testlenebilir, dispatch() platform servislerine delege eder.
library;

import '../models/inr_entry.dart';
import '../models/patient_profile.dart';

enum AlertSeverity { info, warning, critical }

class InrAlert {
  final AlertSeverity severity;
  final String titleTr;
  final String messageTr;

  /// Acil durum kişisi de bilgilendirilmeli mi?
  final bool notifyEmergencyContact;

  const InrAlert({
    required this.severity,
    required this.titleTr,
    required this.messageTr,
    this.notifyEmergencyContact = false,
  });
}

/// Yan etkiler için soyutlamalar — testte mock'lanır,
/// üretimde flutter_local_notifications / SMS intent'ine bağlanır.
abstract interface class NotificationGateway {
  Future<void> showLocalAlert(InrAlert alert);
}

abstract interface class EmergencyGateway {
  Future<void> notifyContact(EmergencyContact contact, InrAlert alert);
}

class AlertService {
  final NotificationGateway _notifications;
  final EmergencyGateway _emergency;

  AlertService(this._notifications, this._emergency);

  /// SAF FONKSİYON: Yeni bir INR kaydı için uyarı üretir (yan etkisiz).
  InrAlert? evaluate(InrEntry entry, PatientProfile profile) {
    final zone = entry.zoneWith(
      criticalLow: profile.criticalLow,
      criticalHigh: profile.criticalHigh,
    );

    switch (zone) {
      case InrZone.criticalLow:
        return InrAlert(
          severity: AlertSeverity.critical,
          titleTr: 'KRİTİK: INR çok düşük',
          messageTr:
              'INR ${entry.inrValue.toStringAsFixed(1)} — pıhtılaşma riski. '
              'Lütfen en kısa sürede doktorunuza veya sağlık kuruluşuna ulaşın.',
          notifyEmergencyContact: true,
        );
      case InrZone.criticalHigh:
        return InrAlert(
          severity: AlertSeverity.critical,
          titleTr: 'KRİTİK: INR çok yüksek',
          messageTr:
              'INR ${entry.inrValue.toStringAsFixed(1)} — kanama riski. '
              'Lütfen en kısa sürede doktorunuza veya sağlık kuruluşuna ulaşın.',
          notifyEmergencyContact: true,
        );
      case InrZone.belowRange:
        return InrAlert(
          severity: AlertSeverity.warning,
          titleTr: 'INR hedefin altında',
          messageTr:
              'INR ${entry.inrValue.toStringAsFixed(1)}, hedef aralık '
              '${entry.targetRange.lower}-${entry.targetRange.upper}. '
              'Takip ölçümünüzü planlayın ve doktorunuzu bilgilendirin.',
        );
      case InrZone.aboveRange:
        return InrAlert(
          severity: AlertSeverity.warning,
          titleTr: 'INR hedefin üstünde',
          messageTr:
              'INR ${entry.inrValue.toStringAsFixed(1)}, hedef aralık '
              '${entry.targetRange.lower}-${entry.targetRange.upper}. '
              'Takip ölçümünüzü planlayın ve doktorunuzu bilgilendirin.',
        );
      case InrZone.inRange:
        return null; // Uyarı gerekmez.
    }
  }

  /// Uyarıyı üretir VE dağıtır. Repository'ye kayıt sonrası çağrılır.
  Future<InrAlert?> processNewEntry(
      InrEntry entry, PatientProfile profile) async {
    final alert = evaluate(entry, profile);
    if (alert == null) return null;

    await _notifications.showLocalAlert(alert);

    final contact = profile.emergencyContact;
    if (alert.notifyEmergencyContact &&
        contact != null &&
        contact.notifyBySms) {
      await _emergency.notifyContact(contact, alert);
    }
    return alert;
  }
}

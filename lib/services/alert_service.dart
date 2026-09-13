/// Akıllı Uyarı Sistemi.
///
/// Saf iş mantığı (evaluate) ile yan etkiler (bildirim, SMS) ayrıştırıldı:
/// evaluate() birim testlenebilir, dağıtım platform servislerine delege eder.
///
/// DİL: [evaluate] hiçbir kullanıcı metni üretmez — yalnızca [InrAlertKind]
/// ve sayısal parametreler döndürür. Metne çevirme dağıtım anında, seçili
/// dile göre yapılır (bkz. l10n/domain_labels.dart). Böylece uyarı mantığı
/// 18 dilde tek bir testle doğrulanabilir ve arka plan izolatında da
/// (bildirim) doğru dilde metin üretilir.
library;

import '../l10n/domain_labels.dart';
import '../models/inr_entry.dart';
import '../models/patient_profile.dart';

enum AlertSeverity { info, warning, critical }

/// Uyarının TÜRÜ — metin değil. Çeviri katmanı bunu cümleye çevirir.
enum InrAlertKind {
  criticalLow,
  criticalHigh,
  belowRange,
  aboveRange,

  /// Ödem taraması: ani kilo artışı + hedef dışı INR
  /// (bkz. comorbidity_sync_service.dart).
  edema,
}

class InrAlert {
  final AlertSeverity severity;
  final InrAlertKind kind;

  /// Uyarıyı tetikleyen INR değeri.
  final double inrValue;

  /// Hedef aralık — yalnızca hedef dışı uyarılarında anlamlı.
  final TargetRange? targetRange;

  /// Son 24 saatteki kilo artışı (kg) — yalnızca [InrAlertKind.edema].
  final double? weightDeltaKg;

  /// Acil durum kişisi de bilgilendirilmeli mi?
  final bool notifyEmergencyContact;

  const InrAlert({
    required this.severity,
    required this.kind,
    required this.inrValue,
    this.targetRange,
    this.weightDeltaKg,
    this.notifyEmergencyContact = false,
  });
}

/// Yan etkiler için soyutlamalar — testte mock'lanır,
/// üretimde flutter_local_notifications / SMS intent'ine bağlanır.
abstract interface class NotificationGateway {
  /// Metin çağıran tarafından, seçili dilde hazırlanıp verilir — gateway
  /// dil bilmez.
  Future<void> showLocalAlert({
    required String title,
    required String body,
    required AlertSeverity severity,
  });
}

abstract interface class EmergencyGateway {
  Future<void> notifyContact(
    EmergencyContact contact, {
    required String title,
    required String body,
  });
}

/// Seçili dildeki çeviri paketini üreten geri çağrım. Servis dili
/// kendisi çözmez: uygulama açıkken kullanıcının seçtiği dil, arka plan
/// izolatında ise kayıtlı dil verilir (bkz. services/app_settings.dart).
typedef LocProvider = Future<Loc> Function();

class AlertService {
  final NotificationGateway _notifications;
  final EmergencyGateway _emergency;
  final LocProvider _loc;

  AlertService(this._notifications, this._emergency, this._loc);

  /// SAF FONKSİYON: Yeni bir INR kaydı için uyarı üretir (yan etkisiz,
  /// dilden bağımsız).
  InrAlert? evaluate(InrEntry entry, PatientProfile profile) {
    final zone = entry.zoneWith(
      criticalLow: profile.criticalLow,
      criticalHigh: profile.criticalHigh,
    );

    return switch (zone) {
      InrZone.criticalLow => InrAlert(
          severity: AlertSeverity.critical,
          kind: InrAlertKind.criticalLow,
          inrValue: entry.inrValue,
          targetRange: entry.targetRange,
          notifyEmergencyContact: true,
        ),
      InrZone.criticalHigh => InrAlert(
          severity: AlertSeverity.critical,
          kind: InrAlertKind.criticalHigh,
          inrValue: entry.inrValue,
          targetRange: entry.targetRange,
          notifyEmergencyContact: true,
        ),
      InrZone.belowRange => InrAlert(
          severity: AlertSeverity.warning,
          kind: InrAlertKind.belowRange,
          inrValue: entry.inrValue,
          targetRange: entry.targetRange,
        ),
      InrZone.aboveRange => InrAlert(
          severity: AlertSeverity.warning,
          kind: InrAlertKind.aboveRange,
          inrValue: entry.inrValue,
          targetRange: entry.targetRange,
        ),
      // Hedefteyken uyarı gerekmez.
      InrZone.inRange => null,
    };
  }

  /// Uyarıyı üretir VE dağıtır. Repository'ye kayıt sonrası çağrılır.
  Future<InrAlert?> processNewEntry(
      InrEntry entry, PatientProfile profile) async {
    final alert = evaluate(entry, profile);
    if (alert == null) return null;

    final loc = await _loc();
    final title = alertTitle(loc, alert);
    final body = alertMessage(loc, alert);

    await _notifications.showLocalAlert(
      title: title,
      body: body,
      severity: alert.severity,
    );

    final contact = profile.emergencyContact;
    if (alert.notifyEmergencyContact &&
        contact != null &&
        contact.notifyBySms) {
      await _emergency.notifyContact(contact, title: title, body: body);
    }
    return alert;
  }
}

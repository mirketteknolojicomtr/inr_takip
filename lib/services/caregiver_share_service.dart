/// Yakınla Paylaşım — hastanın güncel durumunu bir bakıcıya/yakınına
/// tek dokunuşla gönderir.
///
/// Kritik uyarıdaki otomatik SMS'ten (bkz. alert_service.dart) farkı:
/// bu, kullanıcının **kendi isteğiyle** gönderdiği periyodik bir durum
/// özetidir — "iyiyim, INR'm 2.4, ilaçlarımı aldım". Warfarin hastalarının
/// çoğu evde yalnız yaşayan yaşlılar olduğu için, uzaktaki bir çocuğun/
/// bakıcının düzenli bilgi alması tedavi uyumunu artırır.
///
/// Özet üretimi ([buildSummaryTr]) saf fonksiyondur: yan etkisi yok,
/// birim testi trivial. Gönderim [CaregiverShareGateway] arkasındadır.
library;

import '../l10n/domain_labels.dart';
import '../models/inr_entry.dart';
import '../models/patient_profile.dart';
import 'medication_service.dart';

/// Özetin nasıl gönderileceğini soyutlar — testte mock'lanır.
abstract interface class CaregiverShareGateway {
  /// Gönderim yüzeyi açıldıysa `true`. Kullanıcı son "Gönder" dokunuşunu
  /// kendisi yapar (bkz. sms_emergency_gateway.dart platform notu).
  Future<bool> share({required String phone, required String text});
}

class CaregiverShareService {
  final CaregiverShareGateway _gateway;

  const CaregiverShareService(this._gateway);

  /// SAF FONKSİYON: paylaşılacak metni üretir (verilen dilde).
  ///
  /// Yalnızca elde olan bilgiyi yazar — veri yoksa o satır hiç görünmez.
  /// "Veri yok" satırları özeti uzatıp okunmaz hâle getirir, ve alıcıya
  /// yanlış bir eksiklik hissi verir.
  String buildSummary(
    Loc loc, {
    required PatientProfile profile,
    InrEntry? latestInr,
    AdherenceSummary? adherence,
    MedicationDay? today,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final buffer = StringBuffer()
      ..writeln(loc.l10n.shareSummaryTitle(profile.name))
      ..writeln(loc.l10n.shareSummaryDate(loc.formats.date(at)));

    if (latestInr != null) {
      final zone = latestInr.zoneWith(
        criticalLow: profile.criticalLow,
        criticalHigh: profile.criticalHigh,
      );
      buffer
        ..writeln()
        ..writeln(loc.l10n.shareSummaryLastInr(
          loc.formats.inr(latestInr.inrValue),
          inrZoneLabel(loc, zone),
          loc.formats.date(latestInr.date),
        ))
        ..writeln(loc.l10n.shareSummaryTargetRange(
          loc.formats.inr(profile.targetRange.lower),
          loc.formats.inr(profile.targetRange.upper),
        ));
    } else {
      buffer
        ..writeln()
        ..writeln(loc.l10n.shareSummaryNoInr);
    }

    if (today != null && today.doses.isNotEmpty) {
      buffer.writeln(loc.l10n.shareSummaryTodayDose(
        MedicationLabels.mg(loc, today.totalMg),
        MedicationLabels.mg(loc, today.takenMg),
      ));
    }

    if (adherence != null && !adherence.isEmpty) {
      buffer.writeln(loc.l10n.shareSummaryAdherence(
        loc.formats.percent(adherence.percent),
        adherence.taken,
        adherence.scheduled,
      ));
    }

    buffer
      ..writeln()
      ..writeln(loc.l10n.shareSummaryFooter);

    return buffer.toString();
  }

  /// Özeti üretip [profile]'daki acil durum kişisine gönderir.
  ///
  /// Kişi tanımlı değilse [CaregiverShareResult.noContact] döner — sessizce
  /// hiçbir şey yapmamak, kullanıcıya "gönderildi" izlenimi verirdi.
  Future<CaregiverShareResult> shareWithContact(
    Loc loc, {
    required PatientProfile profile,
    InrEntry? latestInr,
    AdherenceSummary? adherence,
    MedicationDay? today,
    DateTime? now,
  }) async {
    final contact = profile.emergencyContact;
    if (contact == null || contact.phone.trim().isEmpty) {
      return CaregiverShareResult.noContact;
    }

    final text = buildSummary(
      loc,
      profile: profile,
      latestInr: latestInr,
      adherence: adherence,
      today: today,
      now: now,
    );

    final opened = await _gateway.share(phone: contact.phone, text: text);
    return opened
        ? CaregiverShareResult.opened
        : CaregiverShareResult.unavailable;
  }
}

enum CaregiverShareResult {
  /// Mesaj taslağı açıldı; göndermek kullanıcıya kaldı.
  opened,

  /// Profilde acil durum kişisi/telefonu yok.
  noContact,

  /// Cihazda mesaj gönderebilecek bir uygulama bulunamadı.
  unavailable,
}

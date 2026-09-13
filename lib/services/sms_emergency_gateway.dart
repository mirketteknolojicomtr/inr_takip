/// `url_launcher` ile `sms:` şemasını açan [EmergencyGateway] implementasyonu.
///
/// GERÇEKÇİLİK NOTU: Bu, mesajı Mesajlar uygulamasında ÖNCEDEN DOLDURULMUŞ
/// olarak açar; kullanıcının "Gönder"e basması gerekir, otomatik/sessiz
/// gönderim yapmaz. Android'in `SmsManager` ile gerçekten sessiz gönderim
/// mümkün olsa da, `SEND_SMS` Google Play'in "kısıtlı izinler" listesinde —
/// yalnızca varsayılan SMS/telefon uygulamaları onaylanıyor, bir INR takip
/// uygulaması bu izinle muhtemelen reddedilir. iOS'ta ise üçüncü parti
/// uygulamalardan sessiz SMS gönderimi için hiçbir genel API yok. Dolayısıyla
/// `sms:` URI'si, her iki platformda da gerçekten dağıtılabilir tek yol.
library;

import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../models/patient_profile.dart';
import 'alert_service.dart';
import 'caregiver_share_service.dart';

/// SAF FONKSİYON: platforma uygun `sms:` URI'sini kurar.
///
/// iOS'ta body parametresi "&" ile başlar (standart "?" Android içindir);
/// Apple'ın dokümante etmediği ama uzun süredir kabul ettiği bir kısayoldur.
/// Kritik uyarı ve yakınla paylaşım aynı kuralı kullanmalı — bu yüzden tek
/// yerde tutuluyor.
Uri buildSmsUri({
  required String phone,
  required String body,
  bool isIOS = false,
}) {
  final separator = isIOS ? '&' : '?';
  return Uri.parse('sms:$phone$separator' 'body=${Uri.encodeComponent(body)}');
}

/// Mesajlar uygulamasını önceden doldurulmuş metinle açar.
/// Açılamazsa `false` döner — çağıran kullanıcıyı bilgilendirebilir.
Future<bool> launchSmsDraft({
  required String phone,
  required String body,
}) async {
  final uri = buildSmsUri(phone: phone, body: body, isIOS: Platform.isIOS);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

class SmsEmergencyGateway implements EmergencyGateway {
  @override
  Future<void> notifyContact(
    EmergencyContact contact, {
    required String title,
    required String body,
  }) async {
    await launchSmsDraft(phone: contact.phone, body: '$title\n$body');
  }
}

/// Yakınla paylaşımın SMS implementasyonu — kritik uyarıyla aynı
/// `sms:` yolunu kullanır (bkz. [launchSmsDraft]).
class SmsCaregiverShareGateway implements CaregiverShareGateway {
  const SmsCaregiverShareGateway();

  @override
  Future<bool> share({required String phone, required String text}) =>
      launchSmsDraft(phone: phone, body: text);
}

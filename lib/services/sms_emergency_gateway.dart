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

class SmsEmergencyGateway implements EmergencyGateway {
  @override
  Future<void> notifyContact(EmergencyContact contact, InrAlert alert) async {
    final body = Uri.encodeComponent('${alert.titleTr}\n${alert.messageTr}');
    // iOS'ta sms: URI'sinde body parametresi "&" ile başlar (standart "?"
    // Android içindir); Apple'ın dokümante etmediği ama uzun süredir kabul
    // ettiği bir kısayoldur.
    final separator = Platform.isIOS ? '&' : '?';
    final uri = Uri.parse('sms:${contact.phone}$separator' 'body=$body');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Acil Durum NFC Yayın Servisi.
///
/// PLATFORM KISITI (önemli — kod yazmadan önce okunmalı):
///
/// iOS: Üçüncü parti uygulamalar CoreNFC ile yalnızca ÖN PLANDA, kullanıcının
/// başlattığı bir okuma oturumuyla (`NFCNDEFReaderSession`) etiket okuyabilir.
/// Apple, "cihaz kilitliyken pasif bir NFC etiketi gibi davranma" (host card
/// emulation) yeteneğini yalnızca kendi sistem servislerine (Apple Pay/
/// Wallet) açar; bu API üçüncü parti uygulamalara kapalıdır. Yani "kilit
/// ekranında NFC anteni açık tutup NDEF yayınlama" isteği iOS'ta karşılığı
/// olmayan bir taleptir — bunu yapan bir Flutter/Swift kodu yazmak, çalışıyor
/// gibi görünüp aslında hiçbir şey yapmayan bir kod üretir. Gerçekçi iOS
/// karşılığı: kullanıcıyı Sağlık uygulamasının yerleşik "Tıbbi Kimlik"
/// (Medical ID) özelliğine yönlendirmek — zaten kilit ekranından (Acil SOS
/// kaydırma) erişilebilir ve iOS'un resmi/desteklenen tek mekanizmasıdır.
///
/// Android: Host Card Emulation (`HostApduService`) ile bir NFC Forum
/// Type 4 Tag (NDEF) emüle etmek mümkündür. Bu servis OS tarafından
/// yönetilir; uygulama arka planda olsa bile (hatta kapalıyken bile, NFC
/// donanımı açık olduğu sürece) tetiklenir. API 33+'da servis XML'inde
/// `android:requireDeviceUnlock="false"` ile kilit ekranında da çalışır.
/// Gerçek HCE implementasyonu native tarafta yazılır
/// (android/app/src/main/kotlin/.../InrHceService.kt); bu dosya yalnızca
/// o servise payload ileten Dart tarafını içerir.
library;

import 'dart:io';

import 'package:flutter/services.dart';

import 'lock_screen_sync_service.dart';

/// Yayınlanacak NDEF içeriğini native tarafa ileten soyutlama —
/// testte mock'lanır.
abstract interface class NfcBroadcastGateway {
  Future<void> updateBroadcastPayload(String ndefText);
  Future<void> stopBroadcast();
}

class NfcEmergencyService {
  final NfcBroadcastGateway _gateway;

  NfcEmergencyService(this._gateway);

  /// SAF FONKSİYON: [payload]'dan, karşı cihazın NDEF metni olarak
  /// okuyacağı düz metni üretir. Native/IO bağımlılığı yok.
  String buildNdefText(LockScreenPayload payload) {
    final buffer = StringBuffer()
      ..writeln('ACİL TIBBİ BİLGİ')
      ..writeln('Hasta: ${payload.patientName}')
      ..writeln('İlaç: ${payload.medicationName} (antikoagülan)')
      ..writeln(payload.headlineTr);

    final contactName = payload.emergencyContactName;
    if (contactName != null && contactName.isNotEmpty) {
      buffer.writeln(
          'Acil kişi: $contactName ${payload.emergencyContactPhone ?? ''}');
    }
    return buffer.toString();
  }

  Future<void> sync(LockScreenPayload payload) =>
      _gateway.updateBroadcastPayload(buildNdefText(payload));

  Future<void> stop() => _gateway.stopBroadcast();
}

/// Android'de `MethodChannel` üzerinden HCE servisine payload ileten
/// implementasyon. iOS'ta çağrılırsa yukarıdaki kısıt nedeniyle açıkça
/// hata fırlatır — sessizce yutup "yayınlıyormuş gibi" davranmak, acil
/// durum özelliği için kabul edilemez bir hata modu.
class PlatformChannelNfcGateway implements NfcBroadcastGateway {
  static const _channel = MethodChannel('inr_takip/nfc_hce');

  @override
  Future<void> updateBroadcastPayload(String ndefText) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'Arka planda pasif NFC yayını yalnızca Android (HCE) üzerinde '
        'desteklenir. iOS için kullanıcıyı Sağlık > Tıbbi Kimlik akışına '
        'yönlendirin (bkz. dosya başındaki platform notu).',
      );
    }
    await _channel.invokeMethod<void>('updatePayload', {'text': ndefText});
  }

  @override
  Future<void> stopBroadcast() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('stop');
  }
}

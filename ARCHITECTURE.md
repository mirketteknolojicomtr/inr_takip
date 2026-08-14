# INR Takip — Mimari ve Entegrasyon Rehberi

Flutter/Dart ile, Model → Repository → Service → UI katmanlı, state management
çözümünden (Riverpod, Bloc, Provider) bağımsız bir çekirdek yapı.

## Katman Şeması

```
UI (Widgets)
   │  yalnızca Stream/Future tüketir
Services (AlertService, TrendService, PdfReportService, ReminderService)
   │  saf iş mantığı + soyut gateway'ler
Repositories (soyut arayüzler)
   │  InMemory → drift/sqflite → API : aynı arayüz
Models (InrEntry, VitaminKLog, PatientProfile)
```

## Dosyalar

| Dosya | Sorumluluk |
|---|---|
| `models/inr_entry.dart` | INR + doz + hedef aralık, `InrZone` bölge hesabı |
| `models/vitamin_k_log.dart` | Gıda kataloğu, porsiyon, göreli K yükü |
| `models/patient_profile.dart` | Acil kişi, ilaç saati (`nextDose`, geri sayım kaynağı), kritik eşikler |
| `repositories/repositories.dart` | Soyut arayüzler + reaktif (Stream) in-memory implementasyon |
| `services/alert_service.dart` | Akıllı uyarı: saf `evaluate()` + yan etkili `processNewEntry()` |
| `services/trend_service.dart` | 30 günlük trend verisi (bantlar dahil) + diyet-INR korelasyonu |
| `services/pdf_report_service.dart` | 3 aylık PDF tablo raporu (tek tuş paylaşım) |
| `services/reminder_service.dart` | Günlük bildirim planlama + `DoseCountdownWidget` |
| `ui/inr_trend_chart.dart` | fl_chart ile yeşil/kırmızı bantlı çizgi grafik |

## Temiz kod kararları

- **Dependency Inversion:** UI ve servisler somut sınıfa değil arayüze bağlı.
  SQLite'a geçiş = tek DI satırı değişikliği.
- **Saf iş mantığı:** `AlertService.evaluate()` ve `TrendService` yan etkisiz;
  birim test yazmak trivial.
- **Yan etkiler gateway arkasında:** Bildirim/SMS `NotificationGateway`,
  `EmergencyGateway`, `ReminderScheduler` ile soyutlandı → mock'lanabilir.
- **Tarihsel doğruluk:** Hedef aralık her `InrEntry`'ye gömülür; doktor aralığı
  değiştirse bile eski kayıtlar doğru yorumlanır.
- **Kritik akış tek yerde:** `_onNewInrEntry` → repo.upsert → alert.process.

## Riverpod ile örnek bağlama

```dart
final inrRepoProvider = Provider<InrRepository>((_) => InMemoryInrRepository());
final kRepoProvider = Provider<VitaminKRepository>((_) => InMemoryVitaminKRepository());

final alertServiceProvider = Provider((ref) => AlertService(
      LocalNotificationGateway(),   // flutter_local_notifications sarmalayıcısı
      SmsEmergencyGateway(),        // url_launcher: sms intent
    ));

final trendProvider = FutureProvider((ref) =>
    TrendService(ref.watch(inrRepoProvider), ref.watch(kRepoProvider))
        .buildTrend(days: 30));

/// Yeni ölçüm akışı (Controller/Notifier içinde):
Future<void> addMeasurement(InrEntry entry) async {
  await ref.read(inrRepoProvider).upsert(entry);
  final profile = await ref.read(profileRepoProvider).getProfile();
  if (profile != null) {
    await ref.read(alertServiceProvider).processNewEntry(entry, profile);
  }
}
```

## pubspec bağımlılıkları

```yaml
dependencies:
  fl_chart: ^0.68.0
  pdf: ^3.11.0
  printing: ^5.13.0
  flutter_local_notifications: ^17.0.0
  # kalıcı depolama için: drift veya sqflite
```

## Önemli not

Uyarı eşikleri (1.5 / 4.5) ve hedef aralık varsayılanları örnektir; gerçek
uygulamada hekim tarafından hastaya özel yapılandırılmalı, uygulama içinde
"tıbbi tavsiye yerine geçmez" ibaresi ve acil durum yönlendirmesi bulunmalıdır.

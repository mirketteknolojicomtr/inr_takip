# INR Takip — Mimari ve Entegrasyon Rehberi

Flutter/Dart ile, **Model → Repository → Service → UI** katmanlı, state
management çözümünden (Riverpod, Bloc, Provider) bağımsız bir çekirdek yapı.
Bağlama (wiring) `main.dart` içinde elle yapılır; DI kütüphanesi yoktur.

## Katman Şeması

```
UI (Widgets)
   │  yalnızca Stream/Future tüketir; platform paketi görmez
Services   AlertService · TrendService · MedicationService
           MedicationReminderService · PdfReportService · EntitlementService
           ComorbiditySyncService · LockScreenSyncService · NfcEmergencyService
           InrOcrService · CloudSyncService · CaregiverShareService
           FirebaseAuthService
   │  saf iş mantığı + soyut gateway'ler
Repositories   soyut arayüzler : InMemory* (test) ⇄ Sqflite* (üretim)
   │
Models    InrEntry · Medication · VitaminKLog · PatientProfile
```

Her platform bağımlılığı bir **gateway** arkasındadır; iş mantığı somut
paketi (purchases_flutter, health, home_widget, flutter_local_notifications,
url_launcher, MethodChannel) hiç görmez:

| Gateway (soyut) | Üretim implementasyonu | Paket |
|---|---|---|
| `NotificationGateway` | `LocalNotificationGateway` | flutter_local_notifications |
| `EmergencyGateway` | `SmsEmergencyGateway` | url_launcher (`sms:`) |
| `ReminderScheduler` | `LocalReminderScheduler` | flutter_local_notifications + timezone |
| `EntitlementGateway` | `RevenueCatEntitlementGateway` / `FakeEntitlementGateway` | purchases_flutter |
| `HealthMetricsGateway` | `HealthPackageMetricsGateway` | health |
| `LockScreenGateway` | `HomeWidgetLockScreenGateway` | home_widget |
| `NfcBroadcastGateway` | `PlatformChannelNfcGateway` | MethodChannel → Kotlin HCE |
| `CloudGateway` | `FirestoreCloudGateway` | cloud_firestore |
| `CaregiverShareGateway` | `SmsCaregiverShareGateway` | url_launcher (`sms:`) |

## Dosyalar

### Modeller (saf Dart, platform bağımsız)

| Dosya | Sorumluluk |
|---|---|
| `models/inr_entry.dart` | INR + doz + kayda gömülü hedef aralık, `InrZone` bölge hesabı |
| `models/medication.dart` | İlaç planı: miktar (mg/tablet), sıklık (`isDueOn`, `doseForDay`, `nextDose`), alım kaydı (`DoseIntake`) |
| `models/vitamin_k_log.dart` | Gıda kataloğu (`VitaminKFood`), porsiyon çarpanı, göreli K yükü |
| `models/patient_profile.dart` | Acil kişi, hedef aralık, kritik eşikler, ilaç saati |

### Repository katmanı

| Dosya | Sorumluluk |
|---|---|
| `repositories/repositories.dart` | 5 soyut repository arayüzü (`InrRepository`, `VitaminKRepository`, `ProfileRepository`, `MedicationRepository`, `DoseIntakeRepository`) + `DeletionLog` (silme defteri) + reaktif (Stream) in-memory implementasyonlar |
| `repositories/sqflite_repositories.dart` | Kalıcı depolama. `AppDatabase` tek paylaşılan bağlantı, şema **v3** (`inr_entries`, `vitamin_k_logs`, `patient_profile`, `medications`, `dose_intakes`, `deleted_records` + v1→v2→v3 migration). Her satır: JSON blob + sorgulanabilir `date` sütunu. `delete()` ile mezar taşı aynı transaction'da yazılır |

Üretimde `main.dart` **yalnızca `Sqflite*`** implementasyonlarını bağlar;
`InMemory*` testler ve prototip içindir.

### Servisler

| Dosya | Sorumluluk |
|---|---|
| `services/alert_service.dart` | Saf `evaluate()` + yan etkili `processNewEntry()`; kritik eşikte bildirim + acil kişiye SMS |
| `services/trend_service.dart` | 30 günlük trend (bantlar + `inRangePercent`, TTR benzeri metrik) ve `correlateDietWithInr()` — 72 saatlik K yükü ↔ INR düşüşü |
| `services/medication_service.dart` | `buildDay()` günün doz tablosu, `adherence()` uyum oranı, `suggestedDose()` ölçüm formu ön-doldurma, `primaryAnticoagulant()` |
| `services/reminder_service.dart` | Sıklığı bildirim planına çevirir (günlük / haftalık / tek seferlik) |
| `services/local_reminder_scheduler.dart` | `ReminderScheduler`'ın flutter_local_notifications + timezone implementasyonu |
| `services/local_notification_gateway.dart` | `NotificationGateway` implementasyonu; Android 13+ POST_NOTIFICATIONS izni |
| `services/sms_emergency_gateway.dart` | `sms:` URI ile önceden doldurulmuş mesaj (sessiz gönderim **yok** — gerekçe dosyada) |
| `services/pdf_report_service.dart` | 3 aylık PDF tablo raporu |
| `services/entitlement_service.dart` | Premium yetkilendirme; `kAlwaysFreeFeatures` güvenlik sınırını kodda sabitler |
| `services/revenuecat_entitlement_gateway.dart` | Tek mağaza-bağımlı dosya |
| `services/inr_ocr_service.dart` | Ham OCR metninden INR değeri çıkaran saf regex mantığı (kamera/ML Kit bağımlılığı yok) |
| `services/comorbidity_sync_service.dart` | `EdemaRiskEvaluator`: son 24 saatte >1,5 kg kilo artışı **ve** hedef dışı INR → kritik uyarı. Nabız arayüzde var, kuralda değil |
| `services/health_package_metrics_gateway.dart` | HealthKit / Health Connect okuma; izin yoksa boş liste → sessizce değerlendirme yapılmaz |
| `services/health_background_observer.dart` | iOS `HKObserverQuery` köprüsü (`inr_takip/health_observer` channel) |
| `services/comorbidity_background_scheduler.dart` | Android WorkManager periyodik görevi (6 saat) |
| `services/lock_screen_sync_service.dart` | `LockScreenPayload.build()` saf fonksiyonu + kayıtlı **her** acil yüzeye yayın; INR akışına abone (poll yok), bir yüzeyin hatası ötekini düşürmez |
| `services/nfc_emergency_service.dart` | `buildNdefText()` saf fonksiyonu; `LockScreenGateway`'i implemente eder → widget ile aynı akışa takılır |
| `services/caregiver_share_service.dart` | `buildSummaryTr()` saf fonksiyonu: son INR + bugünkü doz + 7 günlük uyum özeti |
| `services/firebase_auth_service.dart` | E-posta/parola oturumu |
| `services/app_settings.dart` | Cihaz tercihleri (dil) + `resolveLoc()`, `resolveSupportedLocale()` |
| `services/cloud_sync_service.dart` | `CloudGateway` arayüzü + çek/gönder/sil birleştirme kuralı (aşağıda) |
| `services/firestore_cloud_gateway.dart` | Tek Firestore-bağımlı dosya; `WriteBatch` ile toplu yazma (400'lük parçalar) |

### UI

| Dosya | Sorumluluk |
|---|---|
| `l10n/app_*.arb` | Çeviri kaynakları (şablon: `app_tr.arb`) |
| `l10n/formats.dart` | `AppFormats`: yerel sayı/tarih/saat/gün/ağırlık biçimi |
| `l10n/domain_labels.dart` | `Loc`, `context.loc` ve enum → metin eşlemeleri |
| `ui/language_picker.dart` | Profil ekranındaki dil seçici |
| `ui/theme.dart` | Tasarım tokenları, `ZoneColors`, `clampTextScale`, `EmptyState` |
| `ui/today_screen.dart` | "Bugün": sonraki doz → INR durumu → günün alımları |
| `ui/medications_screen.dart` | İlaç listesi, uyum özeti, ücretsiz katman ilaç limiti |
| `ui/medication_editor_screen.dart` | Doz ve sıklık formu; sıklık seçimi formu değiştirir |
| `ui/medication_card.dart` | `NextDoseCard` (geri sayım + miktar), `TodayDosesCard`, `WeeklyDoseStrip` |
| `ui/history_screen.dart` | Trend, ölçüm listesi, PDF, diyet içgörüleri |
| `ui/add_measurement_dialog.dart` | Ölçüm girişi; doz ön-dolu, aksiyonlar Steady-Touch hedefi |
| `ui/vitamin_k_dialog.dart` | K vitamini öğün girişi: katalog + porsiyon + tarih |
| `ui/inr_trend_chart.dart` | fl_chart bantlı çizgi grafik |
| `ui/inr_ambient_hero.dart` | Güncel INR kartı; zemin rengi klinik bölgeden, renk tek başına bırakılmaz |
| `ui/inr_scan_screen.dart` | Kamera + ML Kit canlı OCR akışı |
| `ui/steady_touch.dart` | `TremorFilter` (EMA, ~200 ms) + mıknatıslı hedefler + tap cooldown |
| `ui/safe_touch.dart` | Tek dokunuş = TTS anonsu, çift dokunuş = onay |
| `ui/auth_screen.dart` · `ui/paywall_screen.dart` · `ui/premium_gate.dart` · `ui/profile_screen.dart` | Oturum, abonelik, kilit bileşenleri, profil |

## Erişilebilirlik: kod düzeyinde kararlar

Hedef kitle ağırlıklı olarak 60+ warfarin hastası. Bu, tasarım notu değil
uygulanan kısıt:

- **`theme.dart`** — gövde metni ≥ 16sp; birincil buton ≥ 56dp (Material'ın
  48dp minimumunun üstünde); sistem yazı ölçeği `clampTextScale` ile 1.0–1.6
  arasına sıkıştırılır (kartlar taşmasın); renk yalnızca klinik anlam taşır
  ve **asla tek başına bilgi taşımaz** (renk körlüğü).
- **`steady_touch.dart`** — el titremesi kompanzasyonu. Ham pointer örnekleri
  tek-kutuplu alçak geçiren filtreden (EMA, zaman sabiti ~200 ms) geçirilir;
  kritik butonlar "mıknatıslı hedef"tir (temel yarıçap + hareket yönüne göre
  büyüyen yönsel bonus); art arda çok hızlı gelen ikinci tetikleme (tremor
  sıçraması) `tapCooldown` ile yutulur.
- **`safe_touch.dart`** — yanlışlıkla dokunma koruması: tek dokunuş işlemi
  çalıştırmaz, TTS ile ne yapacağını okur; işlem çift dokunuş + haptik ile
  onaylanır.

Regresyon notu: `SteadyTouchArea` ham pointer olaylarını dinlediği için,
hedefin içindeki butonun kendi `onPressed`'i ile birlikte "Kaydet" iki kez
koşuyordu (`Navigator.pop` iki kez → siyah ekran). `steady_touch_dialog_test.dart`
bunu kilitler; mıknatıs bölgesi bu yüzden yalnızca aksiyon satırını kapsar.

## Arka plan çalışması ve pil

| Akış | iOS | Android |
|---|---|---|
| Ödem taraması | `HKObserverQuery` + `enableBackgroundDelivery` — **olay bazlı**, yalnızca yeni kilo örneği yazıldığında uyanır (`AppDelegate.swift`) | WorkManager periyodik görev (6 saat; OS tabanı ~15 dk) |
| İlaç hatırlatıcısı | flutter_local_notifications, cihaz saat dilimi | Aynı + `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`; izin yoksa `inexactAllowWhileIdle`'a düşer |
| Yeniden başlatma | — | `ScheduledNotificationBootReceiver` planlı bildirimleri geri yükler |

WorkManager görevleri **ayrı bir Dart izolatında** çalışır ve ana uygulamanın
state'ini göremez. Bu yüzden `comorbidityCallbackDispatcher` bağımlılıkları
sıfırdan kurar ve `SqfliteInrRepository` kullanır (`InMemory*` değil) — her
izolat aynı fiziksel sqlite dosyasını açtığı için uygulama kapalıyken de son
INR kaydı doğru okunur.

## Acil durum yüzeyi: widget + NFC

`LockScreenSyncService` INR akışına abone olur, `LockScreenPayload.build()`
saf fonksiyonuyla metni üretir ve `home_widget` üzerinden paylaşılan depoya
yazar:

- **iOS** → App Group (`group.com.mirketteknoloji.inrtakip`) → WidgetKit
  uzantısı (`ios/InrEmergencyWidgetExtension/`).
- **Android** → SharedPreferences (`HomeWidgetPreferences`) → Glance widget
  (`InrEmergencyGlanceWidget.kt`).

Her iki yüzey de aynı `LockScreenSyncService` akışına bağlıdır: servis bir
gateway **listesi** tutar, tek abonelikle beslenir ve bir gateway hata
verirse (NFC donanımı yok, widget kaldırılmış) diğerleri yayına devam eder.
NFC kartı ücretsiz katmanda da çalışır (acil durum kartı `kAlwaysFreeFeatures`
içindedir); premium widget, abonelik doğrulanınca `addGateway()` ile aynı
akışa eklenir.

Aynı veri Android'de **Host Card Emulation** ile pasif NFC etiketi olarak
yayınlanır: `InrHceService.kt` standart bir NFC Forum Type 4 Tag durum
makinesidir (SELECT AID / SELECT File / READ BINARY), `apduservice.xml`
içinde `requireDeviceUnlock="false"` ile kilit ekranında da çalışır, payload
`inr_takip/nfc_hce` MethodChannel'ından güncellenir.

**Platform gerçeği (kod yazmadan önce okunmalı):** iOS'ta üçüncü parti
uygulamalar için HCE karşılığı **yoktur** — Apple bunu yalnızca Wallet/Apple
Pay'e açar. `PlatformChannelNfcGateway` iOS'ta çağrılırsa sessizce yutmak
yerine `UnsupportedError` fırlatır; acil durum özelliğinde "çalışıyormuş gibi
görünüp hiçbir şey yapmamak" kabul edilemez bir hata modudur. iOS'un
desteklenen karşılığı kullanıcıyı Sağlık > Tıbbi Kimlik akışına yönlendirmektir.

## Yerelleştirme (18 dil hedefi)

### Kural: alan katmanı metin üretmez

Modeller ve servisler kullanıcı metni döndürmez — **tür + sayı** döndürür:

| Önce | Sonra |
|---|---|
| `InrAlert.titleTr/messageTr` | `InrAlertKind` + `inrValue` + `targetRange` |
| `VitaminKFood.labelTr` | etiketsiz enum, ad çeviriden |
| `Medication.frequencyLabelTr` | `MedicationLabels.frequencyLabel(loc)` |
| `Medication.tabletLabel(mg)` → "1 tablet" | `tabletFraction(mg)` → "1" |
| `PremiumFeature.labelTr` | etiketsiz enum |
| `kAlwaysFreeFeatures` (String listesi) | `AlwaysFreeFeature` enum listesi |
| `DietInsight.messageTr` | `logs` + `inrDelta` + `kLoadBefore` |
| `formatMg()` | `AppFormats.decimal()` (yerel ondalık ayracı) |

Kazanç yalnızca çeviri değil: `AlertService.evaluate()` artık dilden
bağımsız olduğu için 18 dilde tek testle doğrulanır, ve güvenlik sınırı
(`kAlwaysFreeFeatures`) metin karşılaştırması yerine **tür** karşılaştırması
olduğundan bir çeviri hatasıyla kayamaz.

### İki katman: cümleler ve değerler

| | Sorumluluk | Kaynak |
|---|---|---|
| `AppLocalizations` (gen_l10n) | cümleler | `lib/l10n/app_*.arb` |
| `AppFormats` | sayı, tarih, saat, gün adı, ağırlık | `intl` + CLDR |

İkisi `Loc` içinde birlikte taşınır; widget ağacında `context.loc`,
ağaç dışında (bildirim, PDF, NFC, SMS) `Loc.forLocale(locale)`.

Gün adlarını ve saat biçimini ARB'ye elle yazmak yerine CLDR'den almak
18 dil için hem daha az iş hem daha doğrudur: "Pzt"/"Mon"/"月" ve
12/24 saat farkı zaten CLDR verisinde vardır.

### Ölçü birimi

Kilo HealthKit/Health Connect'ten **her zaman kilogram** okunur; ödem eşiği
(1,5 kg) da kg cinsindendir. Yalnızca *gösterim* çevrilir — ABD yerel
ayarında pound. Böylece klinik eşik tek birimde kalır ve dönüşüm hatası
riski gösterimle sınırlıdır.

### Dil kaynağı ve arka plan

Seçili dil `app_settings` tablosunda (sqflite, şema v4) tutulur — profilde
değil, çünkü dil cihazın tercihidir ve buluta senkronlanmamalıdır. Bildirim
ve ödem taraması **arka plan izolatında** çalışır ve orada widget ağacı
yoktur; `resolveLoc()` aynı sqlite dosyasından okuyarak orada da doğru dili
verir. `main()` açılışta `initializeDateFormatting()` çağırır, aksi hâlde
Türkçe dışı bir dilde ilk `DateFormat` çağrısı `LocaleDataException` atar.

Dil değişimi `AppLocaleController` (ValueNotifier) üzerinden yayılır:
yalnızca `MaterialApp` yeniden kurulur, ekranların state'i korunur —
kullanıcı formun ortasında dil değiştirebilir.

**Bildirim metinleri planlama anında sabitlenir.** Kullanıcı dili
değiştirdiğinde `MedicationReminderService.syncAll` yeniden planlar; Android
bildirim *kanalı* adı ise bir kez oluşturulduğu için eski dilde kalır (kanalı
yeniden adlandırmak silip kurmayı, o da kullanıcının kanal ayarlarını
sıfırlamayı gerektirir — daha kötü bir takas).

### Dil seçici

Profil ekranındaki liste dil adlarını **kendi dillerinde** gösterir
("Deutsch", "日本語"): yanlış dile düşen kullanıcı, anlamadığı bir listede
kendi dilini yine de tanıyabilmelidir.

## Bulut senkronu (premium)

Kapsam: profil, INR ölçümleri, ilaç planı. `DoseIntake` bilinçli olarak
dışarıda — günde birkaç satır üretir, klinik değeri düşüktür.

Her döngü üç adımdır:

1. **Çek** — bulutta olup yerelde olmayan kayıtlar eklenir. Yereldekilerin
   üzerine yazılmaz (bu cihazdaki düzenleme kaybolmamalı) ve **silme
   defterindeki** id'ler atlanır.
2. **Gönder** — tüm yerel kayıtlar buluta yazılır.
3. **Sil** — silme defterindeki kayıtlar buluttan silinir; defter yalnızca
   bulut silmesi başarılıysa temizlenir.

**Neden silme defteri (tombstone) var:** yerelde bir kaydın *yokluğu* tek
başına "silindi" demek değildir — başka cihazın yeni eklediği kayıt da
yerelde yoktur. İkisi ancak açık bir silme kaydıyla ayırt edilir. Defter
olmadan, silinen bir ölçüm sonraki senkronda geri gelirdi; bu regresyon
`cloud_sync_service_test.dart` ile kilitlenmiştir. Defter satırı, silme ile
**aynı sqlite transaction'ında** yazılır (`SqfliteDeletionLog`), böylece
ikisi hiçbir zaman ayrışmaz.

Servis hata fırlatmaz: bulut erişilemezken uygulama yerel veriyle tam
işlevle çalışır.

## Temiz kod kararları

- **Dependency Inversion:** UI ve servisler somut sınıfa değil arayüze bağlı.
  Depolama veya mağaza sağlayıcısı değişimi = tek DI satırı.
- **Saf iş mantığı:** `AlertService.evaluate()`, `TrendService`,
  `MedicationService.buildDay/adherence`, `InrOcrService.extractInrValue`,
  `LockScreenPayload.build`, `NfcEmergencyService.buildNdefText`,
  `TremorFilter` — hepsi yan etkisiz; birim testi trivial.
- **Tarihsel doğruluk:** Hedef aralık her `InrEntry`'ye gömülür; doktor aralığı
  değiştirse bile eski kayıtlar doğru yorumlanır.
- **Kritik akış tek yerde:** `_addMeasurement` → `repo.upsert` →
  `alert.processNewEntry` → `_refreshTrend`.
- **Paywall iş mantığında değil, kenarda:** Servisler premium bilmez; kilit
  kararı UI'da `EntitlementService.has()` / `ensurePremium()` ile verilir.
  Güvenlik özellikleri hiçbir koşulda kilitlenmez — `entitlement_test.dart`.
- **Premium katman = maliyet katmanı:** Bulut senkronu, sağlık taraması ve
  widget senkronu yalnızca abone olduğunda başlar (`_startPremiumServices`).
  Ücretsiz kullanıcı tamamen yerel çalışır ve sunucu maliyeti üretmez.
- **Sıklık modelde, platform serviste:** "Gün aşırı", "haftalık şema"
  kuralları `Medication`'da saf Dart; bildirim API'sinin tekrar kuralları
  `MedicationReminderService`'te.
- **Dürüst platform sınırları:** Sessiz SMS (`sms_emergency_gateway.dart`),
  iOS NFC yayını (`nfc_emergency_service.dart`) ve HealthKit arka plan
  tetikleyicileri (`comorbidity_sync_service.dart`) için neyin mümkün
  olmadığı dosya başlarında gerekçesiyle belgelenmiştir.

## Testler

```bash
flutter test                                    # birim + widget
flutter test integration_test/app_test.dart -d <device-id>   # uçtan uca
```

| Test | Kapsam |
|---|---|
| `alert_service_test.dart` | Kritik eşik / hedef dışı uyarı mantığı |
| `medication_test.dart` | `isDueOn`, `doseForDay`, `nextDose` saf mantığı |
| `medication_service_test.dart` | Günün tablosu + uyum oranı |
| `reminder_service_test.dart` | Sıklık → bildirim tipi eşlemesi |
| `entitlement_test.dart` | **Güvenlik özelliklerinin paywall'a takılmaması** |
| `add_measurement_dialog_test.dart` | Doz ön-dolumu, kaydet tek sefer koşar |
| `steady_touch_dialog_test.dart` | Çift tetikleme regresyonu (siyah ekran) |
| `paywall_screen_test.dart` | Paywall kapanınca ekran boşalmamalı |
| `ui_smoke_test.dart` | Ekranların gerçekten çizilmesi |
| `cloud_sync_service_test.dart` | Birleştirme kuralı: üzerine yazmama, silme defteri, hortlama regresyonu |
| `caregiver_share_service_test.dart` | Özet metni ve kişi yokken davranış |
| `vitamin_k_dialog_test.dart` | Öğün kaydı üretimi, iptal, "Diğer" doğrulaması |
| `l10n_test.dart` | Her dilde her enum'ın etiketi var mı; biçim ve yerel ayar çözümleme |
| `language_switch_test.dart` | Dil değişimi ekrana yansıyor mu (sabit dize sızıntısı) |
| `integration_test/app_test.dart` | Gerçek engine'de uçtan uca; widget testlerinin sahte rasterizer'ının göremediği çizim hataları |

## Riverpod ile örnek bağlama

Proje elle DI kullanıyor; bir state management katmanı eklenecekse
arayüzler zaten uygundur:

```dart
final inrRepoProvider = Provider<InrRepository>((_) => SqfliteInrRepository());
final kRepoProvider = Provider<VitaminKRepository>((_) => SqfliteVitaminKRepository());

final alertServiceProvider = Provider((ref) => AlertService(
      LocalNotificationGateway(),
      SmsEmergencyGateway(),
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

## Platform yapılandırması

**Android** (`AndroidManifest.xml`, `build.gradle.kts`) — `minSdk 26`
(Health Connect gereği). İzinler: `health.READ_WEIGHT`,
`health.READ_HEART_RATE`, `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`,
`USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `com.android.vending.BILLING`,
`NFC`. Bildirilen bileşenler: `InrHceService`, `InrEmergencyGlanceWidget`,
flutter_local_notifications boot receiver'ları.

**iOS** — `Runner.entitlements`: App Group + `developer.healthkit` +
`healthkit.background-delivery`. `Info.plist`:
`NSHealthShareUsageDescription` ve `NSCameraUsageDescription` (OCR ekranı
kamera açar; anahtar olmadan iOS uygulamayı anında sonlandırır).
`AppDelegate.swift` plugin kaydını `didFinishLaunchingWithOptions` içinde
senkron yapar; Storyboard tabanlı kurulumda yeni `FlutterImplicitEngineDelegate`
callback'i hiç tetiklenmediği ve sqflite dahil hiçbir plugin kayıt olamadığı
için (ilk channel çağrısında `MissingPluginException`) bu bilinçli bir seçimdir.

## Önemli not

Uyarı eşikleri (1.5 / 4.5) ve hedef aralık varsayılanları örnektir; gerçek
kullanımda hekim tarafından hastaya özel yapılandırılmalı, uygulama içinde
"tıbbi tavsiye yerine geçmez" ibaresi ve acil durum yönlendirmesi bulunmalıdır.

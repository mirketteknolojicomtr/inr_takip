# 🩸 INR Takip

Warfarin kullanan hastalar için INR ölçümü, doz, ilaç planı ve K vitamini
takibi yapan, temiz mimarili bir **Flutter** uygulaması.

> ⚠️ **Tıbbi uyarı:** Eşik değerleri (INR < 1.5 / > 4.5) ve hedef aralıklar
> örnektir; gerçek kullanımda hekim tarafından hastaya özel ayarlanmalıdır.
> Uygulama tıbbi tavsiye yerine geçmez.

## ✨ Özellikler

### Takip ve kayıt

- **INR & Doz Geçmişi** — tarih, INR değeri, günlük doz (mg) ve kayda gömülü
  hedef aralık (doktor aralığı değişse bile tarihsel doğruluk korunur)
- **30 Günlük Trend Grafiği** — fl_chart ile yeşil (güvenli) / sarı / kırmızı
  (riskli) bantlı çizgi grafik + **aralıkta kalma yüzdesi** (TTR benzeri metrik)
- **Kamerayla INR okuma (OCR)** — ölçüm cihazının ekranını kameraya tutun;
  ML Kit metni okur, saf regex mantığı 2.0–5.0 bandındaki değeri ayıklayıp
  (saat, pil yüzdesi gibi sayıları eleyerek) ölçüm formunu doldurur
- **PDF Rapor** — doktor viziti için tek tuşla 3 aylık INR & doz tablosu
- **K Vitamini / Diyet Günlüğü** — hazır gıda kataloğu (ıspanak, brokoli…),
  üç kademeli porsiyon ve tarih seçimiyle iki dokunuşta öğün kaydı; ölçümden
  önceki 72 saatin K yükü INR düşüşleriyle eşleştirilip içgörü üretilir.
  Kayıt tutmak ücretsizdir, içgörüler premium

### İlaç planı

- **Doz ve Sıklık** — her ilaç için tablet gücü, alım saatleri ve sıklık
  (her gün / gün aşırı / belirli günler / **haftalık şema**). Warfarin dozu
  günden güne değişebildiği için haftalık şema her gün için ayrı mg tutar;
  ana ekranda "5 mg · 1 tablet" ve haftalık şerit olarak görünür
- **Hatırlatıcı** — her alım saati için doz bilgisiyle bildirim
  ("Coumadin — 2,5 mg (½ tablet)") + canlı geri sayım; cihaz yeniden
  başlatıldığında planlar otomatik geri yüklenir
- **Alım Takibi & Uyum** — "Aldım / Atladım" kaydı ve son 7 günlük uyum oranı
- **Doz ön-dolumu** — yeni ölçüm eklerken doz alanı ilaç planından doldurulur

### Güvenlik (kalıcı ücretsiz)

- **Akıllı Uyarı Sistemi** — kritik eşik aşımında yerel bildirim + acil durum
  kişisine SMS taslağı (gateway soyutlamasıyla)
- **Acil Durum Kartı (widget)** — ana/kilit ekranında son INR, ilaç ve acil
  kişi bilgisi; iOS'ta WidgetKit, Android'de Glance
- **Acil Durum NFC Yayını (Android)** — telefon, Host Card Emulation ile pasif
  bir NFC etiketi gibi davranır: sağlık ekibi telefonu okutunca "warfarin
  kullanıyor, son INR şu, acil kişi bu" bilgisini alır — uygulama kapalıyken,
  kilit ekranında bile. Yayınlanan metin her yeni INR kaydında kendiliğinden
  tazelenir. *(iOS'ta karşılığı yoktur; gerekçe aşağıda.)*
- **Ödem Taraması** — Apple Health / Health Connect'ten kilo okunur; son
  24 saatte **1,5 kg'dan fazla ani artış** (sıvı birikmesi belirtisi) **ve**
  hedef dışı INR birlikte görülürse kritik uyarı üretilir. Nabız okuma
  arayüzde hazır, henüz tetikleme kuralına dahil değil

### Erişilebilirlik — 60+ hastalar için mühendislik

Bu bir slogan değil, kodda uygulanan kısıt (bkz. [ARCHITECTURE.md](ARCHITECTURE.md)):

- **Steady-Touch** — el titremesi (tremor) kompanzasyonu: parmak pozisyonu
  alçak geçiren filtreyle (EMA, ~200 ms) yumuşatılır, kritik butonlar
  "mıknatıslı hedef" olur, tremor sıçramasından doğan ikinci tetikleme yutulur
- **Safe-Touch** — tek dokunuş işlemi çalıştırmaz, TTS ile ne yapacağını
  sesli okur; işlem çift dokunuş + haptik ile onaylanır
- Gövde metni ≥ 16sp, birincil butonlar ≥ 56dp, sistem yazı ölçeği 1.0–1.6
  arasına sıkıştırılır, renk asla tek başına bilgi taşımaz (renk körlüğü)

### Diller

- **18 dil hedefi** — ABD/Kanada, Avrupa, Çin, Avustralya, Japonya, G. Kore
  ve Türki cumhuriyetler. **Tamamlanan: Türkçe ve İngilizce.**
- Sayı, tarih, saat ve gün adları yerel ayardan gelir: "2,5 mg" / "2.5 mg",
  "19:00" / "7:00 PM", "Pzt" / "Mon"
- **Ağırlık birimi otomatik** — ABD'de pound, diğer her yerde kilogram.
  Ödem eşiği (1,5 kg) içeride hep kg kalır; yalnızca gösterim çevrilir
- Profil ekranından dil seçilebilir; liste dilleri kendi dillerinde gösterir
- Bildirimler ve acil NFC kartı da seçili dilde üretilir

### Hesap, yedek ve paylaşım

- **Firebase Authentication** (e-posta/parola)
- **Bulut yedek & çoklu cihaz** — profil, INR ölçümleri ve ilaç planı
  `users/{uid}` ağacında yedeklenir; yeni cihazda oturum açınca geri yüklenir.
  Yerel sqflite kaynak-doğruluktur, bulut erişilemezken uygulama tam çalışır
- **Yakınla paylaşım** — son INR, bugünkü doz ve 7 günlük uyum oranından
  oluşan durum özetini tek dokunuşla yakınınıza gönderin
- **Abonelik (Premium)** — RevenueCat üzerinden; güvenlik özellikleri
  **her zaman ücretsiz** kalır (bkz. [Monetizasyon](#-monetizasyon))

## 🏗 Mimari

```
UI (Widgets)
   │  yalnızca Stream/Future tüketir; platform paketi görmez
Services   AlertService · TrendService · MedicationService · PdfReportService
           ComorbiditySyncService · LockScreenSyncService · EntitlementService …
   │  saf iş mantığı + soyut gateway'ler
Repositories   soyut arayüzler : InMemory* (test) ⇄ Sqflite* (üretim)
   │
Models    InrEntry · Medication · VitaminKLog · PatientProfile
```

Her platform bağımlılığı (bildirim, SMS, mağaza, sağlık verisi, widget, NFC)
bir gateway arkasındadır. Detaylar ve karar gerekçeleri:
[ARCHITECTURE.md](ARCHITECTURE.md).

## 📁 Proje Yapısı

```
lib/
├── main.dart                      # Giriş + manuel DI + AuthGate + sekme kabuğu
├── dev_preview.dart               # Oturumsuz geliştirme girişi (release'e girmez)
├── firebase_options.dart          # flutterfire configure çıktısı
├── config/
│   └── revenuecat_config.dart     # Mağaza anahtarları (--dart-define)
├── l10n/
│   ├── app_tr.arb                 # Şablon dil (360 anahtar)
│   ├── app_en.arb                 # İngilizce
│   ├── formats.dart               # Sayı/tarih/saat/gün/ağırlık biçimi
│   └── domain_labels.dart         # Loc + enum → metin eşlemeleri
├── models/
│   ├── inr_entry.dart             # INR + doz + hedef aralık, InrZone
│   ├── medication.dart            # İlaç, doz miktarı, sıklık, alım kaydı
│   ├── vitamin_k_log.dart         # Gıda kataloğu, K yükü hesabı
│   └── patient_profile.dart       # Acil kişi, hedef aralık, kritik eşikler
├── repositories/
│   ├── repositories.dart          # Soyut arayüzler + reaktif in-memory impl
│   └── sqflite_repositories.dart  # Kalıcı depolama (şema v2 + migration)
├── services/
│   ├── alert_service.dart         # Kritik eşik mantığı + bildirim dağıtımı
│   ├── local_notification_gateway.dart      # flutter_local_notifications
│   ├── sms_emergency_gateway.dart           # url_launcher: sms: intent
│   ├── trend_service.dart         # Trend + TTR + diyet korelasyonu
│   ├── pdf_report_service.dart    # PDF tablosu
│   ├── medication_service.dart    # Günlük doz tablosu + uyum + doz önerisi
│   ├── reminder_service.dart      # Sıklık -> bildirim planı
│   ├── local_reminder_scheduler.dart        # Zaman dilimli tekrarlı bildirim
│   ├── inr_ocr_service.dart       # Ham OCR metninden INR ayıklama (saf)
│   ├── comorbidity_sync_service.dart        # Kilo+nabız ↔ INR ödem riski
│   ├── health_package_metrics_gateway.dart  # HealthKit / Health Connect
│   ├── health_background_observer.dart      # iOS HKObserverQuery köprüsü
│   ├── comorbidity_background_scheduler.dart# Android WorkManager görevi
│   ├── lock_screen_sync_service.dart        # Acil yüzeyleri besler (widget+NFC)
│   ├── nfc_emergency_service.dart           # Android HCE payload'ı
│   ├── caregiver_share_service.dart         # Yakına durum özeti (saf metin)
│   ├── firebase_auth_service.dart           # Oturum
│   ├── app_settings.dart                    # Dil tercihi (sqflite v4)
│   ├── cloud_sync_service.dart              # Bulut birleştirme kuralı
│   ├── firestore_cloud_gateway.dart         # CloudGateway'in Firestore impl.
│   ├── entitlement_service.dart   # Premium yetkilendirme (mağazadan bağımsız)
│   └── revenuecat_entitlement_gateway.dart  # RevenueCat implementasyonu
└── ui/
    ├── theme.dart                 # Tasarım dili (60+ yaş için okunabilirlik)
    ├── today_screen.dart          # "Bugün": sonraki doz + güncel INR
    ├── medications_screen.dart    # İlaç listesi, doz/sıklık, uyum
    ├── medication_editor_screen.dart        # Doz ve sıklık formu
    ├── medication_card.dart       # Geri sayım, günün dozları, haftalık şerit
    ├── history_screen.dart        # Trend, PDF, içgörüler
    ├── add_measurement_dialog.dart# Ölçüm girişi (Steady-Touch ile)
    ├── vitamin_k_dialog.dart      # K vitamini öğün girişi
    ├── inr_scan_screen.dart       # Kamera + ML Kit canlı OCR
    ├── inr_ambient_hero.dart      # Güncel INR kartı
    ├── inr_trend_chart.dart       # fl_chart bantlı çizgi grafik
    ├── profile_screen.dart        # Hasta, hedef aralık, acil kişi, abonelik
    ├── auth_screen.dart           # Giriş / kayıt
    ├── paywall_screen.dart        # Abonelik ekranı
    ├── premium_gate.dart          # PremiumScope + kilit bileşenleri
    ├── language_picker.dart       # Dil seçici
    ├── steady_touch.dart          # Tremor filtresi + mıknatıslı hedefler
    └── safe_touch.dart            # TTS + çift dokunuş onayı

android/app/src/main/kotlin/com/mirketteknoloji/inrtakip/
├── MainActivity.kt                # NFC MethodChannel
├── InrHceService.kt               # NFC Type 4 Tag emülasyonu (HCE)
└── InrEmergencyGlanceWidget.kt    # Glance acil durum widget'ı
ios/
├── Runner/AppDelegate.swift       # HKObserverQuery + plugin kaydı
└── InrEmergencyWidgetExtension/   # WidgetKit acil durum widget'ı

test/                              # 14 birim/widget testi
integration_test/app_test.dart     # Gerçek cihazda uçtan uca akış
```

## 🚀 Başlangıç

```bash
flutter pub get
flutter test
flutter run --dart-define-from-file=dart_defines.json
```

Çeviri dosyaları değiştiğinde sınıfları yeniden üretin (pub get de üretir):

```bash
flutter gen-l10n
```

Yeni dil eklemek: `lib/l10n/app_<dil>.arb` dosyasını `app_tr.arb`'deki
anahtarlarla oluşturun, `flutter gen-l10n` çalıştırın ve dil adını
`ui/language_picker.dart` içindeki `kLanguageNames`'e ekleyin. Kod
değişmez; `l10n_test.dart` eksik etiketi yakalar.

### Geliştirme araçları

Oturum açmadan doğrudan ana kabuğu açan bir giriş noktası:

```bash
flutter run -t lib/dev_preview.dart --dart-define=DEV_TAB=2
```

| Bayrak | Etki |
|---|---|
| `DEV_TAB` | Açılış sekmesi: 0=Bugün, 1=İlaçlarım, 2=Geçmiş, 3=Profil |
| `DEV_PAYWALL` | Paywall'ı HomeShell'in üstüne açar (mağaza ekran görüntüsü için) |
| `DEV_SCROLL` | Paywall'ı belirtilen piksel kadar kaydırır |
| `DEBUG_PREMIUM` | Ana uygulamada paywall'ı atlar (`--dart-define=DEBUG_PREMIUM=true`) |

`dev_preview.dart` release derlemelerine dahil değildir.

Gerçek cihazda uçtan uca akış testi (widget testlerinin sahte rasterizer'ı
gerçek çizim hatalarını göremez):

```bash
flutter test integration_test/app_test.dart -d <device-id>
```

## 📱 Platform gereksinimleri

| | Android | iOS |
|---|---|---|
| Minimum | `minSdk 26` (Health Connect gereği) | — |
| Sağlık verisi | Health Connect uygulaması kurulu olmalı; `READ_WEIGHT`, `READ_HEART_RATE` | `NSHealthShareUsageDescription` + HealthKit & background-delivery entitlement |
| Kamerayla OCR | `camera` eklentisinin manifesti izni sağlar | `NSCameraUsageDescription` |
| Arka plan taraması | WorkManager, 6 saatte bir | `HKObserverQuery`, olay bazlı (yeni kilo örneğinde uyanır) |
| Hatırlatıcı | `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` | — |
| Widget | Glance + SharedPreferences | WidgetKit + App Group |
| NFC acil kart | HCE (`HostApduService`), kilit ekranında çalışır | **Desteklenmiyor** — Apple HCE'yi yalnızca Wallet/Apple Pay'e açar |

**iOS NFC notu:** "Kilit ekranında pasif NFC etiketi gibi davranma"
üçüncü parti uygulamalara kapalıdır. `PlatformChannelNfcGateway` iOS'ta
sessizce başarılı dönmek yerine `UnsupportedError` fırlatır — acil durum
özelliğinde "çalışıyormuş gibi görünmek" kabul edilemez. iOS'un desteklenen
karşılığı kullanıcıyı Sağlık > **Tıbbi Kimlik** akışına yönlendirmektir.

**SMS notu:** Acil kişiye bildirim, Mesajlar uygulamasını **önceden
doldurulmuş** olarak açar; kullanıcının "Gönder"e basması gerekir. Sessiz
gönderim Android'de `SEND_SMS` kısıtlı izni gerektirir (Play yalnızca
varsayılan SMS uygulamalarını onaylar), iOS'ta ise API yoktur.

## ⚠️ Kalan sınırlar

Bilinçli olarak yapılmayanlar ve platformun izin vermedikleri:

| Konu | Durum |
|---|---|
| **16 dil çevirisi** | Altyapı ve tüm dizeler hazır (360 anahtar); şu an yalnızca `tr` ve `en` dolu. Kalan diller ARB dosyası eklenerek gelir, kod değişmez |
| **Android bildirim kanalı adı** | Kanal bir kez oluşturulur; dil sonradan değişirse kanal adı eski dilde kalır (Android kısıtı) |
| **Kayıt düzenleme senkronu** | Bulut birleştirmesi "ekleme" odaklıdır: aynı kayıt iki cihazda ayrı ayrı düzenlenirse her cihaz kendi sürümünü korur (bulutta son gönderen kazanır). Kesin çözüm modele kayıt bazlı `updatedAt` eklemeyi gerektirir. Silme doğru çalışır — mezar taşı (tombstone) defteriyle |
| **Alım kayıtları buluta gitmez** | `DoseIntake` günde birkaç satır üretir, klinik değeri düşüktür; yeni cihazda uyum oranı sıfırdan başlar |
| **iOS'ta NFC acil kartı** | Apple, üçüncü parti uygulamalara Host Card Emulation vermiyor; iOS karşılığı Sağlık > Tıbbi Kimlik'tir |
| **Sessiz SMS yok** | Her iki platformda da mesaj taslağı açılır, "Gönder"e kullanıcı basar (gerekçe aşağıda) |

## 💳 Monetizasyon

Model: **freemium + abonelik**. Gerekçe, uygulamanın her premium kullanıcı için
süregelen bir sunucu maliyeti (Firestore/Auth) olması ve warfarin tedavisinin
kronik — yani çok yıllık — olmasıdır. Ücretsiz kullanıcı tamamen yerel çalışır ve sunucu
maliyeti üretmez: bulut senkronu, sağlık taraması ve widget senkronu yalnızca
abonelik doğrulandığında başlar (`main.dart _startPremiumServices`). Acil
durum NFC kartı bunun istisnasıdır — güvenlik özelliği olduğu için ücretsiz
katmanda da yayınlanır.

**Değişmez kural:** güvenlikle ilgili hiçbir özellik paywall'ın arkasına
konmaz. Bu kural `entitlement_service.dart` içindeki `kAlwaysFreeFeatures`
sabitinde kodlanmış ve `entitlement_test.dart` ile test edilmiştir.

| Ücretsiz | Premium |
|---|---|
| INR + doz kaydı (sınırsız) | Sınırsız geçmiş (30 gün üstü) |
| İlaç planı: doz, sıklık, hatırlatıcı | PDF doktor raporu |
| Kritik eşik uyarısı + acil SMS | Kamerayla INR okuma (OCR) |
| Son 30 günün trendi | Bulut yedek + çoklu cihaz |
| 2 ilaca kadar | Sağlık uygulaması senkronu (ödem taraması) |
| Acil durum kartı (widget verisi + NFC) | Ana ekran / kilit ekranı widget'ı |
| K vitamini günlüğüne kayıt | K vitamini – INR içgörüleri |
| | Yakınla paylaşım, sınırsız ilaç |

Ücretsiz katman limitleri tek yerde: `FreeTierLimits` (`historyDays = 30`,
`medicationCount = 2`).

### Mağaza yapılandırması

Aşağıdaki kimlikler **kodun beklediği değerlerdir**; birebir aynı olmalı
(bkz. `config/revenuecat_config.dart`). App Store Connect ve Play Console'da
oluşturulan ürün kimlikleri **sonradan silinemez ve yeniden kullanılamaz** —
yazmadan önce iki kez kontrol edin.

**RevenueCat**

| Alan | Değer |
|---|---|
| Entitlement | `premium` |
| Offering | `default` |
| Paketler | `$rc_annual`, `$rc_monthly`, `$rc_lifetime` |

**App Store Connect** — Abonelik grubu: `INR Takip Premium`

| Paket | Ürün kimliği | Tür |
|---|---|---|
| `$rc_monthly` | `inr_premium_monthly` | Auto-renewable, 1 ay |
| `$rc_annual` | `inr_premium_annual` | Auto-renewable, 1 yıl |
| `$rc_lifetime` | `inr_premium_lifetime` | **Non-consumable** (abonelik değil) |

**Play Console** — Play'in yeni modelinde tek abonelik + temel planlar:

| Paket | Ürün kimliği | Tür |
|---|---|---|
| `$rc_monthly` | `inr_premium:monthly` | Abonelik `inr_premium`, temel plan `monthly` |
| `$rc_annual` | `inr_premium:annual` | Abonelik `inr_premium`, temel plan `annual` |
| `$rc_lifetime` | `inr_premium_lifetime` | Tek seferlik ürün |

**Fiyat ve deneme**

Temel fiyat ABD doları üzerinden girilir, mağazalar diğer ülkelere (Türkiye
dahil) kendi kurlarıyla dönüştürür — rakip eşleniği konumlandırma:

| Plan | Temel fiyat | Not |
|---|---|---|
| Aylık | 3,99 USD | Warfarin Wise ile aynı |
| Yıllık | 34,99 USD | Aylığa göre ~%27 tasarruf; paywall bu rozeti fiyatlardan kendi hesaplar |
| Ömür boyu | 89,99 USD | Yıllığın ~2,5 katı |

Her iki abonelik planına da **7 günlük ücretsiz deneme** tanımlayın
(Apple: Introductory Offer → Free Trial 1 week; Google: temel plana
free-trial fazlı bir Offer). Paywall deneme süresini mağazadan okuyup
"7 gün ücretsiz dene" olarak gösterir — uygulamada sabit yazılmaz.

> Fiyatı uygulamada asla sabit yazmayın; `StoreProduct.priceString`
> gösterilir. Türkiye fiyatını sonradan veriye bakarak ayrı ayarlamak
> isterseniz mağaza panelinden ülke bazlı override yapabilirsiniz.

### Uygulama kimliği (bundle ID)

| Platform | Değer |
|---|---|
| iOS bundle ID | `com.mirketteknoloji.inrtakip` |
| Android applicationId | `com.mirketteknoloji.inrtakip` |
| iOS App Group (widget) | `group.com.mirketteknoloji.inrtakip` |

> **Yayınlandıktan sonra değiştirilemez.** Flutter şablonundan gelen
> `com.example.*` değerleri Apple ve Google tarafından reddedilir, bu yüzden
> mağaza kaydı açmadan önce değiştirilmesi zorunluydu.

Paket adı değiştiği için Firebase yapılandırması yenilenmelidir — aksi hâlde
Android derlemesi `No matching client found for package name` hatası verir:

```bash
flutterfire configure --project=inr-takip-app
```

Bu komut yeni paket adlarını Firebase projesine kaydeder ve
`firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`
dosyalarını yeniden üretir.

Ayrıca Apple Developer portalında `group.com.mirketteknoloji.inrtakip`
App Group'unu oluşturup hem Runner hem widget uzantısı profillerine ekleyin.

### Firestore kuralları

Profil dokümanı `users/{uid}` yolunda tutulur; `firestore.rules` yalnızca
`request.auth.uid == userId` olan kullanıcıya erişim verir. Yayınlamak için:

```bash
firebase deploy --only firestore:rules
```

### Play Console: ürün oluşturmadan önce sürüm yükleyin

Google Play, **BILLING izni içeren bir sürüm yüklenmeden** abonelik veya tek
seferlik ürün oluşturmanıza izin vermez ("Tek seferlik ürün eklemek için
APK'nıza FATURALANDIRMA iznini eklemeniz gerekir"). İzin manifest'te zaten
var; eksik olan imzalı bir sürüm.

Release derlemesi `android/key.properties` dosyasından okur. Bu dosya ve
keystore `.gitignore`'dadır, depoya girmez.

1. Yükleme anahtarı oluşturun (parolaları siz belirleyin):

```bash
keytool -genkey -v -keystore ~/inrtakip-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. `android/key.properties` dosyasını oluşturun:

```
storePassword=<store parolanız>
keyPassword=<key parolanız>
keyAlias=upload
storeFile=/Users/<kullanıcı>/inrtakip-upload.jks
```

3. Paketi derleyip Play'e yükleyin (dahili test kanalı yeterli):

```bash
flutter build appbundle --dart-define-from-file=dart_defines.json
```

`build/app/outputs/bundle/release/app-release.aab` dosyasını Play Console →
Test edin ve yayınlayın → Dahili test'e yükleyin. Sürüm işlendikten sonra
Para Kazanın → Ürünler bölümü açılır ve abonelikler oluşturulabilir.

> Keystore'u kaybederseniz uygulamayı bir daha güncelleyemezsiniz. Yedekleyin.

### RevenueCat'i mağazalara bağlama

Bu adım kimlik bilgisi gerektirir ve elle yapılmalıdır:

1. **iOS**: App Store Connect → Users and Access → Integrations → In-App
   Purchase key (`.p8`) oluşturup RevenueCat'e yükleyin.
2. **Android**: Google Cloud'da bir servis hesabı açıp Play Developer API
   erişimi verin, JSON anahtarını RevenueCat'e yükleyin.
3. Anahtarları derlemede verin. Depoda hazır `dart_defines.json` var
   (`RC_IOS_KEY`, `RC_ANDROID_KEY`, `RC_ENTITLEMENT`, `RC_OFFERING`;
   RevenueCat public SDK anahtarları istemciye gömülür, gizli değildir):

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Aynı bayrak `flutter build ipa` / `flutter build appbundle` için de geçerlidir.
Anahtar hiç verilmezse uygulama `FakeEntitlementGateway` ile çalışır: herkes
ücretsiz katmandadır, hiçbir ekran kilitlenmez, çökme olmaz.

#### Mağazalarda tanımlı ürünler

| Paket | RevenueCat | App Store | Play Store | Fiyat |
|---|---|---|---|---|
| `$rc_monthly` | `inr_premium_monthly` / `inr_premium:monthly` | `inr_premium_monthly` | `inr_premium` + `monthly` | 3,99 USD |
| `$rc_annual` | `inr_premium_annual` / `inr_premium:annual` | `inr_premium_annual` | `inr_premium` + `annual` | 34,99 USD |
| `$rc_lifetime` | `inr_premium_lifetime` | `inr_premium_lifetime` | `inr_premium_lifetime` | 89,99 USD |

Aylık ve yıllık planların her ikisinde 7 günlük ücretsiz deneme tanımlıdır
(Play'de `freetrial` teklifi, ASC'de introductory offer). Play'de yalnızca
`monthly` temel planı "eski sürümlerle uyumlu" işaretlidir; RevenueCat ürün
tanımları buna göre ayarlanmıştır.

Sağlayıcı değiştirmek isterseniz yalnızca
`revenuecat_entitlement_gateway.dart` yeniden yazılır; UI ve iş mantığı
`EntitlementGateway` arayüzüne bağlıdır.

## 📄 Lisans

MIT — bkz. [LICENSE](LICENSE)

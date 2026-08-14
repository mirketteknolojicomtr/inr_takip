# 🩸 INR Takip

Warfarin kullanan hastalar için INR ölçümü, doz ve K vitamini takibi yapan,
temiz mimarili bir **Flutter** uygulama çekirdeği.

> ⚠️ **Tıbbi uyarı:** Bu proje bir yazılım mimarisi örneğidir, tıbbi tavsiye
> yerine geçmez. Eşik değerleri (INR < 1.5 / > 4.5) ve hedef aralıklar
> örnektir; gerçek kullanımda hekim tarafından hastaya özel ayarlanmalıdır.

## ✨ Özellikler

- **INR & Doz Geçmişi** — tarih, INR değeri, günlük doz (mg) ve kayda gömülü
  hedef aralık (tarihsel doğruluk korunur)
- **K Vitamini / Diyet Logu** — hazır gıda kataloğu, porsiyon çarpanı ve
  INR düşüşleriyle 72 saatlik korelasyon içgörüleri
- **Akıllı Uyarı Sistemi** — kritik eşik aşımında yerel bildirim + acil durum
  kişisine SMS tetikleme (gateway soyutlamasıyla)
- **30 Günlük Trend Grafiği** — fl_chart ile yeşil (güvenli) / sarı / kırmızı
  (riskli) bantlı çizgi grafik
- **PDF Rapor** — doktor viziti için tek tuşla 3 aylık INR & doz tablosu
- **İlaç Saati Hatırlatıcısı** — günlük bildirim + ana ekranda canlı geri
  sayım widget'ı

## 🏗 Mimari

```
UI (Widgets)
   │  yalnızca Stream/Future tüketir
Services        AlertService · TrendService · PdfReportService · ReminderService
   │  saf iş mantığı + soyut gateway'ler
Repositories    soyut arayüzler (InMemory → drift/sqflite → API)
   │
Models          InrEntry · VitaminKLog · PatientProfile
```

Detaylar için [ARCHITECTURE.md](ARCHITECTURE.md).

## 📁 Proje Yapısı

```
lib/
├── main.dart                      # Örnek uygulama girişi
├── models/
│   ├── inr_entry.dart             # INR + doz + hedef aralık, InrZone
│   ├── vitamin_k_log.dart         # Gıda kataloğu, K yükü hesabı
│   └── patient_profile.dart       # Acil kişi, ilaç zamanlaması, eşikler
├── repositories/
│   └── repositories.dart          # Soyut arayüzler + reaktif in-memory impl
├── services/
│   ├── alert_service.dart         # Kritik eşik mantığı + bildirim dağıtımı
│   ├── trend_service.dart         # 30 günlük trend + diyet korelasyonu
│   ├── pdf_report_service.dart    # 3 aylık PDF tablosu
│   └── reminder_service.dart      # Günlük bildirim + geri sayım widget'ı
└── ui/
    └── inr_trend_chart.dart       # fl_chart bantlı çizgi grafik
test/
└── alert_service_test.dart        # Saf iş mantığı birim testleri
```

## 🚀 Başlangıç

```bash
flutter pub get
flutter test
flutter run
```

## 🔌 Kalıcı depolamaya geçiş

`InMemoryInrRepository` yalnızca prototip içindir. `InrRepository` arayüzünü
drift veya sqflite ile implemente edip DI'daki tek satırı değiştirmeniz
yeterlidir — servis ve UI katmanına dokunulmaz.

## 📄 Lisans

MIT — bkz. [LICENSE](LICENSE)

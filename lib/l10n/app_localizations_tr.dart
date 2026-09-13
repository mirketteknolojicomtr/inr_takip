// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'INR Takip';

  @override
  String get tabToday => 'Bugün';

  @override
  String get tabMedications => 'İlaçlarım';

  @override
  String get tabHistory => 'Geçmiş';

  @override
  String get tabProfile => 'Profil';

  @override
  String get zoneInRange => 'Hedefte';

  @override
  String get zoneBelowRange => 'Hedefin altında';

  @override
  String get zoneAboveRange => 'Hedefin üstünde';

  @override
  String get zoneCriticalLow => 'Kritik düşük';

  @override
  String get zoneCriticalHigh => 'Kritik yüksek';

  @override
  String get freqDaily => 'Her gün';

  @override
  String get freqEveryOtherDay => 'Gün aşırı';

  @override
  String get freqSpecificDays => 'Belirli günler';

  @override
  String get freqWeeklyPattern => 'Haftalık şema';

  @override
  String freqDailyAt(String times) {
    return 'Her gün · $times';
  }

  @override
  String freqEveryOtherDayAt(String time) {
    return 'Gün aşırı · $time';
  }

  @override
  String freqSpecificDaysAt(String days, String time) {
    return '$days · $time';
  }

  @override
  String freqWeeklyPatternAt(String time) {
    return 'Haftalık şema · $time';
  }

  @override
  String doseMg(String mg) {
    return '$mg mg';
  }

  @override
  String get doseNoneToday => 'Bugün doz yok';

  @override
  String doseSummary(String mg, String tablets) {
    return '$mg · $tablets';
  }

  @override
  String tabletCount(String count) {
    return '$count tablet';
  }

  @override
  String get intakeTaken => 'Alındı';

  @override
  String get intakeSkipped => 'Atlandı';

  @override
  String get foodSpinach => 'Ispanak';

  @override
  String get foodKale => 'Kara lahana';

  @override
  String get foodChard => 'Pazı';

  @override
  String get foodParsley => 'Maydanoz';

  @override
  String get foodBroccoli => 'Brokoli';

  @override
  String get foodLettuce => 'Marul';

  @override
  String get foodGreenBeans => 'Taze fasulye';

  @override
  String get foodGreenTea => 'Yeşil çay';

  @override
  String get foodOther => 'Diğer';

  @override
  String get portionSmall => 'Az';

  @override
  String get portionMedium => 'Orta';

  @override
  String get portionLarge => 'Bol';

  @override
  String get alertCriticalLowTitle => 'KRİTİK: INR çok düşük';

  @override
  String alertCriticalLowMessage(String value) {
    return 'INR $value — pıhtılaşma riski. Lütfen en kısa sürede doktorunuza veya sağlık kuruluşuna ulaşın.';
  }

  @override
  String get alertCriticalHighTitle => 'KRİTİK: INR çok yüksek';

  @override
  String alertCriticalHighMessage(String value) {
    return 'INR $value — kanama riski. Lütfen en kısa sürede doktorunuza veya sağlık kuruluşuna ulaşın.';
  }

  @override
  String get alertBelowRangeTitle => 'INR hedefin altında';

  @override
  String alertBelowRangeMessage(String value, String lower, String upper) {
    return 'INR $value, hedef aralık $lower–$upper. Takip ölçümünüzü planlayın ve doktorunuzu bilgilendirin.';
  }

  @override
  String get alertAboveRangeTitle => 'INR hedefin üstünde';

  @override
  String alertAboveRangeMessage(String value, String lower, String upper) {
    return 'INR $value, hedef aralık $lower–$upper. Takip ölçümünüzü planlayın ve doktorunuzu bilgilendirin.';
  }

  @override
  String get alertInRangeTitle => 'Hedef aralıkta';

  @override
  String alertInRangeMessage(String value) {
    return 'INR $value hedef aralıkta. Bu düzeni koruyun.';
  }

  @override
  String get alertEdemaTitle => 'Olası akut ödem + hedef dışı INR';

  @override
  String alertEdemaMessage(String delta, String value) {
    return 'Son 24 saatte $delta ani kilo artışı (sıvı birikmesi belirtisi olabilir) kaydedildi ve güncel INR $value hedef aralığın dışında. Bu bilgiyi doktorunuzla paylaşmanız önerilir.';
  }

  @override
  String reminderTitle(String medication) {
    return '$medication zamanı';
  }

  @override
  String reminderBodyWithTablets(String mg, String tablets) {
    return '$mg ($tablets)';
  }

  @override
  String get premiumUnlimitedHistory => 'Sınırsız geçmiş';

  @override
  String get premiumPdfReport => 'PDF doktor raporu';

  @override
  String get premiumOcrScan => 'Kamerayla INR okuma';

  @override
  String get premiumCloudSync => 'Bulut yedek ve senkron';

  @override
  String get premiumHealthSync => 'Sağlık uygulaması senkronu';

  @override
  String get premiumLockScreenWidget => 'Ana ekran widget’ı';

  @override
  String get premiumDietInsights => 'Diyet–INR içgörüleri';

  @override
  String get premiumUnlimitedMedications => 'Sınırsız ilaç';

  @override
  String get premiumCaregiverSharing => 'Yakınla paylaşım';

  @override
  String get freeInrLog => 'INR ve doz kaydı';

  @override
  String get freeMedicationPlan => 'İlaç planı: doz, sıklık ve hatırlatıcı';

  @override
  String get freeCriticalAlert => 'Kritik eşik uyarısı';

  @override
  String get freeEmergencyContact => 'Acil durum kişisine bildirim';

  @override
  String get freeRecentTrend => 'Son 30 günün trendi';

  @override
  String get freeEmergencyCard => 'Acil durum kartı';

  @override
  String emergencyHeadline(String value, String status) {
    return 'SON INR: $value ($status)';
  }

  @override
  String get emergencyStatusStable => 'STABİL';

  @override
  String get emergencyStatusAttention => 'DİKKAT';

  @override
  String get emergencyNoRecord => 'INR kaydı yok';

  @override
  String get emergencyNdefTitle => 'ACİL TIBBİ BİLGİ';

  @override
  String emergencyNdefPatient(String name) {
    return 'Hasta: $name';
  }

  @override
  String emergencyNdefMedication(String medication) {
    return 'İlaç: $medication (antikoagülan)';
  }

  @override
  String emergencyNdefContact(String name, String phone) {
    return 'Acil kişi: $name $phone';
  }

  @override
  String get emergencyNdefStopped =>
      'INR Takip: acil bilgi paylaşımı durduruldu.';

  @override
  String shareSummaryTitle(String name) {
    return '$name — INR durum özeti';
  }

  @override
  String shareSummaryDate(String date) {
    return '$date tarihli';
  }

  @override
  String shareSummaryLastInr(String value, String zone, String date) {
    return 'Son INR: $value ($zone) — $date';
  }

  @override
  String shareSummaryTargetRange(String lower, String upper) {
    return 'Hedef aralık: $lower–$upper';
  }

  @override
  String get shareSummaryNoInr => 'Henüz INR ölçümü kaydedilmedi.';

  @override
  String shareSummaryTodayDose(String total, String taken) {
    return 'Bugünkü doz: $total (alınan: $taken)';
  }

  @override
  String shareSummaryAdherence(String percent, int taken, int scheduled) {
    return 'Son 7 gün ilaç uyumu: %$percent ($taken/$scheduled doz)';
  }

  @override
  String get shareSummaryFooter =>
      'Bu özet INR Takip uygulamasından gönderildi. Tıbbi karar hekime aittir.';

  @override
  String get notificationChannelName => 'INR Uyarıları';

  @override
  String get notificationChannelDescription =>
      'Kritik/hedef dışı INR değerleri ve ödem riski uyarıları';

  @override
  String get reminderChannelName => 'İlaç Hatırlatıcıları';

  @override
  String get reminderChannelDescription =>
      'İlaç alım saatleriniz için hatırlatma bildirimleri';

  @override
  String reminderBody(String medication, String dose) {
    return '$medication — $dose.';
  }

  @override
  String reminderBodyAnticoagulant(String medication, String dose) {
    return '$medication — $dose. Her gün aynı saatte almak INR dengesi için önemlidir.';
  }

  @override
  String doseWithTablets(String mg, String tablets) {
    return '$mg ($tablets)';
  }

  @override
  String doseSourceToday(String medication) {
    return '$medication planınızdan alındı';
  }

  @override
  String doseSourceLastDay(String medication) {
    return '$medication — son doz gününüzden alındı';
  }

  @override
  String vitaminKEntrySubtitle(String date, String portion, String load) {
    return '$date · $portion porsiyon · K yükü $load';
  }

  @override
  String vitaminKDeleteTooltip(String name) {
    return '$name kaydını sil';
  }

  @override
  String dietInsightText(String delta, String foods) {
    return 'INR $delta puan düştü. Önceki 3 günde yüksek K vitamini alımı kaydedilmiş: $foods. Bu bilgiyi doktorunuzla paylaşabilirsiniz.';
  }

  @override
  String get doseFieldLabel => 'O günkü doz';

  @override
  String get doseFieldHelper =>
      'İlaç planı eklerseniz burası kendiliğinden dolar';

  @override
  String get planWeekly => 'Haftalık';

  @override
  String get planMonthly => 'Aylık';

  @override
  String get planTwoMonth => '2 aylık';

  @override
  String get planThreeMonth => '3 aylık';

  @override
  String get planSixMonth => '6 aylık';

  @override
  String get planAnnual => 'Yıllık';

  @override
  String get planLifetime => 'Ömür boyu';

  @override
  String get periodWeek => 'hafta';

  @override
  String get periodMonth => 'ay';

  @override
  String get periodTwoMonths => '2 ay';

  @override
  String get periodThreeMonths => '3 ay';

  @override
  String get periodSixMonths => '6 ay';

  @override
  String get periodYear => 'yıl';

  @override
  String get periodOneTime => 'tek seferlik';

  @override
  String savingBadge(int percent) {
    return '%$percent tasarruf';
  }

  @override
  String get purchaseStoreUnavailable => 'Mağaza bağlantısı kurulamadı.';

  @override
  String get purchasePlanNotFound => 'Seçilen plan mağazada bulunamadı.';

  @override
  String get purchaseCompleted => 'Aboneliğiniz aktif. Teşekkürler!';

  @override
  String get purchaseNotCompleted =>
      'Satın alma tamamlanamadı. Lütfen tekrar deneyin.';

  @override
  String get purchasePendingApproval =>
      'Ödeme onay bekliyor. Onaylanınca premium açılacak.';

  @override
  String get purchaseAlreadyActive => 'Bu abonelik zaten aktif.';

  @override
  String get purchaseNoConnection => 'İnternet bağlantısı kurulamadı.';

  @override
  String get purchaseNotAllowed =>
      'Bu cihazda satın alma izni yok (ör. ebeveyn kontrolü açık olabilir).';

  @override
  String get restoreCompleted => 'Aboneliğiniz geri yüklendi.';

  @override
  String get restoreNothingFound => 'Bu hesapta aktif abonelik bulunamadı.';

  @override
  String get restoreFailed => 'Geri yükleme tamamlanamadı.';

  @override
  String get paywallHeadline => 'Takibi kolaylaştıran her şey';

  @override
  String get paywallSubtitle =>
      'Güvenlik özellikleri ücretsiz kalır; premium yalnızca kolaylıkları açar. Güvenlik uyarıları her zaman ücretsizdir.';

  @override
  String paywallTrialCta(int days) {
    return '$days gün ücretsiz dene';
  }

  @override
  String get paywallCta => 'Premium’a geç';

  @override
  String get paywallRestore => 'Satın alımları geri yükle';

  @override
  String paywallFeatureIsPremium(String feature) {
    return '“$feature” premium bir özellik.';
  }

  @override
  String get paywallPdfSubtitle =>
      '3, 6 veya 12 aylık INR ve doz tablosu, tek dokunuşla.';

  @override
  String get paywallHistorySubtitle =>
      'Ücretsizde son 30 gün; premium ile tüm takip geçmişiniz.';

  @override
  String get paywallCloudTitle => 'Bulut yedek ve çoklu cihaz';

  @override
  String get paywallCloudSubtitle =>
      'Telefon değişse de kayıtlarınız kaybolmaz.';

  @override
  String get paywallOcrSubtitle =>
      'Cihaz ekranındaki değeri elle yazmadan kaydedin.';

  @override
  String get paywallDietSubtitle =>
      'Hangi beslenmenin INR’yi düşürdüğünü görün.';

  @override
  String get paywallMedsSubtitle =>
      'Ücretsizde 2 ilaç; premium ile tüm tedavi listeniz.';

  @override
  String get paywallWidgetSubtitle =>
      'Sonraki doz ve güncel INR, telefonu açmadan.';

  @override
  String get paywallAlwaysFreeTitle => 'Bunlar her zaman ücretsiz';

  @override
  String paywallTrialBadge(int days) {
    return '$days gün ücretsiz';
  }

  @override
  String paywallPerMonth(String price) {
    return 'aylık $price';
  }

  @override
  String get paywallPlansErrorTitle => 'Planlar yüklenemedi';

  @override
  String get paywallPlansErrorMessage =>
      'Mağaza bağlantısı kurulamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get paywallLifetimeTerms => 'Tek seferlik ödemedir, yenilenmez.';

  @override
  String get paywallSubscriptionTerms =>
      'Abonelik, dönem bitiminden en az 24 saat önce iptal edilmezse otomatik yenilenir. İptali cihazınızın mağaza ayarlarından yapabilirsiniz.';

  @override
  String get paywallTerms => 'Kullanım Koşulları';

  @override
  String get paywallPrivacy => 'Gizlilik Politikası';

  @override
  String get paywallMedicalDisclaimer =>
      'INR Takip tıbbi tavsiye vermez; kayıtlarınızı düzenli tutmanıza yardımcı olur. Doz değişikliğini yalnızca hekiminiz yapar.';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get close => 'Kapat';

  @override
  String get pdfTitle => 'INR Takip Raporu';

  @override
  String pdfHeaderLine(
      String name, String lower, String upper, String from, String to) {
    return 'Hasta: $name   |   Hedef aralık: $lower–$upper   |   Dönem: $from – $to';
  }

  @override
  String pdfSummaryLine(int count, String percent) {
    return 'Toplam ölçüm: $count   •   Hedef aralıkta kalma: %$percent';
  }

  @override
  String get pdfColumnDate => 'Tarih';

  @override
  String get pdfColumnInr => 'INR';

  @override
  String get pdfColumnDose => 'Doz (mg/gün)';

  @override
  String get pdfColumnStatus => 'Durum';

  @override
  String get pdfColumnNote => 'Not';

  @override
  String get pdfDisclaimer =>
      'Bu rapor hasta tarafından girilen verilerle oluşturulmuştur; tıbbi karar için hekim değerlendirmesi esastır.';

  @override
  String get pdfFileName => 'inr_raporu.pdf';

  @override
  String get chartNoData => 'Son 30 günde kayıt yok';

  @override
  String get unlockWithPremium => 'Premium ile aç';

  @override
  String get measuredToday => 'bugün ölçüldü';

  @override
  String get measuredYesterday => 'dün ölçüldü';

  @override
  String measuredDaysAgo(int days) {
    return '$days gün önce ölçüldü';
  }

  @override
  String get cameraPreparing => 'Kamera hazırlanıyor…';

  @override
  String get cameraFailedTitle => 'Kamera açılamadı';

  @override
  String get cameraFailedMessage =>
      'Kamera izni verilmemiş olabilir ya da bu cihazda kamera kullanılamıyor. INR değerini elle de girebilirsiniz.';

  @override
  String get measurementDialogTitle => 'Yeni INR ölçümü';

  @override
  String get inrFieldLabel => 'INR değeri';

  @override
  String get inrFieldHint => 'Örn. 2,5';

  @override
  String get inrOutOfBounds => 'INR değeri 0–20 arasında olmalı.';

  @override
  String get doseInvalid => 'Geçerli bir doz girin.';

  @override
  String get vitaminKDialogTitle => 'K vitamini öğünü';

  @override
  String get vitaminKWhatQuestion => 'Ne yediniz?';

  @override
  String get vitaminKPortionLabel => 'Porsiyon';

  @override
  String get vitaminKWhenQuestion => 'Ne zaman?';

  @override
  String get vitaminKDatePickerHelp => 'Öğün tarihi';

  @override
  String get vitaminKFoodNameLabel => 'Gıda adı';

  @override
  String get vitaminKFoodNameHint => 'Örn. Semizotu';

  @override
  String get vitaminKFoodNameRequired => 'Gıdanın adını yazın.';

  @override
  String get dateToday => 'Bugün';

  @override
  String get dateYesterday => 'Dün';

  @override
  String get todayNoMedicationTitle => 'İlaç planı yok';

  @override
  String get todayNoMedicationMessage =>
      'Kan sulandırıcınızı ekleyin; dozu ve sıklığı burada görünsün, saatinde hatırlatalım.';

  @override
  String get todayAddMedication => 'İlaç ekle';

  @override
  String get todayCurrentInr => 'Güncel INR';

  @override
  String todayTargetRange(String lower, String upper) {
    return 'Hedef aralık $lower–$upper';
  }

  @override
  String get todayNoMeasurementTitle => 'Henüz ölçüm yok';

  @override
  String get todayNoMeasurementMessage =>
      'İlk INR değerinizi girin; hedef aralığa göre durumunuzu ve trendi burada gösterelim.';

  @override
  String get todayAddMeasurement => 'Ölçüm ekle';

  @override
  String get todayMedicationsTitle => 'Bugünün ilaçları';

  @override
  String todayMedicationsSubtitle(int count, String total) {
    return '$count alım · toplam $total';
  }

  @override
  String get todayEditPlan => 'Planı düzenle';

  @override
  String get todayDisclaimer =>
      'INR Takip tıbbi tavsiye vermez. Doz değişikliğini yalnızca hekiminiz yapar.';

  @override
  String get greetingMorning => 'Günaydın';

  @override
  String get greetingDay => 'İyi günler';

  @override
  String get greetingEvening => 'İyi akşamlar';

  @override
  String get todayAllDoneTitle => 'Bugünün dozları tamam';

  @override
  String todayAllDoneSubtitle(String total) {
    return 'Toplam $total alındı.';
  }

  @override
  String get zoneNoteInRange =>
      'Değeriniz hedef aralıkta. Dozunuzu ve beslenmenizi aynı düzende sürdürün.';

  @override
  String get zoneNoteBelow =>
      'Hedefin altında — pıhtı riski artabilir. Kontrol tarihinizi kaçırmayın.';

  @override
  String get zoneNoteAbove =>
      'Hedefin üstünde — kanama riski artabilir. Yeni bir morarma/kanama olursa hekiminizi arayın.';

  @override
  String zoneNoteCriticalLow(String threshold) {
    return 'Kritik düşük ($threshold). Hekiminizle bugün iletişime geçin.';
  }

  @override
  String zoneNoteCriticalHigh(String threshold) {
    return 'Kritik yüksek ($threshold). Hekiminizle bugün iletişime geçin.';
  }

  @override
  String get medsTitle => 'İlaç planım';

  @override
  String get medsSubtitle => 'Doz ve sıklık — dokunarak düzenleyin';

  @override
  String get medsAdd => 'İlaç ekle';

  @override
  String get medsEmptyTitle => 'Henüz ilaç eklemediniz';

  @override
  String get medsEmptyMessage =>
      'Kan sulandırıcınızı ekleyin; dozunu, sıklığını ve hatırlatmasını buradan yönetin.';

  @override
  String get medsEmptyAction => 'İlk ilacı ekle';

  @override
  String get medsAdherenceTitle => 'Son 7 günlük uyum';

  @override
  String medsAdherenceDetail(int taken, int scheduled) {
    return '$taken/$scheduled doz alındı';
  }

  @override
  String medsAdherenceMissed(int missed) {
    return ' · $missed kaçırıldı';
  }

  @override
  String get medsLimitTitle => 'Daha fazla ilaç ekleyin';

  @override
  String medsLimitMessage(int count) {
    return 'Ücretsiz sürümde $count ilaç takip edilebilir. Premium ile tüm tedavi listenizi tek yerde tutun.';
  }

  @override
  String get doseTake => 'Aldım';

  @override
  String get doseOverdue => 'Doz saati geçti';

  @override
  String get doseCountdown => 'Sonraki doza kalan';

  @override
  String doseConfirmAnnouncement(String medication, String amount) {
    return '$medication, $amount. Aldıysanız onaylamak için çift dokunun.';
  }

  @override
  String get doseSkip => 'Bu dozu atladım';

  @override
  String doseTodayTotal(String total) {
    return 'Bugünün toplamı: $total';
  }

  @override
  String doseTakenTotal(String total) {
    return '$total alındı';
  }

  @override
  String doseTakeTooltip(String medication) {
    return '$medication dozunu aldım';
  }

  @override
  String get doseUndoTooltip => 'İşareti geri al';

  @override
  String weeklyStripTitle(String medication) {
    return '$medication — haftalık şema';
  }

  @override
  String weeklyStripDayLabel(String day, String amount) {
    return '$day: $amount';
  }

  @override
  String get weeklyStripNoDose => 'ilaç yok';

  @override
  String get anticoagulantBadge => 'Kan sulandırıcı';

  @override
  String doseSummaryToday(String summary) {
    return '$summary  ·  bugün';
  }

  @override
  String get doseStateLate => 'Gecikti';

  @override
  String get doseStateWaiting => 'Bekliyor';

  @override
  String get historyReportFailed => 'Rapor oluşturulamadı.';

  @override
  String get historyEmptyTitle => 'Bu dönemde kayıt yok';

  @override
  String get historyEmptyMessage =>
      'INR ölçümü ekledikçe trend grafiği burada oluşur.';

  @override
  String get historyReportTitle => 'Doktor raporu';

  @override
  String get historyReportSubtitle => 'Vizit için PDF özet';

  @override
  String get historyReportPreparing => 'Hazırlanıyor…';

  @override
  String get historyReportShare => 'PDF raporu paylaş';

  @override
  String get historyMeasurements => 'Ölçümler';

  @override
  String historyRecordCount(int count) {
    return '$count kayıt';
  }

  @override
  String get historyDisclaimer =>
      'Rapor, girdiğiniz verilerle oluşturulur; tıbbi karar hekiminize aittir.';

  @override
  String windowDays(int days) {
    return '$days gün';
  }

  @override
  String windowMonths(int months) {
    return '$months ay';
  }

  @override
  String get windowYear => '1 yıl';

  @override
  String get inRangeTitle => 'Hedef aralıkta kalma';

  @override
  String get inRangeGood => 'İyi bir denge — bu düzeni koruyun.';

  @override
  String get inRangePoor =>
      'Hekiminiz doz ayarı yapmak isteyebilir; bu oranı vizitte paylaşın.';

  @override
  String get vitaminKJournalTitle => 'K vitamini günlüğü';

  @override
  String get vitaminKJournalEmptyHint =>
      'Ispanak, brokoli gibi öğünleri kaydedin';

  @override
  String vitaminKJournalSummary(int count, String load) {
    return '$count öğün · toplam yük $load';
  }

  @override
  String get vitaminKAddMeal => 'Öğün ekle';

  @override
  String get dietLockTitle => 'K vitamini – INR içgörüsü';

  @override
  String get dietLockDescription =>
      'Hangi öğünlerden sonra INR’nizin düştüğünü görün. Ispanak, brokoli gibi K vitamini yüksek gıdalarla değer değişimini eşleştirir.';

  @override
  String get dietEmptyTitle => 'Henüz bir ilişki bulunamadı';

  @override
  String get dietEmptyMessage =>
      'K vitamini yüksek öğünlerinizi kaydettikçe, INR düşüşleriyle bağlantı burada görünür.';

  @override
  String get dietInsightsTitle => 'K vitamini – INR içgörüleri';

  @override
  String entryRowSubtitle(String dose, String zone) {
    return '$dose mg/gün · $zone';
  }

  @override
  String get authSignUpTitle => 'Hesap Oluştur';

  @override
  String get authSignInTitle => 'Giriş Yap';

  @override
  String get authEmailInvalid => 'Geçerli bir e-posta girin';

  @override
  String get authPasswordTooShort => 'En az 6 karakter olmalı';

  @override
  String get authSignUpAction => 'Kayıt Ol';

  @override
  String get authSignInAction => 'Giriş Yap';

  @override
  String get authHaveAccount => 'Zaten hesabım var, giriş yap';

  @override
  String get authNoAccount => 'Hesabım yok, kayıt ol';

  @override
  String get authErrorInvalidEmail => 'Geçersiz e-posta adresi.';

  @override
  String get authErrorUserDisabled => 'Bu hesap devre dışı bırakılmış.';

  @override
  String get authErrorUserNotFound =>
      'Bu e-posta ile kayıtlı bir hesap bulunamadı.';

  @override
  String get authErrorWrongPassword => 'E-posta veya parola hatalı.';

  @override
  String get authErrorEmailInUse =>
      'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin.';

  @override
  String get authErrorWeakPassword => 'Parola çok zayıf (en az 6 karakter).';

  @override
  String get authErrorNotEnabled =>
      'E-posta/parola girişi Firebase Console’da henüz etkinleştirilmemiş.';

  @override
  String get authErrorGeneric => 'Beklenmeyen bir hata oluştu.';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get passwordLabel => 'Parola';

  @override
  String get shareDraftReady =>
      'Özet hazırlandı — göndermek için Mesajlar uygulamasında “Gönder”e dokunun.';

  @override
  String get shareNoContact =>
      'Önce bu ekrandan acil durum kişisi ve telefonunu kaydedin.';

  @override
  String get shareUnavailable =>
      'Bu cihazda mesaj gönderebilecek bir uygulama bulunamadı.';

  @override
  String get edemaScanNoRisk => 'Ödem taraması: risk bulunamadı.';

  @override
  String edemaScanRisk(String delta) {
    return 'Risk tespit edildi: $delta artış + hedef dışı INR.';
  }

  @override
  String get edemaScanTooltip => 'Ödem taraması';

  @override
  String get scanInrTooltip => 'Kamerayla INR oku';

  @override
  String get bootstrapFailed => 'Uygulama başlatılamadı';

  @override
  String get languageSectionTitle => 'Dil';

  @override
  String get languageSectionSubtitle => 'Uygulama dili ve sayı/tarih biçimi';

  @override
  String get languageSystemDefault => 'Cihaz dili';

  @override
  String get profilePatientSection => 'Hasta';

  @override
  String get profileNameLabel => 'Ad Soyad';

  @override
  String get profileTargetTitle => 'Hedef INR aralığı';

  @override
  String get profileTargetSubtitle =>
      'Hekiminizin sizin için belirlediği aralık';

  @override
  String get profileLowerBound => 'Alt sınır';

  @override
  String get profileUpperBound => 'Üst sınır';

  @override
  String get profileCriticalTitle => 'Kritik eşikler';

  @override
  String get profileCriticalSubtitle =>
      'Bu değerler aşılınca acil uyarı verilir';

  @override
  String get profileCriticalLow => 'Kritik düşük';

  @override
  String get profileCriticalHigh => 'Kritik yüksek';

  @override
  String get profileClotRisk => 'Pıhtı riski';

  @override
  String get profileBleedRisk => 'Kanama riski';

  @override
  String get profileContactTitle => 'Acil durum kişisi';

  @override
  String get profileContactSubtitle => 'Kritik değerde bilgilendirilir';

  @override
  String get profileContactPhone => 'Telefon';

  @override
  String get profileSmsToggle => 'Kritik değerde SMS gönder';

  @override
  String get profileSaveChanges => 'Değişiklikleri kaydet';

  @override
  String get profileSignOut => 'Çıkış yap';

  @override
  String get profileInvalidNumber => 'Geçersiz sayı';

  @override
  String get profileRangeOrderError =>
      'Hedef alt sınır, üst sınırdan küçük olmalı.';

  @override
  String profileThresholdError(String lower, String upper) {
    return 'Kritik eşikler hedef aralığın dışında olmalı (kritik düşük < $lower, kritik yüksek > $upper).';
  }

  @override
  String get subscriptionFreeTitle => 'Ücretsiz sürüm';

  @override
  String get subscriptionFreeMessage =>
      'PDF rapor, bulut yedek ve sınırsız geçmiş için premium’a geçin.';

  @override
  String get subscriptionTrialTitle => 'Deneme sürümü';

  @override
  String get subscriptionLifetime => 'Ömür boyu erişim';

  @override
  String get subscriptionCancelled =>
      'Aboneliğiniz iptal edilmiş. Bu tarihe kadar premium özellikler açık kalır.';

  @override
  String get subscriptionManage => 'Aboneliği yönet';

  @override
  String get caregiverShareTitle => 'Yakınla paylaşım';

  @override
  String get caregiverShareDescription =>
      'Son INR değerinizi, bugünkü dozunuzu ve ilaç uyum oranınızı tek dokunuşla yakınınıza gönderin. Uzaktaki bir çocuğunuz ya da bakıcınız durumunuzu düzenli takip edebilir.';

  @override
  String get caregiverSharePreparing => 'Hazırlanıyor…';

  @override
  String get caregiverShareAction => 'Durumumu yakınıma gönder';

  @override
  String get editorDoseAmountTitle => 'Doz miktarı';

  @override
  String get editorNameRequired => 'İlaç adı zorunlu.';

  @override
  String get editorWeeklyNeedsDose =>
      'Haftalık şemada en az bir güne doz girin.';

  @override
  String get editorNeedsTime => 'En az bir alım saati ekleyin.';

  @override
  String get editorNeedsAmount => 'En az bir saat için doz miktarı girin.';

  @override
  String get editorNeedsDay => 'En az bir gün seçin.';

  @override
  String get editorDeleteWarning =>
      'İlaç planı ve bu ilaca ait alım kayıtları silinir. INR ölçümleriniz etkilenmez.';

  @override
  String get editorDiscard => 'Vazgeç';

  @override
  String get editorEditTitle => 'İlacı düzenle';

  @override
  String get editorAddTitle => 'İlaç ekle';

  @override
  String get editorMedicationSection => 'İlaç';

  @override
  String get editorNameLabel => 'İlaç adı';

  @override
  String get editorNameHint => 'Örn. Coumadin';

  @override
  String get editorStrengthLabel => 'Tablet gücü (opsiyonel)';

  @override
  String get editorStrengthHelper =>
      'Girilirse doz “1 tablet”, “½ tablet” olarak da gösterilir.';

  @override
  String get editorAnticoagulantToggle => 'Kan sulandırıcı (INR’yi etkiler)';

  @override
  String get editorAnticoagulantConflict =>
      'Zaten bir kan sulandırıcı işaretli. Genelde tek antikoagülan kullanılır — hekiminize danışın.';

  @override
  String get editorAnticoagulantHelp =>
      'Ana ekranda öne çıkar ve INR kaydında doz olarak önerilir.';

  @override
  String get editorFrequencySection => 'Sıklık';

  @override
  String get editorFrequencySubtitle => 'İlacın hangi günlerde alınacağı';

  @override
  String get editorStartDay => 'Başlangıç günü';

  @override
  String get editorStartDayHelp => 'Gün aşırı sayımı bu günden başlar';

  @override
  String get editorAmountSubtitle => 'Her alımda kaç mg';

  @override
  String get editorOtherSection => 'Diğer';

  @override
  String get editorReminderToggle => 'Hatırlatma bildirimi';

  @override
  String get editorReminderHelp => 'Alım saatinde doz bilgisiyle bildirim';

  @override
  String get editorNoteHint => 'Örn. aç karnına';

  @override
  String get freqDailyHelp => 'Aynı doz, her gün';

  @override
  String get freqEveryOtherDayHelp => 'Bir gün al, bir gün ara ver';

  @override
  String get freqSpecificDaysHelp => 'Seçtiğiniz günlerde, aynı doz';

  @override
  String get freqWeeklyPatternHelp => 'Her gün farklı doz (warfarin şeması)';

  @override
  String get editorRemoveTime => 'Bu saati kaldır';

  @override
  String get editorAddTime => 'Alım saati ekle';

  @override
  String get editorTimeTitle => 'Alım saati';

  @override
  String get editorTimeHelp => 'Her gün aynı saatte';

  @override
  String editorWeeklyTotal(String total) {
    return 'Haftalık toplam: $total';
  }

  @override
  String get editorAmountLabel => 'Miktar (mg)';

  @override
  String get ok => 'Tamam';

  @override
  String editorDeleteTitle(String medication) {
    return '$medication silinsin mi?';
  }

  @override
  String get editorDoseSection => 'Doz';

  @override
  String get editorNoteLabel => 'Not (opsiyonel)';
}

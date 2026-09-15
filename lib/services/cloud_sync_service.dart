/// Bulut Yedek & Çoklu Cihaz Senkronizasyonu (premium).
///
/// Kapsam: hasta profili, INR ölçümleri ve ilaç planı. Alım kayıtları
/// (`DoseIntake`) bilinçli olarak dışarıda — günde birkaç satır üretirler,
/// klinik değerleri düşüktür ve senkron maliyetini gereksiz büyütürler.
///
/// **Kaynak-doğruluk yereldir (sqflite).** Bulut ikinci bir kalıcı katman
/// ve yeni cihaza taşıma yoludur; uygulama bulut erişilemezken tam işlevle
/// çalışmaya devam eder.
///
/// Birleştirme kuralı (her senkron döngüsünde, bu sırayla):
///   1. **Çek (pull):** bulutta olup yerelde olmayan kayıtlar yerele eklenir.
///      Yereldeki kayıtların üzerine yazılmaz — bu cihazda yapılmış bir
///      düzenleme sessizce kaybolmamalıdır. Yerelde **silinmiş** kayıtlar
///      ([DeletionLog]) çekmede atlanır; aksi hâlde silinen ölçüm bir
///      sonraki senkronda geri gelirdi ("hortlama").
///   2. **Gönder (push):** tüm yerel kayıtlar buluta yazılır, ardından
///      silme defterindeki kayıtlar buluttan silinir ve defterden düşülür.
///      Silme kullanıcının açık eylemi olduğu için çekme başarısız olsa
///      bile uygulanır — ama defter ancak bulut silmesi başarılıysa
///      temizlenir, böylece ağ hatasında silme kaybolmaz.
///
/// BİLİNEN SINIR: kayıt *düzenlemesi* cihazlar arasında yayılmaz — aynı id
/// iki cihazda farklı düzenlenirse her cihaz kendi sürümünü korur (son
/// gönderen bulutta kazanır). Kesin çözüm modele kayıt bazlı `updatedAt`
/// eklemeyi gerektirir; ölçüm ve ilaç verisi ağırlıklı olarak "ekleme"
/// tipinde olduğu için bu sürümde yapılmadı. Çakışmada veri kaybetmek
/// yerine fazladan kayıt tutmak, klinik veride doğru olan hata yönüdür.
library;

import '../models/inr_entry.dart';
import '../models/medication.dart';
import '../models/patient_profile.dart';
import '../repositories/repositories.dart';
import '../repositories/sqflite_repositories.dart' show SyncCollections;

/// Bulut tarafının soyutlaması — testte sahte (fake) ile değiştirilir,
/// üretimde `FirestoreCloudGateway`. Servis `cloud_firestore` paketini
/// hiç görmez (bkz. ARCHITECTURE.md "Temiz kod kararları").
abstract interface class CloudGateway {
  Future<PatientProfile?> fetchProfile(String uid);
  Future<void> saveProfile(String uid, PatientProfile profile);

  Future<List<InrEntry>> fetchEntries(String uid);
  Future<void> saveEntries(String uid, List<InrEntry> entries);
  Future<void> deleteEntries(String uid, List<String> ids);

  Future<List<Medication>> fetchMedications(String uid);
  Future<void> saveMedications(String uid, List<Medication> medications);
  Future<void> deleteMedications(String uid, List<String> ids);

  /// Kullanıcının buluttaki tüm ağacını siler (hesap silme).
  Future<void> deleteAllUserData(String uid);
}

/// Bir senkron döngüsünün sonucu — UI'da "3 ölçüm geri yüklendi" gibi
/// geri bildirim vermek ve testte doğrulamak için.
class CloudSyncResult {
  final int pulledEntries;
  final int pulledMedications;
  final int pushedEntries;
  final int pushedMedications;

  /// Buluttaki profil yerele yazıldı mı (başka cihazda güncellenmişti).
  final bool profileRestored;

  /// Buluttan silinen (yerelde kullanıcının sildiği) kayıt sayısı.
  final int deletedRemote;

  /// Çekme başarısız olduysa yalnızca gönderim yapıldı.
  final bool pullFailed;

  const CloudSyncResult({
    this.pulledEntries = 0,
    this.pulledMedications = 0,
    this.pushedEntries = 0,
    this.pushedMedications = 0,
    this.deletedRemote = 0,
    this.profileRestored = false,
    this.pullFailed = false,
  });

  /// Yerel veriye dokunuldu mu — UI'ın kendini tazelemesi gerekir.
  bool get changedLocalData =>
      pulledEntries > 0 || pulledMedications > 0 || profileRestored;
}

class CloudSyncService {
  final CloudGateway _cloud;
  final InrRepository _inrRepo;
  final MedicationRepository _medicationRepo;
  final ProfileRepository _profileRepo;
  final DeletionLog _deletions;

  const CloudSyncService(
    this._cloud,
    this._inrRepo,
    this._medicationRepo,
    this._profileRepo,
    this._deletions,
  );

  /// Profili tek başına gönderir (Profil ekranında "Kaydet" sonrası).
  Future<void> pushProfile(String uid, PatientProfile profile) =>
      _cloud.saveProfile(uid, profile);

  /// Hesap silinirken buluttaki profil, ölçüm ve ilaç kayıtlarını siler.
  /// [syncAll]'dan farklı olarak hatayı yutmaz: silme doğrulanmadan hesap
  /// silinmemelidir.
  Future<void> deleteAllRemote(String uid) => _cloud.deleteAllUserData(uid);

  /// Tam senkron döngüsü. Hata fırlatmaz: bulut erişilemezse uygulama
  /// yerel veriyle çalışmaya devam etmelidir.
  Future<CloudSyncResult> syncAll(String uid) async {
    var pullFailed = false;
    var pulledEntries = 0;
    var pulledMedications = 0;
    var profileRestored = false;

    // Silinen kayıtlar hem çekmede atlanır hem de buluttan silinir.
    final deletedEntryIds =
        await _deletions.pending(SyncCollections.inrEntries);
    final deletedMedicationIds =
        await _deletions.pending(SyncCollections.medications);

    // --- 1) ÇEK ---
    try {
      final remoteProfile = await _cloud.fetchProfile(uid);
      // Yerelde profil yoksa (yeni cihaz) buluttaki geri yüklenir;
      // varsa yerel korunur.
      if (remoteProfile != null && await _profileRepo.getProfile() == null) {
        await _profileRepo.saveProfile(remoteProfile);
        profileRestored = true;
      }

      final localEntryIds =
          (await _inrRepo.getEntries()).map((e) => e.id).toSet();
      for (final entry in await _cloud.fetchEntries(uid)) {
        if (localEntryIds.contains(entry.id)) continue;
        if (deletedEntryIds.contains(entry.id)) continue;
        await _inrRepo.upsert(entry);
        pulledEntries++;
      }

      final localMedIds =
          (await _medicationRepo.getAll()).map((m) => m.id).toSet();
      for (final medication in await _cloud.fetchMedications(uid)) {
        if (localMedIds.contains(medication.id)) continue;
        if (deletedMedicationIds.contains(medication.id)) continue;
        await _medicationRepo.upsert(medication);
        pulledMedications++;
      }
    } catch (_) {
      pullFailed = true;
    }

    // --- 2) GÖNDER ---
    final localEntries = await _inrRepo.getEntries();
    final localMedications = await _medicationRepo.getAll();
    final localProfile = await _profileRepo.getProfile();

    try {
      if (localProfile != null) {
        await _cloud.saveProfile(uid, localProfile);
      }
      await _cloud.saveEntries(uid, localEntries);
      await _cloud.saveMedications(uid, localMedications);
    } catch (_) {
      // Gönderim başarısız: yerel veri bozulmadı, sonraki döngüde tekrar
      // denenir. Kullanıcıya hata göstermeye değmez.
      return CloudSyncResult(
        pulledEntries: pulledEntries,
        pulledMedications: pulledMedications,
        profileRestored: profileRestored,
        pullFailed: pullFailed,
      );
    }

    // --- 3) SİL ---
    // Defter yalnızca bulut silmesi başarılıysa temizlenir: ağ hatasında
    // silme unutulmamalı.
    var deletedRemote = 0;
    if (deletedEntryIds.isNotEmpty) {
      try {
        await _cloud.deleteEntries(uid, deletedEntryIds.toList());
        await _deletions.clear(SyncCollections.inrEntries, deletedEntryIds);
        deletedRemote += deletedEntryIds.length;
      } catch (_) {
        // Sonraki döngüde tekrar denenir.
      }
    }
    if (deletedMedicationIds.isNotEmpty) {
      try {
        await _cloud.deleteMedications(uid, deletedMedicationIds.toList());
        await _deletions.clear(
            SyncCollections.medications, deletedMedicationIds);
        deletedRemote += deletedMedicationIds.length;
      } catch (_) {
        // Sonraki döngüde tekrar denenir.
      }
    }

    return CloudSyncResult(
      pulledEntries: pulledEntries,
      pulledMedications: pulledMedications,
      pushedEntries: localEntries.length,
      pushedMedications: localMedications.length,
      deletedRemote: deletedRemote,
      profileRestored: profileRestored,
      pullFailed: pullFailed,
    );
  }
}

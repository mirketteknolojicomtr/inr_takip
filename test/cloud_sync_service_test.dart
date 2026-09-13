/// Bulut senkronu birleştirme kuralları.
///
/// En kritik iki davranış:
///  - Çekme, yereldeki bir kaydın üzerine YAZMAZ (bu cihazdaki düzenleme
///    sessizce kaybolmamalı).
///  - Buluttaki fazlalık kayıtların silinmesi YALNIZCA başarılı bir
///    çekmeden sonra yapılır; ağ hatasında bulut verisi silinmemeli.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/models/inr_entry.dart';
import 'package:inr_takip/models/medication.dart';
import 'package:inr_takip/models/patient_profile.dart';
import 'package:inr_takip/repositories/repositories.dart';
import 'package:inr_takip/repositories/sqflite_repositories.dart'
    show SyncCollections;
import 'package:inr_takip/services/cloud_sync_service.dart';

/// Belleğe yazan sahte bulut. [failFetch] ile ağ hatası taklit edilir.
class FakeCloudGateway implements CloudGateway {
  final entries = <String, InrEntry>{};
  final medications = <String, Medication>{};
  PatientProfile? profile;

  bool failFetch = false;
  final deletedEntryIds = <String>[];
  final deletedMedicationIds = <String>[];

  void _guard() {
    if (failFetch) throw Exception('ağ yok');
  }

  @override
  Future<PatientProfile?> fetchProfile(String uid) async {
    _guard();
    return profile;
  }

  @override
  Future<void> saveProfile(String uid, PatientProfile p) async => profile = p;

  @override
  Future<List<InrEntry>> fetchEntries(String uid) async {
    _guard();
    return entries.values.toList();
  }

  @override
  Future<void> saveEntries(String uid, List<InrEntry> items) async {
    for (final e in items) {
      entries[e.id] = e;
    }
  }

  @override
  Future<void> deleteEntries(String uid, List<String> ids) async {
    deletedEntryIds.addAll(ids);
    for (final id in ids) {
      entries.remove(id);
    }
  }

  @override
  Future<List<Medication>> fetchMedications(String uid) async {
    _guard();
    return medications.values.toList();
  }

  @override
  Future<void> saveMedications(String uid, List<Medication> items) async {
    for (final m in items) {
      medications[m.id] = m;
    }
  }

  @override
  Future<void> deleteMedications(String uid, List<String> ids) async {
    deletedMedicationIds.addAll(ids);
    for (final id in ids) {
      medications.remove(id);
    }
  }
}

InrEntry entry(String id, double inr, {double dose = 5}) => InrEntry(
      id: id,
      date: DateTime(2026, 1, 1),
      inrValue: inr,
      doseMg: dose,
      targetRange: TargetRange.standard,
    );

Medication med(String id, String name) => Medication(
      id: id,
      name: name,
      startDate: DateTime(2026, 1, 1),
      times: const [DoseTime(hour: 19, minute: 0, amountMg: 5)],
    );

void main() {
  late FakeCloudGateway cloud;
  late InMemoryInrRepository inrRepo;
  late InMemoryMedicationRepository medRepo;
  late InMemoryProfileRepository profileRepo;
  late InMemoryDeletionLog deletions;
  late CloudSyncService service;

  setUp(() {
    cloud = FakeCloudGateway();
    inrRepo = InMemoryInrRepository();
    medRepo = InMemoryMedicationRepository();
    profileRepo = InMemoryProfileRepository();
    deletions = InMemoryDeletionLog();
    service =
        CloudSyncService(cloud, inrRepo, medRepo, profileRepo, deletions);
  });

  test('yeni cihaz: buluttaki profil, ölçüm ve ilaçlar yerele iner',
      () async {
    cloud.profile = const PatientProfile(name: 'Ayşe');
    cloud.entries['e1'] = entry('e1', 2.4);
    cloud.medications['m1'] = med('m1', 'Coumadin');

    final result = await service.syncAll('uid');

    expect(result.profileRestored, isTrue);
    expect(result.pulledEntries, 1);
    expect(result.pulledMedications, 1);
    expect((await inrRepo.getEntries()).single.inrValue, 2.4);
    expect((await medRepo.getAll()).single.name, 'Coumadin');
  });

  test('yerelde var olan kaydın üzerine bulut sürümü yazılmaz', () async {
    await inrRepo.upsert(entry('e1', 2.4, dose: 5));
    await profileRepo.saveProfile(const PatientProfile(name: 'Yerel'));
    cloud.entries['e1'] = entry('e1', 9.9, dose: 1);
    cloud.profile = const PatientProfile(name: 'Bulut');

    final result = await service.syncAll('uid');

    expect(result.pulledEntries, 0, reason: 'çakışan kayıt çekilmemeli');
    expect(result.profileRestored, isFalse);
    expect((await inrRepo.getEntries()).single.inrValue, 2.4);
    expect((await profileRepo.getProfile())!.name, 'Yerel');
    // Gönderim yereli kazandırır: bulut da 2.4 olur.
    expect(cloud.entries['e1']!.inrValue, 2.4);
  });

  test('yerel kayıtlar buluta gönderilir', () async {
    await inrRepo.upsert(entry('e1', 2.1));
    await inrRepo.upsert(entry('e2', 3.2));
    await medRepo.upsert(med('m1', 'Coumadin'));
    await profileRepo.saveProfile(const PatientProfile(name: 'Ayşe'));

    final result = await service.syncAll('uid');

    expect(result.pushedEntries, 2);
    expect(result.pushedMedications, 1);
    expect(cloud.entries.keys, containsAll(['e1', 'e2']));
    expect(cloud.profile!.name, 'Ayşe');
  });

  test('yerelde silinmiş kayıt buluttan da silinir ve geri gelmez', () async {
    cloud.entries['e1'] = entry('e1', 2.1);
    cloud.entries['e2'] = entry('e2', 3.2);
    await inrRepo.upsert(entry('e1', 2.1));
    await service.syncAll('uid'); // 1. döngü: e2 yerele iner

    await inrRepo.delete('e2');
    await deletions.record(SyncCollections.inrEntries, 'e2');

    final result = await service.syncAll('uid');

    expect(result.deletedRemote, 1);
    expect(cloud.deletedEntryIds, ['e2']);
    expect(cloud.entries.keys, ['e1']);
    expect((await inrRepo.getEntries()).map((e) => e.id), ['e1'],
        reason: 'silinen kayıt çekmede geri gelmemeli');
    expect(await deletions.pending(SyncCollections.inrEntries), isEmpty,
        reason: 'bulutta silindikten sonra defter temizlenmeli');
  });

  test('silinen kayıt bulutta hâlâ dururken bile yerele geri dönmez',
      () async {
    // Bulut silmesi ağ hatasıyla başarısız olsa da çekme onu atlamalı.
    cloud.entries['e2'] = entry('e2', 3.2);
    await deletions.record(SyncCollections.inrEntries, 'e2');

    await service.syncAll('uid');

    expect(await inrRepo.getEntries(), isEmpty);
  });

  test('çekme başarısız olsa da kullanıcının silmesi buluta işlenir',
      () async {
    cloud.entries['e2'] = entry('e2', 3.2);
    await inrRepo.upsert(entry('yerel', 2.2));
    await deletions.record(SyncCollections.inrEntries, 'e2');
    cloud.failFetch = true;

    final result = await service.syncAll('uid');

    expect(result.pullFailed, isTrue);
    expect(cloud.deletedEntryIds, ['e2'],
        reason: 'silme açık kullanıcı eylemidir, çekmeye bağlı değildir');
    expect(cloud.entries.keys, ['yerel'],
        reason: 'gönderim yine de yapılmalı');
  });

  test('bulut tamamen erişilemezse hata fırlatmaz', () async {
    cloud.failFetch = true;
    await inrRepo.upsert(entry('e1', 2.0));

    expect(() => service.syncAll('uid'), returnsNormally);
  });
}

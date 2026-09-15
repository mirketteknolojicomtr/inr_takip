/// [CloudGateway]'in Firestore implementasyonu — tek Firestore-bağımlı dosya.
///
/// Doküman düzeni:
///   users/{uid}                      -> profil alanları
///   users/{uid}/inr_entries/{id}     -> InrEntry.toJson()
///   users/{uid}/medications/{id}     -> Medication.toJson()
///
/// Güvenlik kuralları (firestore.rules) kullanıcıyı kendi ağacına kilitler:
/// `match /users/{userId}/{document=**}` altında `request.auth.uid == userId`.
///
/// Yazmalar `WriteBatch` ile toplanır: hem tek ağ gidiş-dönüşü hem de
/// atomiklik sağlar. Firestore'un parti (batch) sınırı 500 işlemdir; daha
/// büyük listeler parçalara bölünür.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/inr_entry.dart';
import '../models/medication.dart';
import '../models/patient_profile.dart';
import 'cloud_sync_service.dart';

class FirestoreCloudGateway implements CloudGateway {
  /// Firestore tek partide en fazla 500 işlem kabul eder.
  static const _batchLimit = 400;

  final FirebaseFirestore _firestore;

  FirestoreCloudGateway({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _entries(String uid) =>
      _userDoc(uid).collection('inr_entries');

  CollectionReference<Map<String, dynamic>> _medications(String uid) =>
      _userDoc(uid).collection('medications');

  @override
  Future<PatientProfile?> fetchProfile(String uid) async {
    final snapshot = await _userDoc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return PatientProfile.fromJson(data);
  }

  @override
  Future<void> saveProfile(String uid, PatientProfile profile) {
    return _userDoc(uid).set({
      ...profile.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<InrEntry>> fetchEntries(String uid) async {
    final snapshot = await _entries(uid).get();
    return snapshot.docs.map((d) => InrEntry.fromJson(d.data())).toList();
  }

  @override
  Future<void> saveEntries(String uid, List<InrEntry> entries) {
    return _writeAll(
      items: entries,
      idOf: (e) => e.id,
      jsonOf: (e) => e.toJson(),
      collection: _entries(uid),
    );
  }

  @override
  Future<void> deleteEntries(String uid, List<String> ids) =>
      _deleteAll(ids: ids, collection: _entries(uid));

  @override
  Future<List<Medication>> fetchMedications(String uid) async {
    final snapshot = await _medications(uid).get();
    return snapshot.docs.map((d) => Medication.fromJson(d.data())).toList();
  }

  @override
  Future<void> saveMedications(String uid, List<Medication> medications) {
    return _writeAll(
      items: medications,
      idOf: (m) => m.id,
      jsonOf: (m) => m.toJson(),
      collection: _medications(uid),
    );
  }

  @override
  Future<void> deleteMedications(String uid, List<String> ids) =>
      _deleteAll(ids: ids, collection: _medications(uid));

  /// Firestore alt koleksiyonları üst doküman silinince kendiliğinden
  /// silinmez; önce ölçümler ve ilaçlar, en son profil dokümanı silinir.
  @override
  Future<void> deleteAllUserData(String uid) async {
    for (final collection in [_entries(uid), _medications(uid)]) {
      final snapshot = await collection.get();
      await _deleteAll(
        ids: snapshot.docs.map((d) => d.id).toList(),
        collection: collection,
      );
    }
    await _userDoc(uid).delete();
  }

  Future<void> _writeAll<T>({
    required List<T> items,
    required String Function(T) idOf,
    required Map<String, dynamic> Function(T) jsonOf,
    required CollectionReference<Map<String, dynamic>> collection,
  }) async {
    for (var i = 0; i < items.length; i += _batchLimit) {
      final chunk = items.skip(i).take(_batchLimit);
      final batch = _firestore.batch();
      for (final item in chunk) {
        batch.set(collection.doc(idOf(item)), jsonOf(item));
      }
      await batch.commit();
    }
  }

  Future<void> _deleteAll({
    required List<String> ids,
    required CollectionReference<Map<String, dynamic>> collection,
  }) async {
    for (var i = 0; i < ids.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final id in ids.skip(i).take(_batchLimit)) {
        batch.delete(collection.doc(id));
      }
      await batch.commit();
    }
  }
}

/// Yerel profili ([SqfliteProfileRepository]) Firestore'a yedekleyen/
/// senkronize eden servis. sqflite kaynak-doğruluk (source of truth) olarak
/// kalır; Firestore ikinci bir kalıcı katman + çok cihazlı senkron sağlar.
///
/// Doküman yolu: `users/{uid}` -- Firestore güvenlik kuralları (bkz.
/// firestore.rules) yalnızca `request.auth.uid == uid` olan kullanıcının
/// kendi dokümanına erişmesine izin verir.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/patient_profile.dart';

class FirestoreProfileSyncService {
  final FirebaseFirestore _firestore;

  FirestoreProfileSyncService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Yerel kayıt sonrası (Profil ekranından "Kaydet") çağrılır.
  Future<void> push(String uid, PatientProfile profile) async {
    await _doc(uid).set({
      ...profile.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Girişte çağrılır: buluttaki profili döndürür (varsa) -- yeni bir
  /// cihazda oturum açıldığında yerel veriyi bulutla senkronlamak için.
  Future<PatientProfile?> pull(String uid) async {
    final snapshot = await _doc(uid).get();
    final data = snapshot.data();
    if (data == null) return null;
    return PatientProfile.fromJson(data);
  }
}

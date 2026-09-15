/// Firebase Authentication (e-posta/parola) sarmalayıcısı.
/// Çok cihazlı senkron için: profil Firestore'da bu kullanıcının UID'si
/// altında saklanır (bkz. cloud_sync_service.dart).
library;

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  /// Hesap silme gibi hassas işlemlerden önce parolayla yeniden doğrular.
  /// Firebase eski oturumda silmeyi "requires-recent-login" ile reddeder;
  /// önceden doğrulayınca bu hata kullanıcıya hiç yansımaz.
  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  }

  /// Firebase hesabını kalıcı olarak siler; oturum da kapanır.
  Future<void> deleteCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');
    await user.delete();
  }
}

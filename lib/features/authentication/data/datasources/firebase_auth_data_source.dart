import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/errors/app_exception.dart';

/// Envuelve `firebase_auth` y traduce sus excepciones a [AuthException] —
/// ningún otro archivo del proyecto debe importar `package:firebase_auth`
/// directamente (ver skill `nutrition-app-architecture`, separación de capas).
class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._firebaseAuth);

  final fb.FirebaseAuth _firebaseAuth;

  Stream<fb.User?> authStateChanges() => _firebaseAuth.authStateChanges();

  fb.User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code, code: e.code, cause: e);
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code, code: e.code, cause: e);
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      // Nunca revelamos si la cuenta existe: se silencia específicamente
      // este código y se deja pasar cualquier otro (email inválido, red).
      if (e.code == 'user-not-found') return;
      throw AuthException(e.message ?? e.code, code: e.code, cause: e);
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();
}

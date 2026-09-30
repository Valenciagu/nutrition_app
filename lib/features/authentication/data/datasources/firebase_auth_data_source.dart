import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/errors/app_exception.dart';

/// Envuelve `firebase_auth` y traduce sus excepciones a [AuthException] —
/// ningún otro archivo del proyecto debe importar `package:firebase_auth`
/// directamente (ver skill `nutrition-app-architecture`, separación de capas).
/// También envuelve `google_sign_in` por la misma razón — es el único
/// archivo que conoce ese paquete.
class FirebaseAuthDataSource {
  FirebaseAuthDataSource(this._firebaseAuth, this._googleSignIn);

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

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

  /// Devuelve `false` (sin lanzar excepción) si el usuario cierra el
  /// selector de cuentas de Google sin elegir una — no es un error, es una
  /// cancelación explícita del usuario, igual de válida que no tocar el
  /// botón "Entrar".
  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final googleAuth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code, code: e.code, cause: e);
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}

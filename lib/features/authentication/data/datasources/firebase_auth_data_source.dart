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

  /// Sesión anónima para B8 (Onboarding): deja generar y guardar un plan
  /// antes de pedir cuenta, con el mismo `uid` real que las reglas de
  /// Firestore y `generateDailyPlan` ya exigen — no toca nada si ya hay una
  /// sesión (anónima o real) activa.
  Future<void> signInAnonymously() async {
    if (_firebaseAuth.currentUser != null) return;
    try {
      await _firebaseAuth.signInAnonymously();
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code, code: e.code, cause: e);
    }
  }

  Future<void> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? e.code, code: e.code, cause: e);
    }
  }

  /// Si ya hay una sesión anónima (venida de B8, ver `signInAnonymously`),
  /// **asciende** esa misma cuenta con `linkWithCredential` en vez de crear
  /// una nueva — conserva el `uid`, y con él el perfil/plan ya escritos en
  /// Firestore durante el onboarding. Si el email ya pertenece a otra cuenta
  /// real (`email-already-in-use` al intentar `link`), no hay nada que
  /// enlazar: se deja la excepción tal cual, la UI ya sabe mostrar ese caso
  /// (mismo código de error que un registro normal duplicado).
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final anonymousUser = _firebaseAuth.currentUser;
      final credential = fb.EmailAuthProvider.credential(email: email, password: password);
      final result = anonymousUser != null && anonymousUser.isAnonymous
          ? await anonymousUser.linkWithCredential(credential)
          : await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      await result.user?.updateDisplayName(displayName);
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
  ///
  /// Mismo ascenso que `signUpWithEmailAndPassword` si hay una sesión
  /// anónima activa (B8): `linkWithCredential` conserva el `uid` y, con él,
  /// el perfil/plan ya generados. Si esa cuenta de Google ya está ligada a
  /// OTRA cuenta real (`credential-already-in-use` — alguien que onboardeó
  /// de invitado y luego elige Google con una cuenta que ya existía), se
  /// cae a un login normal sobre esa cuenta existente: es el único caso
  /// donde el perfil/plan generados en esta sesión anónima se abandonan, y
  /// es el comportamiento que la propia documentación de Firebase recomienda
  /// para este conflicto.
  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final googleAuth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final anonymousUser = _firebaseAuth.currentUser;
      if (anonymousUser != null && anonymousUser.isAnonymous) {
        try {
          await anonymousUser.linkWithCredential(credential);
          return true;
        } on fb.FirebaseAuthException catch (e) {
          if (e.code != 'credential-already-in-use') rethrow;
        }
      }
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

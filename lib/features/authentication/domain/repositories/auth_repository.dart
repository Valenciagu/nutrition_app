import '../entities/auth_user.dart';

/// Contrato de autenticación. La implementación concreta (Firebase Auth hoy,
/// potencialmente otra cosa mañana) vive en `data/` — el resto de la app
/// solo conoce esta interfaz.
abstract class AuthRepository {
  /// Emite el usuario actual cada vez que cambia el estado de sesión
  /// (login, logout, expiración de token). Lo consume el router para las
  /// reglas de redirección.
  Stream<AuthUser?> authStateChanges();

  /// Snapshot síncrono del usuario actual, útil para el `redirect` de
  /// GoRouter (que no puede esperar un `Future`).
  AuthUser? get currentUser;

  Future<void> signInWithEmailAndPassword({required String email, required String password});

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Siempre se completa sin error, exista o no una cuenta con [email] —
  /// revelar esa información es un riesgo de privacidad/seguridad (ver
  /// skill `nutrition-app-security` e Instrucciones.md §33).
  Future<void> sendPasswordResetEmail({required String email});

  /// Devuelve `false` si el usuario canceló el selector de cuentas de
  /// Google (no es un error) — `true` si quedó autenticado.
  Future<bool> signInWithGoogle();

  Future<void> signOut();
}

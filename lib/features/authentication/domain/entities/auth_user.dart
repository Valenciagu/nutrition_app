/// Usuario autenticado, independiente de Firebase. La capa de datos mapea
/// `firebase_auth`'s `User` a esto — el dominio y la presentación nunca
/// deben importar `package:firebase_auth`.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.isAnonymous = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  /// true para la sesión anónima que arranca B8 (Onboarding) para poder
  /// generar un plan antes de pedir cuenta — ver `documentation/onboarding.md`
  /// y `AuthController.ensureAnonymousSession`. El router la trata como
  /// "con sesión" (puede navegar el shell principal sin que la rebote a
  /// Welcome), pero no como una cuenta real (no debe bloquear el acceso a
  /// Login/SignUp, a diferencia de una sesión real).
  final bool isAnonymous;
}

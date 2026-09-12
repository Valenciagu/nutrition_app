/// Usuario autenticado, independiente de Firebase. La capa de datos mapea
/// `firebase_auth`'s `User` a esto — el dominio y la presentación nunca
/// deben importar `package:firebase_auth`.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;
}

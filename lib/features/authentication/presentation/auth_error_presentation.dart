import '../../../core/errors/failure.dart';
import '../../../core/localization/generated/app_localizations.dart';

/// A qué campo (si aplica) pertenece el mensaje de error de una operación
/// de auth. Mantiene el mapeo código-de-Firebase → copy localizado fuera
/// de los widgets, en un único lugar por feature.
class AuthErrorPresentation {
  const AuthErrorPresentation({this.emailError, this.passwordError, this.generalError});

  final String? emailError;
  final String? passwordError;
  final String? generalError;
}

/// Traduce el `code` de un [AuthFailure] a copy localizado.
///
/// Importante: credenciales inválidas (email o contraseña incorrectos)
/// siempre se muestran como error de contraseña con el mismo mensaje
/// genérico — nunca revelamos si el correo existe o no en el sistema
/// (ver Fase 2 · Bloque A e Instrucciones.md §33).
AuthErrorPresentation mapAuthError(AppLocalizations l10n, Object error) {
  final code = error is AuthFailure ? error.code : null;

  switch (code) {
    case 'wrong-password':
    case 'user-not-found':
    case 'invalid-credential':
      return AuthErrorPresentation(passwordError: l10n.authErrorInvalidCredentials);
    case 'invalid-email':
      return AuthErrorPresentation(emailError: l10n.authErrorInvalidEmail);
    case 'email-already-in-use':
      return AuthErrorPresentation(emailError: l10n.authErrorEmailAlreadyInUse);
    case 'weak-password':
      return AuthErrorPresentation(passwordError: l10n.authErrorWeakPassword);
    case 'too-many-requests':
      return AuthErrorPresentation(generalError: l10n.authErrorTooManyRequests);
    default:
      return AuthErrorPresentation(generalError: l10n.authErrorGeneric);
  }
}

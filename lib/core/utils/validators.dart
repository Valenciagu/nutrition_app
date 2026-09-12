/// Validadores puramente sintácticos para UX en el cliente. La validación
/// real de seguridad/integridad siempre ocurre también en el backend
/// (Firebase Auth, Cloud Functions) — esto nunca sustituye esa capa.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

  /// Mínimo 8 caracteres, igual que en la ficha de registro.
  static bool isValidPassword(String value) => value.length >= 8;

  /// Heurística simple solo para el indicador visual de fuerza — no es una
  /// política de seguridad real, esa vive en Firebase Auth (mínimo 6-8
  /// caracteres) y no debe duplicarse aquí con reglas más estrictas.
  static PasswordStrength passwordStrength(String value) {
    if (value.length < 8) return PasswordStrength.weak;
    final hasNumber = RegExp(r'\d').hasMatch(value);
    final hasSymbolOrUpper = RegExp(r'[A-Z!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value);
    if (hasNumber && hasSymbolOrUpper) return PasswordStrength.strong;
    if (hasNumber || hasSymbolOrUpper) return PasswordStrength.medium;
    return PasswordStrength.medium;
  }
}

enum PasswordStrength { weak, medium, strong }

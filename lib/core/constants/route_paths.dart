/// Centralized route path constants. Add one entry per screen as features
/// are built — never inline a route string literal inside a widget.
abstract final class RoutePaths {
  static const String root = '/';

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';

  /// Rutas que no requieren sesión — usadas por el `redirect` del router.
  static const List<String> publicRoutes = [splash, welcome, login, signUp, forgotPassword];

  // Reservado para próximas épicas: onboarding, home, plan de nutrición,
  // recetas, análisis de fotos, lista de compras, perfil, suscripción.
}

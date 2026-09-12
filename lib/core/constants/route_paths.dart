/// Centralized route path constants. Add one entry per screen as features
/// are built — never inline a route string literal inside a widget.
abstract final class RoutePaths {
  static const String root = '/';

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String onboarding = '/onboarding';

  /// Tabs del shell principal (Épica 4) — `root` es Home. Plan/IA/Perfil son
  /// placeholders (`ComingSoonPage`/`ProfilePlaceholderPage`) hasta que sus
  /// épicas (6/5/11) existan. No hay tab de "Progreso" ni de cámara: la
  /// cámara es el botón central del shell, no una ruta con tab propia (ver
  /// `documentation/home.md` y la decisión de navegación confirmada
  /// 2026-09-12).
  static const String plan = '/plan';
  static const String ai = '/ai';
  static const String profile = '/profile';

  /// Rutas donde un usuario sin sesión puede quedarse (no lo mandan a
  /// Welcome). `splash` NO va aquí a propósito: es una parada transitoria
  /// que siempre redirige hacia otro lado, nunca un destino final — ver el
  /// `redirect` en `app_router.dart`.
  static const List<String> publicRoutes = [welcome, login, signUp, forgotPassword];

  /// Rutas a las que puede entrar un invitado sin sesión mientras
  /// `guestModeProvider` esté activo (ver `app_router.dart` y
  /// `documentation/authentication.md`) — las 4 tabs del shell principal y
  /// `onboarding` (iniciado desde Welcome · "Empezar").
  static const List<String> guestAccessibleRoutes = [root, plan, ai, profile, onboarding];

  // Reservado para próximas épicas: plan de nutrición, recetas, análisis de
  // fotos, lista de compras, suscripción.
}

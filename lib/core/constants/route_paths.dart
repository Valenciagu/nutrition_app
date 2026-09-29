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

  /// Tabs del shell principal (Épica 4) — `root` es Home, Plan (Épica 6),
  /// Perfil (Épica 11) y `ai` (Épica 5's `AIService`, finalmente con un
  /// consumidor real — ver `features/ai_assistant/`) son reales. No hay tab
  /// de "Progreso" ni de cámara: la cámara es el botón central del shell,
  /// no una ruta con tab propia (ver `documentation/home.md` y la decisión
  /// de navegación confirmada 2026-09-12).
  static const String plan = '/plan';
  static const String ai = '/ai';
  static const String profile = '/profile';

  /// Épica 8 — nivel superior, no anidada bajo ningún tab: el botón de
  /// cámara vive en `MainShell`, fuera de las 4 pilas de navegación de las
  /// tabs. Los bytes de la foto ya capturada viajan por `extra` de
  /// GoRouter (binario, no cabe en la URL).
  static const String foodAnalysis = '/food-analysis';

  /// D3 (Épica 7) — anidada bajo `plan` (no una tab propia) para que D3 y D5
  /// vivan en la pila de navegación del tab Plan, con el back nativo
  /// funcionando sin lógica extra. `recipe` toma `date`/`mealId`, no
  /// `recipeId` — la Cloud Function decide server-side si genera una receta
  /// nueva o reutiliza la existente (ver `documentation/recipes.md`).
  static const String recipeDetailSegment = 'recipe/:date/:mealId';
  static String recipeDetailPath(String date, String mealId) => '$plan/recipe/$date/$mealId';

  /// Épica 10 — anidada bajo `plan` igual que D3/D5: se llega desde la fila
  /// "Generar lista de compra" de D1.
  static const String groceryListSegment = 'grocery-list';
  static String groceryListPath() => '$plan/grocery-list';

  /// Épica 11 — anidadas bajo `profile`, mismo criterio que D3/D5/lista de
  /// compra bajo `plan`: el back nativo funciona sin lógica extra.
  static const String profileEditGoalSegment = 'edit-goal';
  static String profileEditGoalPath() => '$profile/edit-goal';

  static const String profileEditPreferencesSegment = 'edit-preferences';
  static String profileEditPreferencesPath() => '$profile/edit-preferences';

  static const String profilePrivacySegment = 'privacy';
  static String profilePrivacyPath() => '$profile/privacy';

  static const String profileNotificationsSegment = 'notifications';
  static String profileNotificationsPath() => '$profile/notifications';

  /// D5 — anidada bajo D3; recibe la `Recipe` ya cargada vía `extra` de
  /// GoRouter en vez de re-pedirla, para no depender de que el provider de
  /// D3 siga vivo/cacheado al navegar.
  static const String cookingModeSegment = 'cook';
  static String cookingModePath(String date, String mealId) => '${recipeDetailPath(date, mealId)}/cook';

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

import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/sign_up_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/welcome_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/ai_assistant/presentation/pages/ai_chat_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../features/food_analysis/presentation/pages/food_analysis_page.dart';
import '../../features/grocery_list/presentation/pages/grocery_list_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/plan/presentation/pages/plan_page.dart';
import '../../features/profile/presentation/pages/edit_goal_biometrics_page.dart';
import '../../features/profile/presentation/pages/edit_preferences_page.dart';
import '../../features/profile/presentation/pages/privacy_data_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/recipes/domain/entities/recipe.dart';
import '../../features/recipes/presentation/pages/cooking_mode_page.dart';
import '../../features/recipes/presentation/pages/recipe_detail_page.dart';
import '../constants/route_paths.dart';
import 'main_shell.dart';

/// El único [GoRouter] de la app. No crear otros routers ni navegar con
/// `Navigator` crudo — extender este en su lugar.
///
/// La guarda de sesión vive en `redirect`: mientras
/// `authStateChangesProvider` no ha resuelto (arranque en frío) se queda en
/// Splash; resuelto, manda a Welcome (sin sesión) o Home (con sesión).
/// "Empezar" en Welcome lleva al Onboarding (Épica 3); "Seguir sin cuenta"
/// en SignUp y el final del Onboarding llevan a Home.
///
/// `RoutePaths.root/plan/ai/profile` viven dentro de un
/// [StatefulShellRoute] (`MainShell`, 4 tabs + cámara central — decisión de
/// navegación confirmada 2026-09-12, ver `documentation/home.md`) para que
/// cada tab mantenga su propia pila de navegación independiente.
final routerProvider = Provider<GoRouter>((ref) {
  // Importante: se notifica via `ref.listen` sobre el MISMO
  // `authStateChangesProvider` que lee `redirect` más abajo (con
  // `ref.read`) — no una suscripción nueva/independiente a
  // `.authStateChanges()`. Dos suscripciones independientes al stream de
  // Firebase no garantizan orden entre sí: el router podía "despertar"
  // antes de que `authStateChangesProvider` ya tuviera el valor
  // actualizado y, como no volvía a despertar, se quedaba pegado en
  // Splash. `ref.listen` sobre el propio provider garantiza que su caché
  // ya está al día en el momento en que se notifica.
  final refreshNotifier = _RouterRefreshNotifier();
  ref.listen(authStateChangesProvider, (previous, next) {
    refreshNotifier.notify();
    // Composición: el router es quien conoce tanto Auth como Onboarding
    // (ninguna feature debería depender de la otra directamente). Al pasar
    // de "sin sesión" a "con sesión" (signIn o signUp), si hay un borrador
    // de Onboarding completo pendiente, se sube a Firestore aquí — una sola
    // vez, sin importar si el usuario venía de "Crear cuenta" o de un
    // login normal con un borrador local viejo de una sesión anterior.
    final userId = next.valueOrNull?.uid;
    if (previous?.valueOrNull == null && userId != null) {
      ref.read(onboardingRepositoryProvider).migrateDraftToProfile(userId);
    }
  });
  ref.listen(guestModeProvider, (previous, next) => refreshNotifier.notify());

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final location = state.matchedLocation;

      if (authState.isLoading && !authState.hasValue) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }

      final isLoggedIn = authState.valueOrNull != null;

      // Splash es una parada transitoria, no un destino — una vez resuelto
      // el estado de sesión, siempre se sale de ahí hacia Home o Welcome.
      // (Antes esto faltaba y, al no estar logueado, `/splash` calificaba
      // como "ruta pública" y el router se quedaba ahí para siempre.)
      if (location == RoutePaths.splash) {
        return isLoggedIn ? RoutePaths.root : RoutePaths.welcome;
      }

      final isPublicRoute = RoutePaths.publicRoutes.contains(location);
      // Temporal: las tabs del shell principal (`root`/`plan`/`ai`/`profile`)
      // y `onboarding` no tienen persistencia de cuenta real todavía (Épica
      // 3/6, ver documentation/authentication.md "Known gaps").
      // `guestModeProvider`
      // es lo que distingue "invitado navegando tras Empezar/Seguir sin
      // cuenta" de "usuario recién deslogueado" — ambos tienen
      // `authStateChangesProvider` en null, pero solo el primero debe poder
      // quedarse en estas rutas (si no se distinguiera, "Cerrar sesión" no
      // devolvía a Welcome: bug real encontrado probando).
      final isGuestAccessible = RoutePaths.guestAccessibleRoutes.contains(location) && ref.read(guestModeProvider);
      if (!isLoggedIn && !isPublicRoute && !isGuestAccessible) return RoutePaths.welcome;
      if (isLoggedIn && isPublicRoute) return RoutePaths.root;
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: RoutePaths.welcome, builder: (context, state) => const WelcomePage()),
      GoRoute(path: RoutePaths.onboarding, builder: (context, state) => const OnboardingPage()),
      GoRoute(
        path: RoutePaths.foodAnalysis,
        builder: (context, state) => FoodAnalysisPage(imageBytes: state.extra! as Uint8List),
      ),
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginPage()),
      GoRoute(
        path: RoutePaths.signUp,
        builder: (context, state) {
          return SignUpPage(hasPendingPlan: ref.read(onboardingControllerProvider).isComplete);
        },
      ),
      GoRoute(path: RoutePaths.forgotPassword, builder: (context, state) => const ForgotPasswordPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: RoutePaths.root, builder: (context, state) => const HomePage())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.plan,
                builder: (context, state) => const PlanPage(),
                routes: [
                  GoRoute(
                    path: RoutePaths.recipeDetailSegment,
                    builder: (context, state) => RecipeDetailPage(
                      date: state.pathParameters['date']!,
                      mealId: state.pathParameters['mealId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: RoutePaths.cookingModeSegment,
                        builder: (context, state) => CookingModePage(
                          recipe: state.extra! as Recipe,
                          date: state.pathParameters['date']!,
                          mealId: state.pathParameters['mealId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: RoutePaths.groceryListSegment,
                    builder: (context, state) => const GroceryListPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(routes: [GoRoute(path: RoutePaths.ai, builder: (context, state) => const AiChatPage())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) {
                  return ProfilePage(onSignOut: () => ref.read(authControllerProvider.notifier).signOut());
                },
                routes: [
                  GoRoute(
                    path: RoutePaths.profileEditGoalSegment,
                    builder: (context, state) => const EditGoalBiometricsPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.profileEditPreferencesSegment,
                    builder: (context, state) => const EditPreferencesPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.profilePrivacySegment,
                    builder: (context, state) => const PrivacyDataPage(),
                  ),
                  GoRoute(
                    path: RoutePaths.profileNotificationsSegment,
                    builder: (context, state) => const NotificationSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

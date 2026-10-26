import 'dart:typed_data';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/app_version/app_update_status.dart';
import '../widgets/update_required_page.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/sign_up_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/welcome_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/ai_assistant/presentation/pages/ai_chat_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_generating_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_plan_ready_page.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../../features/plan/domain/entities/nutrition_plan.dart';
import '../../features/food_analysis/presentation/pages/food_analysis_page.dart';
import '../../features/grocery_list/presentation/pages/grocery_list_page.dart';
import '../../features/ingredients/domain/entities/ingredient_suggestions.dart';
import '../../features/ingredients/presentation/pages/ingredient_detection_page.dart';
import '../../features/ingredients/presentation/pages/ingredient_recipes_page.dart';
import '../../features/ingredients/presentation/pages/suggested_recipe_page.dart';
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
import '../services/analytics/firebase_analytics_service.dart';
import '../services/firebase_instances.dart';
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
    // La sesión anónima de B8 (ver `AuthController.ensureAnonymousSession`)
    // también dispara este listener (null -> uid) pero no debe disparar
    // esta migración: su perfil ya se escribe aparte, de forma no
    // destructiva, desde el propio controlador de generación de plan (B8) —
    // `migrateDraftToProfile` BORRA el borrador local, y B8 todavía lo
    // necesita vivo para que SignUp (A4) siga mostrando "tu plan ya está
    // calculado". Solo una transición a una cuenta REAL (registro/login,
    // `isAnonymous == false`) debe migrar y limpiar.
    final wasRealUser = previous?.valueOrNull != null && previous!.valueOrNull!.isAnonymous == false;
    final user = next.valueOrNull;
    final userId = user?.uid;
    if (!wasRealUser && userId != null && user?.isAnonymous == false) {
      ref.read(onboardingRepositoryProvider).migrateDraftToProfile(userId).then((migrated) {
        if (migrated) ref.read(analyticsServiceProvider).logOnboardingCompleted();
      });
    }
  });
  ref.listen(guestModeProvider, (previous, next) => refreshNotifier.notify());
  ref.listen(appUpdateStatusProvider, (previous, next) => refreshNotifier.notify());

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshNotifier,
    // Épica 14 — cierra el gap documentado de screen-view tracking: ya
    // existe un `name:` explícito por ruta (antes ninguna lo tenía, por
    // eso se había dejado sin construir), así que `FirebaseAnalyticsObserver`
    // reporta un `screen_name` real y estable en vez de uno vacío/nulo.
    observers: [FirebaseAnalyticsObserver(analytics: ref.read(firebaseAnalyticsProvider))],
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final location = state.matchedLocation;

      // Versión mínima obligatoria (Épica 17) — antes que cualquier otra
      // regla: con la versión vieja no se navega a ningún lado. Mientras la
      // consulta no resuelve (o si falla) no bloquea: falla abierto, ver
      // `appUpdateStatusProvider`.
      final updateRequired = ref.read(appUpdateStatusProvider).valueOrNull?.isUpdateRequired ?? false;
      if (updateRequired) return location == RoutePaths.updateRequired ? null : RoutePaths.updateRequired;
      if (location == RoutePaths.updateRequired) return RoutePaths.splash;

      if (authState.isLoading && !authState.hasValue) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }

      final isLoggedIn = authState.valueOrNull != null;
      // La sesión anónima de B8 (ver `AuthController.ensureAnonymousSession`)
      // cuenta como "con sesión" para no rebotarla de root/plan/ai/profile,
      // pero NO como una cuenta real: debe poder seguir llegando a SignUp
      // (A4, desde B9 · "Empezar mi día") sin que la regla de abajo
      // ("logueado en ruta pública -> Home") se lo impida.
      final isAnonymous = authState.valueOrNull?.isAnonymous ?? false;

      // Splash es una parada transitoria, no un destino — una vez resuelto
      // el estado de sesión, siempre se sale de ahí hacia Home o Welcome.
      // (Antes esto faltaba y, al no estar logueado, `/splash` calificaba
      // como "ruta pública" y el router se quedaba ahí para siempre.)
      // AUTH-106: si no hay sesión pero sí un borrador local de Onboarding
      // (invitado que ya había "Empezado" o terminado y eligió "Seguir sin
      // cuenta"), `guestResumeRouteProvider` manda directo a `/onboarding`
      // o a Home en vez de Welcome — reabrir la app ya no resetea el modo
      // invitado.
      if (location == RoutePaths.splash) {
        if (isLoggedIn) return RoutePaths.root;
        return ref.read(guestResumeRouteProvider) ?? RoutePaths.welcome;
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
      if (isLoggedIn && !isAnonymous && isPublicRoute) return RoutePaths.root;
      return null;
    },
    routes: [
      GoRoute(name: 'splash', path: RoutePaths.splash, builder: (context, state) => const SplashPage()),
      GoRoute(
        name: 'update_required',
        path: RoutePaths.updateRequired,
        builder: (context, state) => const UpdateRequiredPage(),
      ),
      GoRoute(name: 'welcome', path: RoutePaths.welcome, builder: (context, state) => const WelcomePage()),
      GoRoute(name: 'onboarding', path: RoutePaths.onboarding, builder: (context, state) => const OnboardingPage()),
      GoRoute(
        name: 'onboarding_generating',
        path: RoutePaths.onboardingGenerating,
        builder: (context, state) => const OnboardingGeneratingPage(),
      ),
      GoRoute(
        name: 'onboarding_plan_ready',
        path: RoutePaths.onboardingPlanReady,
        builder: (context, state) => OnboardingPlanReadyPage(plan: state.extra! as NutritionPlan),
      ),
      GoRoute(
        name: 'food_analysis',
        path: RoutePaths.foodAnalysis,
        builder: (context, state) => FoodAnalysisPage(imageBytes: state.extra! as Uint8List),
      ),
      GoRoute(
        name: 'ingredient_analysis',
        path: RoutePaths.ingredientAnalysis,
        builder: (context, state) => IngredientDetectionPage(imageBytes: state.extra! as Uint8List),
      ),
      GoRoute(
        name: 'ingredient_recipes',
        path: RoutePaths.ingredientRecipes,
        builder: (context, state) => const IngredientRecipesPage(),
      ),
      GoRoute(
        name: 'ingredient_recipe',
        path: RoutePaths.ingredientRecipe,
        builder: (context, state) => SuggestedRecipePage(suggestion: state.extra! as SuggestedRecipe),
      ),
      GoRoute(
        name: 'ingredient_recipe_cooking',
        path: RoutePaths.ingredientRecipeCooking,
        builder: (context, state) => CookingModePage(recipe: state.extra! as Recipe),
      ),
      GoRoute(name: 'login', path: RoutePaths.login, builder: (context, state) => const LoginPage()),
      GoRoute(
        name: 'sign_up',
        path: RoutePaths.signUp,
        builder: (context, state) {
          return SignUpPage(hasPendingPlan: ref.read(onboardingControllerProvider).isComplete);
        },
      ),
      GoRoute(
        name: 'forgot_password',
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(name: 'home', path: RoutePaths.root, builder: (context, state) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'plan',
                path: RoutePaths.plan,
                builder: (context, state) => const PlanPage(),
                routes: [
                  GoRoute(
                    name: 'recipe_detail',
                    path: RoutePaths.recipeDetailSegment,
                    builder: (context, state) => RecipeDetailPage(
                      date: state.pathParameters['date']!,
                      mealId: state.pathParameters['mealId']!,
                    ),
                    routes: [
                      GoRoute(
                        name: 'cooking_mode',
                        path: RoutePaths.cookingModeSegment,
                        builder: (context, state) => CookingModePage(
                          recipe: state.extra! as Recipe,
                          mealId: state.pathParameters['mealId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    name: 'grocery_list',
                    path: RoutePaths.groceryListSegment,
                    builder: (context, state) => const GroceryListPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(name: 'ai_chat', path: RoutePaths.ai, builder: (context, state) => const AiChatPage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'profile',
                path: RoutePaths.profile,
                builder: (context, state) {
                  return ProfilePage(onSignOut: () => ref.read(authControllerProvider.notifier).signOut());
                },
                routes: [
                  GoRoute(
                    name: 'profile_edit_goal',
                    path: RoutePaths.profileEditGoalSegment,
                    builder: (context, state) => const EditGoalBiometricsPage(),
                  ),
                  GoRoute(
                    name: 'profile_edit_preferences',
                    path: RoutePaths.profileEditPreferencesSegment,
                    builder: (context, state) => const EditPreferencesPage(),
                  ),
                  GoRoute(
                    name: 'profile_privacy',
                    path: RoutePaths.profilePrivacySegment,
                    builder: (context, state) => const PrivacyDataPage(),
                  ),
                  GoRoute(
                    name: 'profile_notifications',
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

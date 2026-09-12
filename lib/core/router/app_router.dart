import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/sign_up_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/welcome_page.dart';
import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../constants/route_paths.dart';
import '../widgets/home_placeholder_page.dart';
import 'go_router_refresh_stream.dart';

/// El único [GoRouter] de la app. No crear otros routers ni navegar con
/// `Navigator` crudo — extender este en su lugar.
///
/// La guarda de sesión vive en `redirect`: mientras
/// `authStateChangesProvider` no ha resuelto (arranque en frío) se queda en
/// Splash; resuelto, manda a Welcome (sin sesión) o Home (con sesión). El
/// onboarding (Épica 3) aún no existe, así que "Empezar" en Welcome y
/// "Seguir sin cuenta" en SignUp navegan directo a Home por ahora.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: GoRouterRefreshStream(ref.watch(authRepositoryProvider).authStateChanges()),
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final location = state.matchedLocation;

      if (authState.isLoading && !authState.hasValue) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }

      final isLoggedIn = authState.valueOrNull != null;
      final isPublicRoute = RoutePaths.publicRoutes.contains(location);

      if (!isLoggedIn && !isPublicRoute) return RoutePaths.welcome;
      if (isLoggedIn && isPublicRoute) return RoutePaths.root;
      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: RoutePaths.welcome, builder: (context, state) => const WelcomePage()),
      GoRoute(path: RoutePaths.login, builder: (context, state) => const LoginPage()),
      GoRoute(path: RoutePaths.signUp, builder: (context, state) => const SignUpPage()),
      GoRoute(path: RoutePaths.forgotPassword, builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(
        path: RoutePaths.root,
        builder: (BuildContext context, GoRouterState state) {
          return HomePlaceholderPage(
            onSignOut: () => ref.read(authControllerProvider.notifier).signOut(),
          );
        },
      ),
    ],
  );
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/analytics/firebase_analytics_service.dart';
import '../../../../core/services/firebase_instances.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = FirebaseAuthDataSource(ref.watch(firebaseAuthProvider), ref.watch(googleSignInProvider));
  return AuthRepositoryImpl(dataSource);
});

/// Fuente de verdad reactiva del estado de sesión — la consume el router
/// para las reglas de redirección y cualquier pantalla que necesite saber
/// si hay un usuario autenticado.
final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Modo invitado: true mientras el usuario navega "sin cuenta" (Welcome ·
/// "Empezar" o SignUp · "Seguir sin cuenta") — distingue "invitado
/// navegando" de "usuario sin sesión" (p. ej. justo después de cerrar
/// sesión), casos que de otra forma se ven idénticos porque ambos tienen
/// `authStateChangesProvider` en null. Su valor inicial real (en frío, al
/// abrir la app) no es `false` a secas: `main.dart` lo sobreescribe antes de
/// `runApp` según si ya existe un borrador local de Onboarding (AUTH-106) —
/// ver [guestResumeRouteProvider].
final guestModeProvider = StateProvider<bool>((ref) => false);

/// Ruta a la que un invitado debe volver al reabrir la app en frío (sin
/// sesión), calculada UNA sola vez en `main()` a partir del borrador local
/// de Onboarding (`OnboardingLocalDataSource`) antes de construir el árbol
/// de widgets — nunca en caliente, para no competir con la carga asíncrona
/// de ese mismo borrador dentro de `onboardingControllerProvider`. `null`
/// significa "no hay borrador local" (dispositivo nuevo o ya migrado a una
/// cuenta real vía `migrateDraftToProfile`, que borra el borrador). Lo
/// consume solo el `redirect` de `splash` en `app_router.dart` — resuelve
/// AUTH-106 (antes, un invitado que cerraba la app perdía su sesión de
/// invitado y volvía a Welcome aunque sus respuestas sí sobrevivían).
final guestResumeRouteProvider = Provider<String?>((ref) => null);

/// Orquesta las acciones de login/registro/reset — el estado
/// `AsyncValue<void>` le da a cada pantalla loading/error "gratis" vía
/// `AsyncValue.guard`, sin manejar excepciones a mano en cada botón.
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signInWithEmailAndPassword(email: email, password: password),
    );
    if (!state.hasError) ref.read(analyticsServiceProvider).logLogin();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
    if (!state.hasError) ref.read(analyticsServiceProvider).logSignUp();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.sendPasswordResetEmail(email: email));
  }

  /// A diferencia de `signIn`/`signUp`, no hay forma de saber de antemano si
  /// esto termina en un login (cuenta de Google ya vinculada a un usuario
  /// existente) o un registro (primera vez) — Firebase lo decide
  /// internamente. Se reporta como login por default; ver el comentario en
  /// el botón de la UI para el porqué de esa elección.
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    bool signedIn = false;
    state = await AsyncValue.guard(() async {
      signedIn = await _repository.signInWithGoogle();
    });
    if (!state.hasError && signedIn) ref.read(analyticsServiceProvider).logLogin(method: 'google');
  }

  /// Llamado por B8 (Onboarding) antes de generar el plan — ver
  /// `documentation/onboarding.md`. No usa `AsyncValue.guard`/`state`
  /// porque B8 ya tiene su propio controlador de progreso (no queremos que
  /// un error aquí se confunda con un error de generación de plan); si
  /// falla, deja que quien lo llamó lo propague.
  Future<void> ensureAnonymousSession() => _repository.signInAnonymously();

  Future<void> signOut() async {
    await _repository.signOut();
    ref.read(guestModeProvider.notifier).state = false;
    ref.read(analyticsServiceProvider).logSignOut();
  }
}

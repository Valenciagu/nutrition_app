import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_instances.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = FirebaseAuthDataSource(ref.watch(firebaseAuthProvider));
  return AuthRepositoryImpl(dataSource);
});

/// Fuente de verdad reactiva del estado de sesión — la consume el router
/// para las reglas de redirección y cualquier pantalla que necesite saber
/// si hay un usuario autenticado.
final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

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
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.sendPasswordResetEmail(email: email));
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }
}

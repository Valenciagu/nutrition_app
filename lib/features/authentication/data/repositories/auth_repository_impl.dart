import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final FirebaseAuthDataSource _dataSource;

  AuthUser? _mapUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() => _dataSource.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_dataSource.currentUser);

  @override
  Future<void> signInWithEmailAndPassword({required String email, required String password}) {
    return _run(() => _dataSource.signInWithEmailAndPassword(email: email, password: password));
  }

  @override
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _run(
      () => _dataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _run(() => _dataSource.sendPasswordResetEmail(email: email));
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      return await _dataSource.signInWithGoogle();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.code, cause: e.cause);
    }
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  /// Traduce [AuthException] (capa de datos) a [AuthFailure] (dominio /
  /// presentación) preservando el `code` de Firebase para que la UI decida
  /// el mensaje localizado — el repositorio no conoce copy ni idioma.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, code: e.code, cause: e.cause);
    }
  }
}

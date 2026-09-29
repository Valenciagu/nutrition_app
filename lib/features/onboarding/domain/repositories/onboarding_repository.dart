import '../entities/onboarding_answers.dart';

/// Contrato del feature Onboarding. `saveDraft`/`loadDraft`/`clearDraft`
/// operan siempre en local (sin `userId`, ver `OnboardingAnswers`);
/// `migrateDraftToProfile` es el único método que toca Firestore, llamado
/// una vez que existe un usuario autenticado (ver `app_router.dart`).
abstract class OnboardingRepository {
  Future<void> saveDraft(OnboardingAnswers answers);
  Future<OnboardingAnswers> loadDraft();
  Future<void> clearDraft();

  /// Si hay un borrador local completo, lo escribe en
  /// `users/{userId}` de Firestore y borra el borrador local. No hace nada
  /// si no hay borrador (usuario que se registra sin haber hecho onboarding).
  /// Devuelve `true` solo si de verdad migró un borrador — lo usa
  /// `app_router.dart` para no reportar `onboardingCompleted` en un login
  /// normal sin borrador pendiente.
  Future<bool> migrateDraftToProfile(String userId);

  /// Escribe cambios sobre un perfil YA existente (Perfil, Épica 11) — sin
  /// tocar el borrador local ni su ciclo de vida de migración; el usuario ya
  /// tiene sesión y ya tiene un documento. Mismo destino remoto que
  /// `migrateDraftToProfile`, sin la parte de borrador.
  Future<void> updateProfile(String userId, OnboardingAnswers answers);
}

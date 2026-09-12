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
  Future<void> migrateDraftToProfile(String userId);
}

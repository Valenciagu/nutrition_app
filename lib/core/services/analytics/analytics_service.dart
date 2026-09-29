/// Abstracción de Analytics (Instrucciones.md §48: eventos centralizados,
/// nunca nombres hardcodeados en cada feature). Un método tipado por evento
/// en vez de un `logEvent(String name, Map params)` genérico — así el
/// nombre y la forma de cada evento viven en un solo sitio
/// (`FirebaseAnalyticsService`), y un error de tipeo en un nombre de evento
/// es un error de compilación, no un typo silencioso en producción.
///
/// Deliberadamente sin PII ni contenido generado por el usuario/la IA en
/// ningún parámetro — Instrucciones.md: "Never expose secrets through
/// analytics" / "Do not log sensitive information" (§20, §48).
abstract class AnalyticsService {
  Future<void> logSignUp();
  Future<void> logLogin();
  Future<void> logSignOut();
  Future<void> logAccountDeleted();

  Future<void> logOnboardingCompleted();

  Future<void> logPlanGenerated();
  Future<void> logPlanAdjusted();
  Future<void> logMealRegistered();
  Future<void> logMealReplaced();

  Future<void> logFoodPhotoAnalyzed({required bool isFoodPhoto});

  Future<void> logRemindersEnabled({required int activeTypeCount});
}

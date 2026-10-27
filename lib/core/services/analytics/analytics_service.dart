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
  /// [method] es un identificador fijo ("email"/"google"), nunca texto
  /// libre — permite separar el embudo de registro/login por método sin
  /// violar la regla de "nada de PII/texto libre en parámetros" (§20/§48).
  Future<void> logSignUp({String method = 'email'});
  Future<void> logLogin({String method = 'email'});
  Future<void> logSignOut();
  Future<void> logAccountDeleted();

  Future<void> logOnboardingCompleted();

  Future<void> logPlanGenerated();
  Future<void> logPlanAdjusted();
  Future<void> logMealRegistered();
  Future<void> logMealReplaced();

  /// Comida fuera del plan (Épica 19); `source`: `manual` | `photo`.
  Future<void> logExtraMealLogged({required String source});

  Future<void> logFoodPhotoAnalyzed({required bool isFoodPhoto});
  Future<void> logIngredientPhotoAnalyzed({required bool isIngredientPhoto, required int ingredientCount});

  Future<void> logRemindersEnabled({required int activeTypeCount});
}

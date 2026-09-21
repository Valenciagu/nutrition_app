import 'nutrition_assistant_answer.dart';

/// Abstracción del asistente de IA del backend (Instrucciones.md §77: "Create
/// an abstraction that allows model changes later... Model selection should
/// happen in a configurable layer"). Ninguna feature debe llamar a
/// `cloud_functions`/OpenAI directamente — siempre a través de esta interfaz,
/// para poder cambiar de implementación (o de modelo, en el backend) sin
/// tocar el código que la consume.
///
/// Un solo método — solo cabe aquí lo que es genérico de verdad (una
/// pregunta de texto libre, sin tipo de retorno propio de ninguna feature).
/// Una Cloud Function de IA cuyo resultado SÍ es específico de una feature
/// (p. ej. `generateDailyPlan`, que devuelve un `NutritionPlan` — Épica 6)
/// NO se agrega aquí: `core/` no puede importar tipos de `features/*`
/// (violaría la separación de capas). Esas funciones tienen su propio
/// repositorio dentro de la feature (ver `features/plan/data/repositories/`),
/// llamando a `cloud_functions` directamente vía `firebaseFunctionsProvider`
/// — mismo patrón, sin forzar esta interfaz a conocer tipos que no le
/// corresponden.
abstract class AIService {
  /// Responde una pregunta de nutrición en texto libre. Lanza un `Failure`
  /// de `core/errors` si la llamada falla (ver `FirebaseAiService`) —
  /// incluyendo `AiQuotaExceededFailure` si el usuario ya agotó su cupo
  /// diario.
  Future<NutritionAssistantAnswer> askNutritionQuestion(String question);
}

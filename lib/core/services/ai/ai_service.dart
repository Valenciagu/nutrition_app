import 'nutrition_assistant_answer.dart';

/// Abstracción del asistente de IA del backend (Instrucciones.md §77: "Create
/// an abstraction that allows model changes later... Model selection should
/// happen in a configurable layer"). Ninguna feature debe llamar a
/// `cloud_functions`/OpenAI directamente — siempre a través de esta interfaz,
/// para poder cambiar de implementación (o de modelo, en el backend) sin
/// tocar el código que la consume.
///
/// Un solo método hoy porque es la única función de IA desplegada
/// (`askNutritionAssistant`, Épica 5). Cada Cloud Function de IA nueva que
/// aterrice en Épicas 6-9 agrega su propio método aquí, no una interfaz
/// separada.
abstract class AIService {
  /// Responde una pregunta de nutrición en texto libre. Lanza un `Failure`
  /// de `core/errors` si la llamada falla (ver `FirebaseAiService`) —
  /// incluyendo `AiQuotaExceededFailure` si el usuario ya agotó su cupo
  /// diario.
  Future<NutritionAssistantAnswer> askNutritionQuestion(String question);
}

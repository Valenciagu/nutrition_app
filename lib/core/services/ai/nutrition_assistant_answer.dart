/// Respuesta de `askNutritionAssistant` (Cloud Function), ya validada por el
/// backend — ver `functions/src/ai/schema.ts` y `functions/src/ai/safety.ts`.
/// Esta clase es dominio puro, sin nada de `cloud_functions`; `AIService` es
/// la única frontera que conoce la forma cruda que devuelve la función.
class NutritionAssistantAnswer {
  const NutritionAssistantAnswer({
    required this.answer,
    required this.recommendsProfessionalConsult,
    required this.safetyFallbackApplied,
    required this.remainingToday,
  });

  final String answer;

  /// true si la pregunta sugiere que conviene consultar a un profesional de
  /// la salud — la UI debe mostrar esto de forma visible, nunca ocultarlo.
  final bool recommendsProfessionalConsult;

  /// true si la capa de seguridad determinística del backend reemplazó la
  /// respuesta real por un mensaje seguro genérico (ver
  /// `documentation/ai_backend.md`) — útil para que la UI, si quiere, marque
  /// visualmente que la respuesta fue limitada por seguridad.
  final bool safetyFallbackApplied;

  /// Cupo de consultas de este feature que le quedan al usuario hoy
  /// (Instrucciones.md §28: el cliente puede mostrar el cupo restante, pero
  /// nunca lo controla).
  final int remainingToday;
}

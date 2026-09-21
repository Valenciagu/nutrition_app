/// Un paso del modo cocina (D5 — `documentation/design_screens_plan.md`,
/// aprobado por el usuario 2026-09-20). El orden es el índice dentro de
/// `Recipe.steps`, no un campo propio: los pasos los genera la IA una sola
/// vez y el cliente nunca reordena ni edita pasos sueltos.
class RecipeStep {
  const RecipeStep({
    required this.instruction,
    this.timerSeconds,
  });

  final String instruction;

  /// Duración del temporizador de este paso (p. ej. 240 para "04:00"), o
  /// `null` si el paso no implica esperar nada (p. ej. "corta la cebolla").
  final int? timerSeconds;

  RecipeStep copyWith({
    String? instruction,
    int? timerSeconds,
  }) {
    return RecipeStep(
      instruction: instruction ?? this.instruction,
      timerSeconds: timerSeconds ?? this.timerSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        'timerSeconds': timerSeconds,
      };

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      instruction: json['instruction'] as String,
      timerSeconds: json['timerSeconds'] as int?,
    );
  }
}

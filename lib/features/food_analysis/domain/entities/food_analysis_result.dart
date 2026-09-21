/// Qué tan segura está la IA de su propia estimación — Instrucciones.md §6:
/// "cuando la incertidumbre sea alta, el sistema debe comunicarla
/// apropiadamente". Autorreportado por el modelo, no calculado.
enum FoodAnalysisConfidence { low, medium, high }

/// Resultado de analizar una foto de comida (Épica 8). Todos los campos de
/// comida son `null` cuando [isFoodPhoto] es `false` — la foto no mostraba
/// nada reconocible como comida, y el backend deliberadamente no inventa una
/// estimación en ese caso (ver `functions/src/foodAnalysis/schema.ts`).
///
/// [allergenWarning] es una ADVERTENCIA, no un rechazo: a diferencia de
/// `NutritionPlan`/`Recipe` (contenido que la IA genera y puede volver a
/// generar si es inseguro), esta comida ya existe frente al usuario — negar
/// la estimación sería inútil. La UI debe mostrar el resultado igual, con la
/// advertencia visible.
class FoodAnalysisResult {
  const FoodAnalysisResult({
    required this.id,
    required this.isFoodPhoto,
    required this.allergenWarning,
    required this.analyzedAt,
    this.foodName,
    this.portionDescription,
    this.calories,
    this.proteinGrams,
    this.carbsGrams,
    this.fatGrams,
    this.confidence,
    this.uncertaintyNote,
  });

  final String id;
  final bool isFoodPhoto;
  final bool allergenWarning;
  final DateTime analyzedAt;

  final String? foodName;
  final String? portionDescription;
  final int? calories;
  final int? proteinGrams;
  final int? carbsGrams;
  final int? fatGrams;
  final FoodAnalysisConfidence? confidence;
  final String? uncertaintyNote;

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResult(
      id: json['id'] as String,
      isFoodPhoto: json['isFoodPhoto'] as bool,
      allergenWarning: json['allergenWarning'] as bool,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      foodName: json['foodName'] as String?,
      portionDescription: json['portionDescription'] as String?,
      calories: json['calories'] as int?,
      proteinGrams: json['proteinGrams'] as int?,
      carbsGrams: json['carbsGrams'] as int?,
      fatGrams: json['fatGrams'] as int?,
      confidence: json['confidence'] == null
          ? null
          : FoodAnalysisConfidence.values.byName(json['confidence'] as String),
      uncertaintyNote: json['uncertaintyNote'] as String?,
    );
  }
}

import '../../../recipes/domain/entities/recipe.dart';

/// Una receta propuesta a partir de una foto de ingredientes (Épica 9). La
/// receta en sí es una [Recipe] normal (Épica 7) — así D3/D5 la muestran
/// sin cambios —, más lo que habría que conseguir aparte de lo que se vio.
class SuggestedRecipe {
  const SuggestedRecipe({required this.recipe, required this.missingIngredients});

  final Recipe recipe;

  /// Vacío si alcanza con lo de la foto + básicos (sal, aceite, agua).
  final List<String> missingIngredients;

  factory SuggestedRecipe.fromJson(Map<String, dynamic> json) {
    return SuggestedRecipe(
      recipe: Recipe.fromJson(json),
      missingIngredients: (json['missingIngredients'] as List? ?? const []).cast<String>(),
    );
  }
}

/// Respuesta de `suggestRecipesFromIngredients`. No se guarda en ningún lado:
/// vive en memoria mientras el usuario mira el resultado (ver
/// `documentation/ingredients.md`).
class IngredientSuggestions {
  const IngredientSuggestions({
    required this.isIngredientPhoto,
    required this.detectedIngredients,
    required this.recipes,
    required this.remainingToday,
  });

  /// `false` si la foto no mostraba ingredientes — no es un error, es un
  /// resultado (mismo criterio que `FoodAnalysisResult.isFoodPhoto`).
  final bool isIngredientPhoto;
  final List<String> detectedIngredients;
  final List<SuggestedRecipe> recipes;
  final int remainingToday;

  factory IngredientSuggestions.fromJson(Map<String, dynamic> json) {
    return IngredientSuggestions(
      isIngredientPhoto: json['isIngredientPhoto'] as bool,
      detectedIngredients: (json['detectedIngredients'] as List? ?? const []).cast<String>(),
      recipes: (json['recipes'] as List? ?? const [])
          .map((raw) => SuggestedRecipe.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(),
      remainingToday: json['remainingToday'] as int,
    );
  }
}

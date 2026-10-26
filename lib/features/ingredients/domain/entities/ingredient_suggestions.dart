import '../../../recipes/domain/entities/recipe.dart';

/// Un ingrediente de la lista de F1 (Fase 6). [confident] `false` = el
/// modelo dudó (o aún no se confirmó): se muestra con borde punteado y no
/// entra a las recetas hasta que el usuario lo confirme.
class DetectedIngredient {
  const DetectedIngredient({required this.name, required this.confident});

  final String name;
  final bool confident;

  DetectedIngredient confirmed() => DetectedIngredient(name: name, confident: true);

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    return DetectedIngredient(name: json['name'] as String, confident: json['confident'] as bool);
  }
}

/// Respuesta de `detectIngredients` (F1).
class IngredientDetection {
  const IngredientDetection({
    required this.isIngredientPhoto,
    required this.ingredients,
    required this.remainingToday,
  });

  /// `false` si la foto no mostraba ingredientes — no es un error, es un
  /// resultado (mismo criterio que `FoodAnalysisResult.isFoodPhoto`).
  final bool isIngredientPhoto;
  final List<DetectedIngredient> ingredients;
  final int remainingToday;

  factory IngredientDetection.fromJson(Map<String, dynamic> json) {
    return IngredientDetection(
      isIngredientPhoto: json['isIngredientPhoto'] as bool,
      ingredients: (json['ingredients'] as List? ?? const [])
          .map((raw) => DetectedIngredient.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(),
      remainingToday: json['remainingToday'] as int,
    );
  }
}

/// Una receta propuesta en F2 a partir de la lista revisada. La receta es
/// una [Recipe] normal (Épica 7) — así D3/D5 la muestran sin cambios —, más
/// lo que habría que conseguir aparte.
class SuggestedRecipe {
  const SuggestedRecipe({required this.recipe, required this.missingIngredients});

  final Recipe recipe;

  /// Vacío = badge "Tienes todo" (los básicos — sal, aceite, agua — no cuentan).
  final List<String> missingIngredients;

  factory SuggestedRecipe.fromJson(Map<String, dynamic> json) {
    return SuggestedRecipe(
      recipe: Recipe.fromJson(json),
      missingIngredients: (json['missingIngredients'] as List? ?? const []).cast<String>(),
    );
  }
}

/// Respuesta de `suggestRecipesFromIngredients` (F2). No se guarda en ningún
/// lado: vive en memoria mientras el usuario mira el resultado.
class IngredientRecipeSuggestions {
  const IngredientRecipeSuggestions({required this.recipes, required this.remainingToday});

  final List<SuggestedRecipe> recipes;
  final int remainingToday;

  factory IngredientRecipeSuggestions.fromJson(Map<String, dynamic> json) {
    return IngredientRecipeSuggestions(
      recipes: (json['recipes'] as List? ?? const [])
          .map((raw) => SuggestedRecipe.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(),
      remainingToday: json['remainingToday'] as int,
    );
  }
}

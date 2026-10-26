import 'dart:typed_data';

import '../entities/ingredient_suggestions.dart';

/// Contrato de la Épica 9 — un método por Cloud Function real
/// (`functions/src/ingredients/`). Ver `documentation/ingredients.md`.
abstract class IngredientAnalysisRepository {
  /// F1: sube la foto y devuelve lo que se ve. La foto se borra en el
  /// servidor al terminar.
  Future<IngredientDetection> detectIngredients({required String userId, required Uint8List imageBytes});

  /// F2: recetas sobre la lista ya revisada, sin foto. [excludeRecipeNames]
  /// pide ideas distintas a las ya mostradas ("Pedir más ideas a la IA").
  Future<IngredientRecipeSuggestions> suggestRecipes({
    required List<String> ingredients,
    List<String> excludeRecipeNames = const [],
  });
}

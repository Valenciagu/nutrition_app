import 'dart:typed_data';

import '../entities/ingredient_suggestions.dart';

/// Contrato de la Épica 9 — un método por Cloud Function real
/// (`functions/src/ingredients/`). Ver `documentation/ingredients.md`.
abstract class IngredientAnalysisRepository {
  /// Sube la foto y pide ingredientes + recetas. La foto se borra en el
  /// servidor al terminar.
  Future<IngredientSuggestions> suggestRecipes({required String userId, required Uint8List imageBytes});
}

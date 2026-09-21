import '../entities/recipe.dart';

/// Contrato de recetas — un método, porque hoy solo existe una Cloud
/// Function (`generateRecipe`). Ver `documentation/recipes.md`.
abstract class RecipeRepository {
  /// Genera (o reutiliza, si `PlannedMeal.recipeId` ya existe) la receta
  /// completa de una comida del plan. Idempotente por comida del lado del
  /// backend — llamar dos veces con la misma `date`/`mealId` no vuelve a
  /// gastar cuota de IA.
  Future<Recipe> getOrGenerateRecipe({
    required String userId,
    required String date,
    required String mealId,
  });
}

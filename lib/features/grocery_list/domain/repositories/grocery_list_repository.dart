import '../../../recipes/domain/entities/recipe.dart';

abstract class GroceryListRepository {
  /// Recetas ya generadas para los `recipeId` dados. Puede devolver MENOS
  /// documentos que ids (un id sin documento no es un error, solo se omite)
  /// — pasa cuando `PlannedMeal.recipeId` quedó apuntando a algo que ya no
  /// existe, mismo caso raro que documenta `generateRecipe.ts`.
  Future<List<Recipe>> getRecipesByIds({required String userId, required List<String> recipeIds});

  /// Claves normalizadas (`GroceryItem.key`) marcadas como "ya tengo/compré"
  /// para la semana `weekKey` (lunes de esa semana, YYYY-MM-DD).
  Future<Set<String>> getCheckedItemKeys({required String userId, required String weekKey});

  Future<void> setItemChecked({
    required String userId,
    required String weekKey,
    required String itemKey,
    required bool checked,
  });

  /// Ítems añadidos a mano a la lista de la semana (Épica 9: "Añadir X a la
  /// lista de compra" desde una receta sugerida), tal como se escribieron.
  Future<List<String>> getExtraItems({required String userId, required String weekKey});

  Future<void> addExtraItems({required String userId, required String weekKey, required List<String> names});

  /// Quita las entradas manuales [names] (exactas, como las devolvió
  /// [getExtraItems]) y el estado "comprado" de [itemKey].
  Future<void> removeExtraItem({
    required String userId,
    required String weekKey,
    required List<String> names,
    required String itemKey,
  });
}

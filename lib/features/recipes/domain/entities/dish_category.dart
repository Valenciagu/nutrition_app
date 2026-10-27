/// Tipo de plato (RECIPE-101) — la IA elige uno de esta lista cerrada para
/// cada comida/receta y la app muestra la foto ilustrativa de esa categoría.
/// Mismos valores que `DISH_CATEGORIES` en `functions/src/dishCategory.ts`.
enum DishCategory {
  salad('salad'),
  bowl('bowl'),
  soup('soup'),
  pasta('pasta'),
  rice('rice'),
  proteinPlate('protein_plate'),
  fish('fish'),
  eggs('eggs'),
  wrapSandwich('wrap_sandwich'),
  tacosArepa('tacos_arepa'),
  oatsYogurt('oats_yogurt'),
  smoothie('smoothie'),
  toast('toast'),
  snackFruit('snack_fruit'),
  dessert('dessert'),
  stirFry('stir_fry');

  const DishCategory(this.id);

  /// Valor guardado en Firestore y nombre del archivo de la foto.
  final String id;

  /// `null` para documentos anteriores a RECIPE-101 o un valor que esta
  /// versión de la app no conoce — se muestra el placeholder, nunca falla.
  static DishCategory? fromId(Object? id) {
    for (final category in values) {
      if (category.id == id) return category;
    }
    return null;
  }
}

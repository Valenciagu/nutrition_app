/// Categoría de un ingrediente en la lista de compra (Instrucciones.md §10:
/// "the grocery list should group items logically" — el ejemplo del propio
/// spec usa Protein/Carbohydrates/Fruits/Vegetables; se agregan `dairy` y
/// `other` como categorías reales adicionales, no cubiertas por el ejemplo
/// pero necesarias para clasificar una lista real).
enum GroceryCategory { protein, carbs, fruit, vegetable, dairy, other }

/// De dónde viene una entrada de [GroceryItem.sources] — datos crudos, sin
/// formatear: el texto final ("200 g · Almuerzo · lun") lo arma la UI, que
/// es quien tiene `AppLocalizations`/locale a mano, no este provider/entidad
/// (mismo criterio que `PlanPage._timeLabel`, que tampoco vive en `PlannedMeal`).
class GroceryItemSource {
  const GroceryItemSource({required this.quantity, required this.slotLabelKey, required this.date});

  final String quantity;
  final String slotLabelKey;
  final DateTime date;
}

/// Un ingrediente agrupado en la lista de compra. Varias recetas de la
/// semana pueden pedir el mismo ingrediente (p. ej. pollo el lunes Y el
/// miércoles) — en vez de sumar cantidades (`RecipeIngredient.quantity` es
/// texto libre, no hay una unidad común confiable para sumar, ver
/// `documentation/recipes.md`), se listan una al lado de la otra en
/// [sources] para que el usuario las combine mentalmente.
class GroceryItem {
  const GroceryItem({
    required this.key,
    required this.name,
    required this.category,
    required this.sources,
    required this.checked,
  });

  /// Nombre normalizado (trim + minúsculas) — identifica el ítem tanto para
  /// agrupar ingredientes repetidos como para persistir el estado
  /// "comprado" (`FirebaseGroceryListRepository`).
  final String key;

  final String name;
  final GroceryCategory category;
  final List<GroceryItemSource> sources;
  final bool checked;

  GroceryItem copyWith({bool? checked}) {
    return GroceryItem(
      key: key,
      name: name,
      category: category,
      sources: sources,
      checked: checked ?? this.checked,
    );
  }
}

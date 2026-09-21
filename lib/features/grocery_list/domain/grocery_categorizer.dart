import 'entities/grocery_item.dart';

/// Clasifica un ingrediente por palabras clave en español — determinístico,
/// no una llamada a IA: a diferencia de generar una receta, categorizar
/// "pollo" como proteína es un dominio acotado y no necesita un modelo
/// (mismo criterio que `estimateDailyCalories`, una fórmula, no IA). Mismo
/// patrón de substring simple que `ALLERGEN_KEYWORDS` en
/// `functions/src/foodCatalog.ts` — un falso positivo aquí es solo estético
/// (algo cae en la categoría equivocada), así que no hace falta la
/// precisión de una coincidencia de palabra completa.
GroceryCategory categorizeIngredient(String name) {
  final lower = name.toLowerCase();
  for (final entry in _categoryKeywords.entries) {
    if (entry.value.any((keyword) => lower.contains(keyword))) return entry.key;
  }
  return GroceryCategory.other;
}

const _categoryKeywords = <GroceryCategory, List<String>>{
  GroceryCategory.protein: [
    'pollo', 'pechuga', 'carne', 'res', 'cerdo', 'pescado', 'atún', 'salmón',
    'huevo', 'tofu', 'pavo', 'camarón', 'camarones', 'lomo', 'jamón', 'garbanzo',
    'lenteja', 'frijol', 'legumbre',
  ],
  GroceryCategory.carbs: [
    'arroz', 'pasta', 'papa', 'patata', 'avena', 'pan', 'quinoa', 'tortilla',
    'cuscús', 'harina', 'cereal', 'fideo',
  ],
  GroceryCategory.fruit: [
    'manzana', 'banana', 'plátano', 'naranja', 'fresa', 'uva', 'mango',
    'piña', 'limón', 'pera', 'sandía', 'melón', 'durazno', 'kiwi', 'aguacate',
  ],
  GroceryCategory.vegetable: [
    'tomate', 'lechuga', 'brócoli', 'zanahoria', 'cebolla', 'espinaca',
    'pepino', 'pimiento', 'calabacín', 'ajo', 'apio', 'coliflor', 'champiñón',
    'berenjena', 'calabaza',
  ],
  GroceryCategory.dairy: ['leche', 'queso', 'yogur', 'crema', 'mantequilla'],
};

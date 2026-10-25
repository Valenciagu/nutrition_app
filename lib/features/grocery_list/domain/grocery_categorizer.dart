import 'entities/grocery_item.dart';

/// Clasifica un ingrediente por palabras clave en español — determinístico,
/// no una llamada a IA: a diferencia de generar una receta, categorizar
/// "pollo" como proteína es un dominio acotado y no necesita un modelo
/// (mismo criterio que `estimateDailyCalories`, una fórmula, no IA).
///
/// Coincide por INICIO de palabra, no por substring: con substring, "res"
/// (carne de res) atrapaba "fresa" y "queso fresco" como proteína. El
/// prefijo sigue cubriendo plurales ("huevos", "lentejas").
GroceryCategory categorizeIngredient(String name) {
  final words = name.toLowerCase().split(_nonLetters).where((word) => word.isNotEmpty).toList();
  for (final entry in _categoryKeywords.entries) {
    if (entry.value.any((keyword) => words.any((word) => word.startsWith(keyword)))) return entry.key;
  }
  return GroceryCategory.other;
}

final _nonLetters = RegExp(r'[^a-záéíóúüñ]+');

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

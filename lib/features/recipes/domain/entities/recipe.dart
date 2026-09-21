import 'recipe_ingredient.dart';
import 'recipe_step.dart';

/// Dificultad de una receta (D3 chip "Fácil"). Las etiquetas visibles salen
/// de `AppLocalizations`, nunca de `name`/valores de este enum.
enum RecipeDifficulty { easy, medium, hard }

/// Una receta completa: Instrucciones.md §8 (nombre, descripción,
/// ingredientes+cantidades, instrucciones, tiempo, dificultad, macros,
/// raciones, sustituciones). Documento Firestore
/// `users/{userId}/recipes/{recipeId}` (Instrucciones.md §69) — propiedad
/// del usuario porque la genera la IA a partir de su perfil/restricciones,
/// igual que `NutritionPlan`; `PlannedMeal.recipeId` (Épica 6) es el puente
/// opcional desde una comida del plan hacia su receta completa.
///
/// Sin `imageUrl` todavía: ninguna Cloud Function genera fotos de receta
/// hoy, y el diseño (D3/D2) pide explícitamente un placeholder rayado en
/// vez de un ícono genérico cuando no hay foto — no un campo a rellenar.
/// Revisar si una épica futura (generación/búsqueda de imagen) lo necesita.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.servings,
    required this.prepTimeMinutes,
    required this.difficulty,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.ingredients,
    required this.steps,
  });

  final String id;
  final String name;
  final String description;

  final int servings;
  final int prepTimeMinutes;
  final RecipeDifficulty difficulty;

  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;

  final List<RecipeIngredient> ingredients;

  /// Vacío para una receta sin modo cocina construido todavía (p. ej. una
  /// migración futura) — D3 solo debe mostrar "Empezar a cocinar" cuando
  /// esta lista no esté vacía.
  final List<RecipeStep> steps;

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    int? servings,
    int? prepTimeMinutes,
    RecipeDifficulty? difficulty,
    int? calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
    List<RecipeIngredient>? ingredients,
    List<RecipeStep>? steps,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servings: servings ?? this.servings,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      difficulty: difficulty ?? this.difficulty,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'servings': servings,
        'prepTimeMinutes': prepTimeMinutes,
        'difficulty': difficulty.name,
        'calories': calories,
        'proteinGrams': proteinGrams,
        'carbsGrams': carbsGrams,
        'fatGrams': fatGrams,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      servings: json['servings'] as int,
      prepTimeMinutes: json['prepTimeMinutes'] as int,
      difficulty: RecipeDifficulty.values.byName(json['difficulty'] as String),
      calories: json['calories'] as int,
      proteinGrams: json['proteinGrams'] as int,
      carbsGrams: json['carbsGrams'] as int,
      fatGrams: json['fatGrams'] as int,
      ingredients: (json['ingredients'] as List? ?? const [])
          .map((raw) => RecipeIngredient.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(),
      steps: (json['steps'] as List? ?? const [])
          .map((raw) => RecipeStep.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(),
    );
  }
}

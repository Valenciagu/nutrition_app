import 'dish_category.dart';
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
/// Sin `imageUrl`: no se genera una foto por receta (costo y latencia, ver
/// RECIPE-101 en TASKS.md). En su lugar [dishCategory] elige una foto
/// ilustrativa de los assets; sin ella, placeholder rayado como pide el
/// diseño.
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
    this.dishCategory,
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

  /// RECIPE-101 — `null` en recetas guardadas antes de que existiera.
  final DishCategory? dishCategory;

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
    DishCategory? dishCategory,
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
      dishCategory: dishCategory ?? this.dishCategory,
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
        'dishCategory': dishCategory?.id,
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
      dishCategory: DishCategory.fromId(json['dishCategory']),
    );
  }
}

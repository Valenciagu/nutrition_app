import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/ingredients/domain/entities/ingredient_suggestions.dart';
import 'package:nutrition_app/features/recipes/domain/entities/recipe.dart';

void main() {
  Map<String, dynamic> recipeJson({List<String> missing = const []}) => {
        'id': 'r1',
        'name': 'Tortilla de papa',
        'description': 'Clásica y rápida.',
        'servings': 1,
        'prepTimeMinutes': 25,
        'difficulty': 'easy',
        'calories': 480,
        'proteinGrams': 22,
        'carbsGrams': 40,
        'fatGrams': 24,
        'ingredients': [
          {'name': 'Huevo', 'quantity': '3 unidades', 'substitutes': <String>[]},
        ],
        'steps': [
          {'instruction': 'Fríe la papa.', 'timerSeconds': 600},
        ],
        'missingIngredients': missing,
      };

  test('lee la respuesta de suggestRecipesFromIngredients como Recipe + faltantes', () {
    final result = IngredientSuggestions.fromJson({
      'isIngredientPhoto': true,
      'detectedIngredients': ['Huevo', 'Papa'],
      'recipes': [
        recipeJson(missing: ['Cebolla']),
      ],
      'remainingToday': 2,
    });

    expect(result.isIngredientPhoto, isTrue);
    expect(result.detectedIngredients, ['Huevo', 'Papa']);
    expect(result.remainingToday, 2);
    final suggestion = result.recipes.single;
    expect(suggestion.recipe.name, 'Tortilla de papa');
    expect(suggestion.recipe.difficulty, RecipeDifficulty.easy);
    expect(suggestion.recipe.steps.single.timerSeconds, 600);
    expect(suggestion.missingIngredients, ['Cebolla']);
  });

  test('una foto sin ingredientes llega con listas vacías', () {
    final result = IngredientSuggestions.fromJson({
      'isIngredientPhoto': false,
      'detectedIngredients': <String>[],
      'recipes': <Object>[],
      'remainingToday': 1,
    });
    expect(result.isIngredientPhoto, isFalse);
    expect(result.recipes, isEmpty);
  });
}

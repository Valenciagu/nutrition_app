import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/ingredients/domain/entities/ingredient_suggestions.dart';
import 'package:nutrition_app/features/ingredients/presentation/providers/ingredient_analysis_providers.dart';
import 'package:nutrition_app/features/recipes/domain/entities/recipe.dart';

void main() {
  group('respuestas de las Cloud Functions', () {
    test('detectIngredients: ingredientes con su confianza', () {
      final result = IngredientDetection.fromJson({
        'isIngredientPhoto': true,
        'ingredients': [
          {'name': 'Huevos', 'confident': true},
          {'name': 'Arroz', 'confident': false},
        ],
        'remainingToday': 2,
      });
      expect(result.isIngredientPhoto, isTrue);
      expect(result.ingredients.map((i) => i.name), ['Huevos', 'Arroz']);
      expect(result.ingredients.last.confident, isFalse);
      expect(result.remainingToday, 2);
    });

    test('suggestRecipesFromIngredients: Recipe + faltantes', () {
      final result = IngredientRecipeSuggestions.fromJson({
        'recipes': [
          {
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
            'missingIngredients': ['Cebolla'],
          },
        ],
        'remainingToday': 5,
      });
      final suggestion = result.recipes.single;
      expect(suggestion.recipe.difficulty, RecipeDifficulty.easy);
      expect(suggestion.recipe.steps.single.timerSeconds, 600);
      expect(suggestion.missingIngredients, ['Cebolla']);
      expect(result.remainingToday, 5);
    });
  });

  group('lista editable de F1', () {
    late ProviderContainer container;
    late IngredientListController list;

    setUp(() {
      container = ProviderContainer();
      list = container.read(ingredientListProvider.notifier)
        ..replaceAll(const [
          DetectedIngredient(name: 'Huevos', confident: true),
          DetectedIngredient(name: 'Arroz', confident: false),
        ]);
    });
    tearDown(() => container.dispose());

    test('solo los confirmados van a las recetas', () {
      expect(list.confirmedNames, ['Huevos']);
      list.confirm('Arroz');
      expect(list.confirmedNames, ['Huevos', 'Arroz']);
    });

    test('quitar elimina, dudoso o no', () {
      list.remove('Arroz');
      expect(container.read(ingredientListProvider).map((i) => i.name), ['Huevos']);
    });

    test('añadir a mano: confirmado, sin vacíos ni repetidos; un dudoso repetido se confirma', () {
      list
        ..add('  cebolla   morada ')
        ..add('')
        ..add('HUEVOS')
        ..add('arroz');
      expect(container.read(ingredientListProvider).map((i) => i.name), ['Huevos', 'Arroz', 'cebolla morada']);
      expect(list.confirmedNames, ['Huevos', 'Arroz', 'cebolla morada']);
    });
  });
}

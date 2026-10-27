import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/plan/domain/entities/planned_meal.dart';
import 'package:nutrition_app/features/recipes/domain/entities/dish_category.dart';
import 'package:nutrition_app/features/recipes/presentation/dish_images.dart';

void main() {
  test('fromId reads the backend ids, unknown or missing values are null', () {
    expect(DishCategory.fromId('protein_plate'), DishCategory.proteinPlate);
    expect(DishCategory.fromId('tacos_arepa'), DishCategory.tacosArepa);
    expect(DishCategory.fromId('pizza'), isNull);
    expect(DishCategory.fromId(null), isNull);
  });

  test('a planned meal round-trips its category, and old docs without it still parse', () {
    final json = {
      'id': 'm1',
      'slotLabelKey': 'lunch',
      'scheduledHour': 13,
      'scheduledMinute': 0,
      'name': 'Ensalada tibia de atún',
      'calories': 450,
      'proteinGrams': 30,
      'status': 'pending',
      'dishCategory': 'salad',
    };
    final meal = PlannedMeal.fromJson(json);
    expect(meal.dishCategory, DishCategory.salad);
    expect(meal.toJson()['dishCategory'], 'salad');
    expect(PlannedMeal.fromJson({...json}..remove('dishCategory')).dishCategory, isNull);
  });

  test('no photo yet means the hatched placeholder (null asset)', () {
    expect(dishImageAsset(null), isNull);
  });
}

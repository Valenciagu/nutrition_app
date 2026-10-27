import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/meal_log/domain/entities/extra_meal.dart';
import 'package:nutrition_app/features/meal_log/presentation/providers/extra_meal_providers.dart';
import 'package:nutrition_app/features/plan/domain/entities/nutrition_plan.dart';
import 'package:nutrition_app/features/plan/domain/entities/planned_meal.dart';

ExtraMeal _extra({int calories = 400, int protein = 20, double portion = 1}) {
  return ExtraMeal(
    id: 'x',
    date: '2026-10-26',
    name: 'Arepa con queso',
    source: ExtraMealSource.manual,
    baseCalories: calories,
    baseProteinGrams: protein,
    portion: portion,
  );
}

PlannedMeal _planned(String id, MealStatus status, {int calories = 500, int protein = 30}) {
  return PlannedMeal.fromJson({
    'id': id,
    'slotLabelKey': 'lunch',
    'scheduledHour': 13,
    'scheduledMinute': 0,
    'name': 'Pollo con arroz',
    'calories': calories,
    'proteinGrams': protein,
    'status': status.name,
  });
}

void main() {
  test('fromJson reads the server document shape', () {
    final meal = ExtraMeal.fromJson({
      'id': 'photo_abc',
      'date': '2026-10-26',
      'name': 'Hamburguesa',
      'source': 'photo',
      'base': {'calories': 700, 'proteinGrams': 35, 'carbsGrams': 50, 'fatGrams': null},
      'portion': 1.5,
      'allergenWarning': true,
      'createdAt': '2026-10-26T13:00:00.000Z',
    });
    expect(meal.source, ExtraMealSource.photo);
    expect(meal.calories, 1050);
    expect(meal.proteinGrams, 53);
    expect(meal.carbsGrams, 75);
    expect(meal.fatGrams, isNull);
    expect(meal.allergenWarning, isTrue);
  });

  test('portion scales from the base values, never compounds', () {
    expect(_extra(calories: 333, portion: 0.5).calories, 167);
    expect(_extra(calories: 333, portion: 2).calories, 666);
  });

  test('dayIntake sums registered plan meals and extra meals only', () {
    final plan = NutritionPlan(date: '2026-10-26', meals: [
      _planned('a', MealStatus.registered),
      _planned('b', MealStatus.pending, calories: 900),
    ]);
    final intake = dayIntake(plan, [_extra(), _extra(portion: 0.5)]);
    expect(intake.calories, 500 + 400 + 200);
    expect(intake.proteinGrams, 30 + 20 + 10);
    expect(intake.mealsCount, 3);
  });

  test('dayIntake works without a plan', () {
    final intake = dayIntake(null, [_extra()]);
    expect(intake.calories, 400);
    expect(intake.mealsCount, 1);
  });
}

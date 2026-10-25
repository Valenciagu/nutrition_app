import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/plan/domain/entities/nutrition_plan.dart';
import 'package:nutrition_app/features/plan/domain/entities/planned_meal.dart';

import 'plan_test_helpers.dart';

void main() {
  test('registeredCalories suma solo las comidas registradas', () {
    final p = plan('2026-10-19', [
      meal('a', status: MealStatus.registered, calories: 300),
      meal('b', calories: 500),
      meal('c', status: MealStatus.registered, calories: 250),
    ]);
    expect(p.registeredCalories, 550);
  });

  test('toJson/fromJson ida y vuelta conserva los datos', () {
    final original = NutritionPlan(
      date: '2026-10-19',
      meals: [meal('a', status: MealStatus.registered)],
      generatedAt: DateTime.utc(2026, 10, 19, 7),
    );
    final copy = NutritionPlan.fromJson(original.toJson());
    expect(copy.date, original.date);
    expect(copy.generatedAt, original.generatedAt);
    expect(copy.meals.single.status, MealStatus.registered);
    expect(copy.meals.single.name, 'a');
  });

  test('una comida sin status guardado se lee como pendiente', () {
    final json = meal('a').toJson()..remove('status');
    expect(PlannedMeal.fromJson(json).status, MealStatus.pending);
  });

  test('timeLabel rellena con ceros', () {
    final m = meal('a').copyWith(scheduledHour: 7, scheduledMinute: 5);
    expect(m.timeLabel, '07:05');
  });
}

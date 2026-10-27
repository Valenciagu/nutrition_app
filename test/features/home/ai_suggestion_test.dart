import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/home/presentation/providers/ai_suggestion_providers.dart';
import 'package:nutrition_app/features/meal_log/domain/entities/extra_meal.dart';
import 'package:nutrition_app/features/plan/domain/entities/nutrition_plan.dart';
import 'package:nutrition_app/features/plan/domain/entities/planned_meal.dart';

PlannedMeal _meal(MealStatus status) => PlannedMeal(
      id: status.name,
      slotLabelKey: 'dinner',
      scheduledHour: 20,
      scheduledMinute: 0,
      name: 'Cena',
      calories: 500,
      proteinGrams: 30,
      status: status,
    );

ExtraMeal _extra(String id, int hour) => ExtraMeal(
      id: id,
      date: '2026-10-26',
      name: 'Hamburguesa',
      source: ExtraMealSource.manual,
      baseCalories: 700,
      baseProteinGrams: 30,
      createdAt: DateTime(2026, 10, 26, hour),
    );

void main() {
  final planWithPending = NutritionPlan(date: '2026-10-26', meals: [_meal(MealStatus.registered), _meal(MealStatus.pending)]);

  test('shows the most recent extra meal when there is something left to adjust', () {
    expect(pickSuggestionMeal(planWithPending, [_extra('a', 12), _extra('b', 15)], null)?.id, 'b');
  });

  test('hidden once that meal was handled, back when a newer one is logged', () {
    expect(pickSuggestionMeal(planWithPending, [_extra('a', 12)], 'a'), isNull);
    expect(pickSuggestionMeal(planWithPending, [_extra('a', 12), _extra('b', 15)], 'a')?.id, 'b');
  });

  test('hidden without a plan, without extra meals, or with nothing pending', () {
    expect(pickSuggestionMeal(null, [_extra('a', 12)], null), isNull);
    expect(pickSuggestionMeal(planWithPending, const [], null), isNull);
    final allDone = NutritionPlan(date: '2026-10-26', meals: [_meal(MealStatus.registered)]);
    expect(pickSuggestionMeal(allDone, [_extra('a', 12)], null), isNull);
  });
}

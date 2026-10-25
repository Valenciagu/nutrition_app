import 'package:nutrition_app/features/plan/domain/entities/nutrition_plan.dart';
import 'package:nutrition_app/features/plan/domain/entities/planned_meal.dart';

PlannedMeal meal(String name, {MealStatus status = MealStatus.pending, int calories = 400, int protein = 20}) {
  return PlannedMeal(
    id: name,
    slotLabelKey: 'lunch',
    scheduledHour: 13,
    scheduledMinute: 0,
    name: name,
    calories: calories,
    proteinGrams: protein,
    status: status,
  );
}

NutritionPlan plan(String date, List<PlannedMeal> meals) => NutritionPlan(date: date, meals: meals);

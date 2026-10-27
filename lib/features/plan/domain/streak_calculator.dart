import '../../../core/utils/date_key.dart';
import 'entities/nutrition_plan.dart';
import 'entities/planned_meal.dart';

/// Días seguidos con al menos una comida registrada (Fase 3 · Home, badge
/// de racha). Cuenta hacia atrás desde hoy; si hoy todavía no hay nada
/// registrado, cuenta desde ayer — la racha no se "rompe" a las 8 a. m.
/// solo porque aún no desayunaste. Un día sin nada registrado corta.
///
/// Un día cuenta si tiene una comida del plan registrada **o** alguna
/// comida fuera del plan ([extraMealDates], YYYY-MM-DD, Épica 19) — comer
/// algo imprevisto y anotarlo también es constancia.
///
/// [plans] puede venir en cualquier orden y con huecos (ver
/// `PlanRepository.getRecentPlans`).
int computeStreak(List<NutritionPlan> plans, DateTime today, {Set<String> extraMealDates = const {}}) {
  final activeDays = {
    for (final plan in plans)
      if (plan.meals.any((meal) => meal.status == MealStatus.registered)) plan.date,
    ...extraMealDates,
  };

  var day = DateTime(today.year, today.month, today.day);
  if (!activeDays.contains(dateKey(day))) day = day.subtract(const Duration(days: 1));

  var streak = 0;
  while (activeDays.contains(dateKey(day))) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

import '../../../core/utils/date_key.dart';
import 'entities/nutrition_plan.dart';

/// D2 — detección de la tarjeta "el jueves repites N comidas de esta
/// semana" del mock (`documentation/design_screens_plan.md`), deferida en
/// PLAN-006 por necesitar justo esta lógica. Función pura, sin estado ni
/// dependencia de Riverpod — mismo criterio que
/// `notifications/domain/reminder_builder.dart`.
class RepeatedMealsSuggestion {
  const RepeatedMealsSuggestion({required this.date, required this.repeatedMealNames});

  final DateTime date;

  /// Nombres tal cual aparecen en el plan de [date] (sin normalizar), en el
  /// orden del plan — para mostrarlos y para armar el mensaje de ajuste.
  final List<String> repeatedMealNames;
}

/// Umbral literal del mock ("repites *tres* comidas").
const repeatedMealsSuggestionThreshold = 3;

/// Recorre [weekdays] en orden y devuelve el primer día cuyo plan tiene al
/// menos [repeatedMealsSuggestionThreshold] comidas (por nombre, sin
/// distinguir mayúsculas/espacios) que también aparecen en el plan de
/// algún OTRO día de la misma semana. `null` si ningún día califica o si
/// falta el plan de un día (no se puede comparar contra un plan que no
/// existe todavía).
RepeatedMealsSuggestion? detectRepeatedMealsDay(
  Map<String, NutritionPlan?> plansByDate,
  List<DateTime> weekdays,
) {
  for (final day in weekdays) {
    final plan = plansByDate[dateKey(day)];
    if (plan == null || plan.meals.isEmpty) continue;

    final otherDaysMealNames = <String>{};
    for (final otherDay in weekdays) {
      if (otherDay == day) continue;
      final otherPlan = plansByDate[dateKey(otherDay)];
      if (otherPlan == null) continue;
      otherDaysMealNames.addAll(otherPlan.meals.map((meal) => _normalize(meal.name)));
    }

    final seenNormalized = <String>{};
    final repeatedNames = <String>[];
    for (final meal in plan.meals) {
      final normalized = _normalize(meal.name);
      if (otherDaysMealNames.contains(normalized) && seenNormalized.add(normalized)) {
        repeatedNames.add(meal.name);
      }
    }

    if (repeatedNames.length >= repeatedMealsSuggestionThreshold) {
      return RepeatedMealsSuggestion(date: day, repeatedMealNames: repeatedNames);
    }
  }
  return null;
}

String _normalize(String name) => name.trim().toLowerCase();

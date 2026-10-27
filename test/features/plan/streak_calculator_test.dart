import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/plan/domain/entities/planned_meal.dart';
import 'package:nutrition_app/features/plan/domain/streak_calculator.dart';

import 'plan_test_helpers.dart';

void main() {
  final today = DateTime(2026, 10, 19, 9, 30);
  final eaten = meal('a', status: MealStatus.registered);
  final notEaten = meal('b');

  test('sin planes la racha es 0', () {
    expect(computeStreak([], today), 0);
  });

  test('cuenta días seguidos con alguna comida registrada, incluido hoy', () {
    final plans = [
      plan('2026-10-19', [eaten]),
      plan('2026-10-18', [eaten, notEaten]),
      plan('2026-10-17', [eaten]),
    ];
    expect(computeStreak(plans, today), 3);
  });

  test('si hoy aún no hay registros, cuenta desde ayer sin romper la racha', () {
    final plans = [
      plan('2026-10-19', [notEaten]),
      plan('2026-10-18', [eaten]),
      plan('2026-10-17', [eaten]),
    ];
    expect(computeStreak(plans, today), 2);
  });

  test('un día sin plan corta la racha', () {
    final plans = [
      plan('2026-10-19', [eaten]),
      plan('2026-10-17', [eaten]),
    ];
    expect(computeStreak(plans, today), 1);
  });

  test('un día con plan pero sin registros corta la racha', () {
    final plans = [
      plan('2026-10-19', [eaten]),
      plan('2026-10-18', [notEaten]),
      plan('2026-10-17', [eaten]),
    ];
    expect(computeStreak(plans, today), 1);
  });

  test('cruza fin de mes', () {
    final plans = [plan('2026-11-01', [eaten]), plan('2026-10-31', [eaten])];
    expect(computeStreak(plans, DateTime(2026, 11, 1)), 2);
  });

  test('un día con solo comidas fuera del plan también cuenta', () {
    final plans = [
      plan('2026-10-19', [eaten]),
      plan('2026-10-18', [notEaten]),
      plan('2026-10-17', [eaten]),
    ];
    expect(computeStreak(plans, today, extraMealDates: {'2026-10-18'}), 3);
    // Sin plan ese día, la comida extra lo sostiene igual.
    expect(computeStreak([plan('2026-10-19', [eaten])], today, extraMealDates: {'2026-10-18', '2026-10-17'}), 3);
  });
}

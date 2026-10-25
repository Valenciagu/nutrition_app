import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/plan/domain/repeated_meals_detector.dart';

import 'plan_test_helpers.dart';

void main() {
  final monday = DateTime(2026, 10, 19);
  final tuesday = DateTime(2026, 10, 20);
  final weekdays = [monday, tuesday];

  test('detecta un día que repite 3 comidas de otro día (sin distinguir mayúsculas/espacios)', () {
    final result = detectRepeatedMealsDay({
      '2026-10-19': plan('2026-10-19', [meal('Avena'), meal('Pollo'), meal('Ensalada')]),
      '2026-10-20': plan('2026-10-20', [meal(' avena '), meal('POLLO'), meal('Ensalada'), meal('Sopa')]),
    }, weekdays);

    expect(result, isNotNull);
    expect(result!.date, monday);
    expect(result.repeatedMealNames, ['Avena', 'Pollo', 'Ensalada']);
  });

  test('menos de 3 repetidas no sugiere nada', () {
    final result = detectRepeatedMealsDay({
      '2026-10-19': plan('2026-10-19', [meal('Avena'), meal('Pollo'), meal('Ensalada')]),
      '2026-10-20': plan('2026-10-20', [meal('Avena'), meal('Pollo'), meal('Sopa')]),
    }, weekdays);
    expect(result, isNull);
  });

  test('una comida repetida dentro del mismo día no cuenta dos veces', () {
    final result = detectRepeatedMealsDay({
      '2026-10-19': plan('2026-10-19', [meal('Avena'), meal('Avena'), meal('Avena')]),
      '2026-10-20': plan('2026-10-20', [meal('Avena')]),
    }, weekdays);
    expect(result, isNull);
  });

  test('días sin plan se ignoran', () {
    expect(detectRepeatedMealsDay({'2026-10-19': null, '2026-10-20': null}, weekdays), isNull);
  });
}

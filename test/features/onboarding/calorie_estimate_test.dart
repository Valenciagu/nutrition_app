import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/onboarding/domain/calorie_estimate.dart';
import 'package:nutrition_app/features/onboarding/domain/entities/onboarding_answers.dart';

void main() {
  test('Mifflin-St Jeor redondeado a múltiplos de 50', () {
    // Hombre 30 años, 180 cm, 80 kg: BMR = 800 + 1125 - 150 + 5 = 1780;
    // × 1.55 = 2759 → 2750.
    final kcal = estimateDailyCalories(
      sex: Sex.male,
      age: 30,
      heightCm: 180,
      weightKg: 80,
      activityLevel: ActivityLevel.moderate,
    );
    expect(kcal, 2750);
  });

  test('mujer usa el offset -161', () {
    // 25 años, 165 cm, 60 kg: BMR = 600 + 1031.25 - 125 - 161 = 1345.25;
    // × 1.2 = 1614.3 → 1600.
    final kcal = estimateDailyCalories(
      sex: Sex.female,
      age: 25,
      heightCm: 165,
      weightKg: 60,
      activityLevel: ActivityLevel.sedentary,
    );
    expect(kcal, 1600);
  });

  test('sin datos usa valores por defecto razonables', () {
    final kcal = estimateDailyCalories(
      sex: null,
      age: null,
      heightCm: null,
      weightKg: null,
      activityLevel: ActivityLevel.moderate,
    );
    expect(kcal % 50, 0);
    expect(kcal, inInclusiveRange(2000, 3000));
  });

  test('más actividad nunca da menos calorías', () {
    int estimate(ActivityLevel level) =>
        estimateDailyCalories(sex: Sex.male, age: 30, heightCm: 175, weightKg: 75, activityLevel: level);
    final values = ActivityLevel.values.map(estimate).toList();
    for (var i = 1; i < values.length; i++) {
      expect(values[i], greaterThanOrEqualTo(values[i - 1]));
    }
  });
}

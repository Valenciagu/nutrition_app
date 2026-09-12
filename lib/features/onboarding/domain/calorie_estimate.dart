import 'entities/onboarding_answers.dart';

/// Estimación determinista de calorías diarias (Mifflin-St Jeor + factor de
/// actividad) — matemática nutricional estándar, no una llamada a IA, así
/// que no viola la regla de "IA solo desde el backend" de `Instrucciones.md`.
/// Sirve únicamente como feedback en vivo durante B3; el plan real (Épica
/// 5/6) lo recalculará con el modelo de IA cuando exista.
int estimateDailyCalories({
  required Sex? sex,
  required int? age,
  required double? heightCm,
  required double? weightKg,
  required ActivityLevel activityLevel,
}) {
  final effectiveAge = age ?? 30;
  final effectiveHeight = heightCm ?? 170;
  final effectiveWeight = weightKg ?? 70;

  final sexOffset = switch (sex) {
    Sex.female => -161,
    _ => 5,
  };

  final bmr = 10 * effectiveWeight + 6.25 * effectiveHeight - 5 * effectiveAge + sexOffset;

  final multiplier = switch (activityLevel) {
    ActivityLevel.sedentary => 1.2,
    ActivityLevel.light => 1.375,
    ActivityLevel.moderate => 1.55,
    ActivityLevel.high => 1.725,
    ActivityLevel.athlete => 1.9,
  };

  return ((bmr * multiplier) / 50).round() * 50;
}

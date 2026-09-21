/**
 * Estimación determinista de calorías diarias (Mifflin-St Jeor + factor de
 * actividad) — matemática nutricional estándar, no una llamada a IA.
 *
 * Port EXACTO de `lib/features/onboarding/domain/calorie_estimate.dart`
 * (`estimateDailyCalories`). No se puede compartir código Dart/Node
 * directamente entre el cliente Flutter y esta Cloud Function — si la
 * fórmula cambia en un lado, cambiarla en el otro también, o la estimación
 * "en vivo" de B3 (Onboarding) y el objetivo real usado para generar el
 * plan (Épica 6) empiezan a divergir.
 */

export type Sex = "male" | "female" | "other";
export type ActivityLevel = "sedentary" | "light" | "moderate" | "high" | "athlete";

export interface CalorieEstimateInput {
  sex?: Sex;
  age?: number;
  heightCm?: number;
  weightKg?: number;
  activityLevel: ActivityLevel;
}

export function estimateDailyCalories({ sex, age, heightCm, weightKg, activityLevel }: CalorieEstimateInput): number {
  const effectiveAge = age ?? 30;
  const effectiveHeight = heightCm ?? 170;
  const effectiveWeight = weightKg ?? 70;

  const sexOffset = sex === "female" ? -161 : 5;

  const bmr = 10 * effectiveWeight + 6.25 * effectiveHeight - 5 * effectiveAge + sexOffset;

  const multiplier: Record<ActivityLevel, number> = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    high: 1.725,
    athlete: 1.9,
  };

  return Math.round((bmr * multiplier[activityLevel]) / 50) * 50;
}

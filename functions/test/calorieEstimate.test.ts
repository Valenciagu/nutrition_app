import { test } from "node:test";
import assert from "node:assert/strict";
import { estimateDailyCalories } from "../src/plan/calorieEstimate";

// Mismos casos que `test/features/onboarding/calorie_estimate_test.dart`:
// esta función es un port exacto de la de Dart, y si divergen, la meta que
// ve el usuario en B3/Home deja de coincidir con la que usa el plan.
test("paridad con Dart: hombre moderado", () => {
  assert.equal(estimateDailyCalories({ sex: "male", age: 30, heightCm: 180, weightKg: 80, activityLevel: "moderate" }), 2750);
});

test("paridad con Dart: mujer sedentaria", () => {
  assert.equal(estimateDailyCalories({ sex: "female", age: 25, heightCm: 165, weightKg: 60, activityLevel: "sedentary" }), 1600);
});

test("sin datos usa los mismos valores por defecto que Dart", () => {
  // 30 años, 170 cm, 70 kg, offset +5 → 1617.5 × 1.55 = 2507 → 2500.
  assert.equal(estimateDailyCalories({ activityLevel: "moderate" }), 2500);
});

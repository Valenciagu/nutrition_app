import '../entities/meal_alternative.dart';
import '../entities/nutrition_plan.dart';

/// Contrato del plan de comidas — un método por Cloud Function real del
/// lado del backend (`functions/src/plan/`). Ver `documentation/plan.md`.
abstract class PlanRepository {
  /// `null` si el usuario todavía no tiene un plan generado para esa fecha
  /// (no es un error — es el estado "Aún no tienes plan para este día").
  Future<NutritionPlan?> getPlan({required String userId, required String date});

  /// Una lectura por fecha en `dates` (Firestore no tiene un "IN" barato
  /// para subcolecciones con id de documento arbitrario) — suficiente para
  /// una semana (5 lecturas), no pensado para rangos largos.
  Future<Map<String, NutritionPlan?>> getPlansForDates({required String userId, required List<String> dates});

  /// Genera (y persiste server-side) un plan nuevo para esa fecha,
  /// sobrescribiendo cualquier plan anterior del mismo día.
  Future<NutritionPlan> generatePlan({required String userId, required String date});

  /// Ajusta las comidas PENDIENTES de un plan ya generado a partir de un
  /// mensaje libre (Instrucciones.md §9) — las ya registradas no cambian.
  Future<NutritionPlan> adjustPlan({required String userId, required String date, required String message});

  /// Marca (o desmarca, `registered: false`) una comida como consumida.
  Future<void> setMealRegistered({
    required String userId,
    required String date,
    required String mealId,
    bool registered = true,
  });

  /// D4 — 3 alternativas para una comida pendiente; no persiste el plan
  /// todavía, solo las deja disponibles server-side para `replaceMeal`.
  Future<List<MealAlternative>> suggestMealAlternatives({
    required String userId,
    required String date,
    required String mealId,
    String? filterHint,
  });

  /// D4 — confirma una de las alternativas devueltas por
  /// `suggestMealAlternatives` (por índice, nunca reenviando el contenido).
  Future<void> replaceMeal({
    required String userId,
    required String date,
    required String mealId,
    required int candidateIndex,
  });
}

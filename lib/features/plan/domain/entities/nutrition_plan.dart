import 'planned_meal.dart';

/// El plan de comidas de un día. Documento Firestore
/// `users/{userId}/nutritionPlans/{yyyy-mm-dd}` — un documento por día
/// (`date` como YYYY-MM-DD, igual al id del documento), no por semana:
/// reemplazar o registrar una comida solo escribe el día que cambia, y la
/// vista semanal (D2) es una query por rango de fechas sobre varios de
/// estos documentos, no un blob semanal creciendo sin límite
/// (Instrucciones.md §23 — evitar documentos no acotados y escrituras
/// excesivas).
///
/// Un día sin plan generado todavía no es un `NutritionPlan` con `meals`
/// vacío guardado en Firestore — es, simplemente, la ausencia del
/// documento para esa fecha (estado "Aún no tienes plan para este día" del
/// diseño). Este tipo modela un plan que sí existe.
class NutritionPlan {
  const NutritionPlan({
    required this.date,
    required this.meals,
    this.generatedAt,
  });

  /// YYYY-MM-DD, mismo formato y mismo criterio que `aiUsage/{yyyy-mm-dd}`
  /// en `functions/src/ai/quota.ts` (Épica 5).
  final String date;

  final List<PlannedMeal> meals;

  /// Cuándo la IA generó este plan (`null` si todavía no se ha generado
  /// ninguna vez, o si el plan se seeded/migró de otra forma). Sirve para
  /// decisiones futuras de regeneración ("¿el plan de hoy es de esta
  /// mañana o de hace 3 días?"), no para mostrarse directamente al usuario.
  final DateTime? generatedAt;

  /// Suma de calorías de las comidas ya registradas (consumidas) — NO el
  /// total planificado del día. Es lo que muestra D1 ("1.420 kcal"): un
  /// cálculo derivado, deliberadamente no persistido (Instrucciones.md §23
  /// — evitar duplicación de datos que puede desincronizarse).
  int get registeredCalories => meals
      .where((meal) => meal.status == MealStatus.registered)
      .fold(0, (sum, meal) => sum + meal.calories);

  NutritionPlan copyWith({
    String? date,
    List<PlannedMeal>? meals,
    DateTime? generatedAt,
  }) {
    return NutritionPlan(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'meals': meals.map((meal) => meal.toJson()).toList(),
        'generatedAt': generatedAt?.toIso8601String(),
      };

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan(
      date: json['date'] as String,
      meals: (json['meals'] as List? ?? const [])
          .map((raw) => PlannedMeal.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(),
      generatedAt: json['generatedAt'] != null ? DateTime.parse(json['generatedAt'] as String) : null,
    );
  }
}

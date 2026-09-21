/// Una de las 3 alternativas generadas por `suggestMealAlternatives` (D4)
/// para reemplazar una comida pendiente. Efímera — vive en memoria del
/// cliente mientras se muestra la hoja de reemplazo, no es parte del plan
/// guardado hasta que se confirma con `PlanRepository.replaceMeal`.
class MealAlternative {
  const MealAlternative({required this.name, required this.calories, required this.proteinGrams});

  final String name;
  final int calories;
  final int proteinGrams;

  factory MealAlternative.fromJson(Map<String, dynamic> json) {
    return MealAlternative(
      name: json['name'] as String,
      calories: json['calories'] as int,
      proteinGrams: json['proteinGrams'] as int,
    );
  }
}

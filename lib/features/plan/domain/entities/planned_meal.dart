/// Estado de una comida planificada. Deliberadamente solo 2 valores: el
/// tercer estado visual del diseño (D1 · tarjeta "elevada" para la próxima
/// comida pendiente) no es un dato guardado, es una comparación de
/// presentación (hora programada vs. hora actual) sobre una comida que
/// sigue en `pending` — ver `documentation/design_screens_plan.md`.
enum MealStatus { pending, registered }

/// Una comida dentro del plan de un día (`NutritionPlan.meals`). Contiene
/// los campos que la lista del plan (D1/D2) necesita mostrar directamente
/// — nombre, calorías, proteína, hora — sin tener que ir a buscar una
/// receta aparte; es una denormalización deliberada (Instrucciones.md §23:
/// evitar lecturas excesivas) para poder pintar el plan completo de un día
/// con una sola lectura de Firestore. `recipeId` es el puente opcional
/// hacia el detalle completo de receta (ingredientes, pasos) que construirá
/// la Épica 7 — hoy puede ser `null` porque esa entidad `Recipe` todavía no
/// existe.
class PlannedMeal {
  const PlannedMeal({
    required this.id,
    required this.slotLabelKey,
    required this.scheduledHour,
    required this.scheduledMinute,
    required this.name,
    required this.calories,
    required this.proteinGrams,
    this.status = MealStatus.pending,
    this.recipeId,
  });

  /// Único dentro de un mismo día — lo usan las acciones de reemplazar y
  /// registrar (D1 swipe, D4) para saber qué comida del plan tocar.
  final String id;

  /// Misma clave (`breakfast`, `lunch`, `afternoonSnack`, `dinner`, ...) que
  /// `MealSlot.labelKey` en `features/onboarding` (B6) — no es un enlace de
  /// código entre features, es una convención de vocabulario compartida a
  /// propósito para que el plan hable el mismo idioma de horarios que el
  /// usuario ya configuró.
  final String slotLabelKey;

  final int scheduledHour;
  final int scheduledMinute;

  final String name;
  final int calories;
  final int proteinGrams;

  final MealStatus status;
  final String? recipeId;

  /// "HH:mm" — formato de 24 h igual en todos los idiomas, por eso no pasa
  /// por `AppLocalizations`. Lo comparten D1 (Plan) y C1 (Home).
  String get timeLabel =>
      '${scheduledHour.toString().padLeft(2, '0')}:${scheduledMinute.toString().padLeft(2, '0')}';

  PlannedMeal copyWith({
    String? id,
    String? slotLabelKey,
    int? scheduledHour,
    int? scheduledMinute,
    String? name,
    int? calories,
    int? proteinGrams,
    MealStatus? status,
    String? recipeId,
  }) {
    return PlannedMeal(
      id: id ?? this.id,
      slotLabelKey: slotLabelKey ?? this.slotLabelKey,
      scheduledHour: scheduledHour ?? this.scheduledHour,
      scheduledMinute: scheduledMinute ?? this.scheduledMinute,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      status: status ?? this.status,
      recipeId: recipeId ?? this.recipeId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slotLabelKey': slotLabelKey,
        'scheduledHour': scheduledHour,
        'scheduledMinute': scheduledMinute,
        'name': name,
        'calories': calories,
        'proteinGrams': proteinGrams,
        'status': status.name,
        'recipeId': recipeId,
      };

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    return PlannedMeal(
      id: json['id'] as String,
      slotLabelKey: json['slotLabelKey'] as String,
      scheduledHour: json['scheduledHour'] as int,
      scheduledMinute: json['scheduledMinute'] as int,
      name: json['name'] as String,
      calories: json['calories'] as int,
      proteinGrams: json['proteinGrams'] as int,
      status: MealStatus.values.byName(json['status'] as String? ?? MealStatus.pending.name),
      recipeId: json['recipeId'] as String?,
    );
  }
}

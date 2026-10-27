/// De dónde salió una [ExtraMeal]. `voice`/`barcode` llegarán con LOG-103/104.
enum ExtraMealSource { manual, photo }

/// Una "comida extra" (Épica 19, LOG-101): algo que el usuario comió fuera
/// del plan. Documento `users/{uid}/extraMeals/{id}`, escrito solo por las
/// Cloud Functions `logExtraMeal`/`editExtraMeal` — el cliente solo lo lee.
///
/// Suma al día igual que una comida registrada del plan. Se guardan los
/// macros de la porción 1 (`base*`) y la [portion] por separado: lo que
/// cuenta se deriva (`calories`, `proteinGrams`, …), nunca se persiste
/// escalado — cambiar la porción varias veces no acumula redondeos.
class ExtraMeal {
  const ExtraMeal({
    required this.id,
    required this.date,
    required this.name,
    required this.source,
    required this.baseCalories,
    required this.baseProteinGrams,
    this.baseCarbsGrams,
    this.baseFatGrams,
    this.portion = 1,
    this.allergenWarning = false,
    this.createdAt,
  });

  final String id;

  /// Día local del usuario, YYYY-MM-DD (mismo formato que `NutritionPlan.date`).
  final String date;
  final String name;
  final ExtraMealSource source;
  final int baseCalories;
  final int baseProteinGrams;

  /// `null` cuando el origen no los da (una entrada manual sin ellos).
  final int? baseCarbsGrams;
  final int? baseFatGrams;

  /// 0,25–5, en pasos de 0,25 (lo valida `editExtraMeal`).
  final double portion;
  final bool allergenWarning;
  final DateTime? createdAt;

  int get calories => (baseCalories * portion).round();
  int get proteinGrams => (baseProteinGrams * portion).round();
  int? get carbsGrams => baseCarbsGrams == null ? null : (baseCarbsGrams! * portion).round();
  int? get fatGrams => baseFatGrams == null ? null : (baseFatGrams! * portion).round();

  factory ExtraMeal.fromJson(Map<String, dynamic> json) {
    final base = Map<String, dynamic>.from(json['base'] as Map);
    return ExtraMeal(
      id: json['id'] as String,
      date: json['date'] as String,
      name: json['name'] as String,
      source: json['source'] == 'photo' ? ExtraMealSource.photo : ExtraMealSource.manual,
      baseCalories: (base['calories'] as num).round(),
      baseProteinGrams: (base['proteinGrams'] as num? ?? 0).round(),
      baseCarbsGrams: (base['carbsGrams'] as num?)?.round(),
      baseFatGrams: (base['fatGrams'] as num?)?.round(),
      portion: (json['portion'] as num? ?? 1).toDouble(),
      allergenWarning: json['allergenWarning'] as bool? ?? false,
      createdAt: json['createdAt'] is String ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

/// Lo comido en un día: comidas del plan marcadas como registradas + comidas
/// extra. Única fuente de las cifras de Home (anillo, kcal/proteína) y del
/// contador de D1, para que las dos pantallas nunca se contradigan.
class DayIntake {
  const DayIntake({
    required this.planCalories,
    required this.planProteinGrams,
    required this.planMealsRegistered,
    required this.extraMeals,
  });

  final int planCalories;
  final int planProteinGrams;
  final int planMealsRegistered;
  final List<ExtraMeal> extraMeals;

  int get calories => planCalories + extraMeals.fold(0, (sum, meal) => sum + meal.calories);
  int get proteinGrams => planProteinGrams + extraMeals.fold(0, (sum, meal) => sum + meal.proteinGrams);
  int get mealsCount => planMealsRegistered + extraMeals.length;
}

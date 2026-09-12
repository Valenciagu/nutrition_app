/// Objetivo nutricional (B1). El copy real vive en las claves de
/// localización `onboardingGoal*` — este enum es solo la clave de dominio.
enum NutritionGoal { loseFat, gainMuscle, maintainWeight, eatHealthier }

enum Sex { male, female, other }

enum UnitSystem { metric, imperial }

/// Nivel de actividad (B3). El orden importa: se usa para elegir el mensaje
/// de estimación de calorías en `activity_level_step.dart`.
enum ActivityLevel { sedentary, light, moderate, high, athlete }

enum CookingTimePreference { quick, medium, relaxed }

enum CookingSkillLevel { basic, intermediate, advanced }

/// Presupuesto semanal (B7). El diseño lo muestra como un slider de 4
/// posiciones con una etiqueta + rango orientativo, no como un monto libre en
/// una moneda — no hay requisito de moneda/localización de precio en
/// `Instrucciones.md`, así que se modela como nivel discreto.
enum BudgetLevel { tight, moderate, comfortable, flexible }

/// Un paso de comida con su horario (B6). `label` es una clave de
/// localización (`fieldMealSlot<N>Label`), no texto mostrable.
class MealSlot {
  const MealSlot({required this.labelKey, required this.hour, required this.minute});

  final String labelKey;
  final int hour;
  final int minute;

  MealSlot copyWith({int? hour, int? minute}) {
    return MealSlot(labelKey: labelKey, hour: hour ?? this.hour, minute: minute ?? this.minute);
  }

  Map<String, dynamic> toJson() => {'labelKey': labelKey, 'hour': hour, 'minute': minute};

  factory MealSlot.fromJson(Map<String, dynamic> json) {
    return MealSlot(labelKey: json['labelKey'] as String, hour: json['hour'] as int, minute: json['minute'] as int);
  }
}

/// Borrador de respuestas del Onboarding conversacional (B1-B7). Todos los
/// campos son opcionales mientras se completan los pasos; `isComplete` solo
/// se marca al terminar B7. Se persiste localmente en cada cambio
/// (`OnboardingLocalDataSource`) porque el registro ocurre DESPUÉS del
/// onboarding (decisión confirmada por el usuario 2026-09-12) — todavía no
/// hay `userId` al que asociar un documento de Firestore.
class OnboardingAnswers {
  const OnboardingAnswers({
    this.goal,
    this.sex,
    this.age,
    this.heightCm,
    this.weightKg,
    this.unitSystem = UnitSystem.metric,
    this.activityLevel,
    this.likedFoods = const <String>{},
    this.avoidFoods = const <String>{},
    this.mealSlots = const <MealSlot>[],
    this.cookingTimePreference,
    this.cookingSkillLevel,
    this.budgetLevel,
    this.isComplete = false,
  });

  final NutritionGoal? goal;
  final Sex? sex;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final UnitSystem unitSystem;
  final ActivityLevel? activityLevel;

  /// IDs de alimentos que le gustan al usuario (B4) — claves estables del
  /// catálogo de comida, no texto mostrable.
  final Set<String> likedFoods;

  /// Alergias/intolerancias a evitar (B5) — mismo tratamiento que
  /// [likedFoods]. El diseño no distingue severidad (alergia vs.
  /// intolerancia) con un control propio en la UI; se guarda como una sola
  /// lista de exclusión (known gap, ver `documentation/onboarding.md`).
  final Set<String> avoidFoods;

  final List<MealSlot> mealSlots;
  final CookingTimePreference? cookingTimePreference;
  final CookingSkillLevel? cookingSkillLevel;
  final BudgetLevel? budgetLevel;

  final bool isComplete;

  OnboardingAnswers copyWith({
    NutritionGoal? goal,
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    UnitSystem? unitSystem,
    ActivityLevel? activityLevel,
    Set<String>? likedFoods,
    Set<String>? avoidFoods,
    List<MealSlot>? mealSlots,
    CookingTimePreference? cookingTimePreference,
    CookingSkillLevel? cookingSkillLevel,
    BudgetLevel? budgetLevel,
    bool? isComplete,
  }) {
    return OnboardingAnswers(
      goal: goal ?? this.goal,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      unitSystem: unitSystem ?? this.unitSystem,
      activityLevel: activityLevel ?? this.activityLevel,
      likedFoods: likedFoods ?? this.likedFoods,
      avoidFoods: avoidFoods ?? this.avoidFoods,
      mealSlots: mealSlots ?? this.mealSlots,
      cookingTimePreference: cookingTimePreference ?? this.cookingTimePreference,
      cookingSkillLevel: cookingSkillLevel ?? this.cookingSkillLevel,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() => {
        'goal': goal?.name,
        'sex': sex?.name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'unitSystem': unitSystem.name,
        'activityLevel': activityLevel?.name,
        'likedFoods': likedFoods.toList(),
        'avoidFoods': avoidFoods.toList(),
        'mealSlots': mealSlots.map((slot) => slot.toJson()).toList(),
        'cookingTimePreference': cookingTimePreference?.name,
        'cookingSkillLevel': cookingSkillLevel?.name,
        'budgetLevel': budgetLevel?.name,
        'isComplete': isComplete,
      };

  factory OnboardingAnswers.fromJson(Map<String, dynamic> json) {
    T? enumFromName<T>(List<T> values, String? name, T Function(String) parse) {
      if (name == null) return null;
      try {
        return parse(name);
      } catch (_) {
        return null;
      }
    }

    return OnboardingAnswers(
      goal: enumFromName(NutritionGoal.values, json['goal'] as String?, (n) => NutritionGoal.values.byName(n)),
      sex: enumFromName(Sex.values, json['sex'] as String?, (n) => Sex.values.byName(n)),
      age: json['age'] as int?,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      unitSystem: enumFromName(UnitSystem.values, json['unitSystem'] as String?, (n) => UnitSystem.values.byName(n)) ??
          UnitSystem.metric,
      activityLevel:
          enumFromName(ActivityLevel.values, json['activityLevel'] as String?, (n) => ActivityLevel.values.byName(n)),
      likedFoods: {...(json['likedFoods'] as List? ?? const [])}.cast<String>(),
      avoidFoods: {...(json['avoidFoods'] as List? ?? const [])}.cast<String>(),
      mealSlots: (json['mealSlots'] as List? ?? const [])
          .map((raw) => MealSlot.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(),
      cookingTimePreference: enumFromName(CookingTimePreference.values, json['cookingTimePreference'] as String?,
          (n) => CookingTimePreference.values.byName(n)),
      cookingSkillLevel: enumFromName(
          CookingSkillLevel.values, json['cookingSkillLevel'] as String?, (n) => CookingSkillLevel.values.byName(n)),
      budgetLevel:
          enumFromName(BudgetLevel.values, json['budgetLevel'] as String?, (n) => BudgetLevel.values.byName(n)),
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }
}

/// Genera los horarios por defecto para B6 según cuántas comidas/día elija
/// el usuario (3-6). El diseño solo especifica el caso de 4 comidas
/// (desayuno/almuerzo/merienda/cena) — para 3/5/6 se interpola de forma
/// razonable (decisión de producto no cubierta por el canvas, documentada en
/// `documentation/onboarding.md`).
List<MealSlot> defaultMealSlotsFor(int mealsPerDay) {
  switch (mealsPerDay) {
    case 3:
      return const [
        MealSlot(labelKey: 'breakfast', hour: 8, minute: 0),
        MealSlot(labelKey: 'lunch', hour: 13, minute: 30),
        MealSlot(labelKey: 'dinner', hour: 20, minute: 30),
      ];
    case 5:
      return const [
        MealSlot(labelKey: 'breakfast', hour: 8, minute: 0),
        MealSlot(labelKey: 'midMorningSnack', hour: 10, minute: 30),
        MealSlot(labelKey: 'lunch', hour: 13, minute: 30),
        MealSlot(labelKey: 'afternoonSnack', hour: 17, minute: 30),
        MealSlot(labelKey: 'dinner', hour: 20, minute: 30),
      ];
    case 6:
      return const [
        MealSlot(labelKey: 'breakfast', hour: 8, minute: 0),
        MealSlot(labelKey: 'midMorningSnack', hour: 10, minute: 30),
        MealSlot(labelKey: 'lunch', hour: 13, minute: 30),
        MealSlot(labelKey: 'afternoonSnack', hour: 16, minute: 30),
        MealSlot(labelKey: 'dinner', hour: 19, minute: 30),
        MealSlot(labelKey: 'eveningSnack', hour: 21, minute: 30),
      ];
    case 4:
    default:
      return const [
        MealSlot(labelKey: 'breakfast', hour: 8, minute: 0),
        MealSlot(labelKey: 'lunch', hour: 13, minute: 30),
        MealSlot(labelKey: 'afternoonSnack', hour: 17, minute: 30),
        MealSlot(labelKey: 'dinner', hour: 20, minute: 30),
      ];
  }
}

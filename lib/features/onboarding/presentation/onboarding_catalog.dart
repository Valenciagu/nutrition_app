import '../../../core/constants/app_assets.dart';
import '../../../core/localization/generated/app_localizations.dart';
import '../domain/entities/onboarding_answers.dart';

/// IDs estables del catálogo de alimentos (B4) y alérgenos (B5) — se
/// guardan tal cual en [OnboardingAnswers], el texto mostrable sale de
/// [foodLabel]/[allergenLabel]. Mantener la lista corta y curada por ahora;
/// crecerá cuando exista un catálogo real respaldado por Firestore (fuera
/// del alcance de esta épica).
const List<String> likedFoodCatalogIds = [
  'chicken',
  'meat',
  'fish',
  'eggs',
  'avocado',
  'rice',
  'legumes',
  'pasta',
  'tofu',
];

const List<String> allergenCatalogIds = [
  'lactose',
  'gluten',
  'nuts',
  'shellfish',
  'egg',
  'soy',
  'fish',
  'sesame',
];

String foodLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'chicken':
      return l10n.onboardingFoodChicken;
    case 'meat':
      return l10n.onboardingFoodMeat;
    case 'fish':
      return l10n.onboardingFoodFish;
    case 'eggs':
      return l10n.onboardingFoodEggs;
    case 'avocado':
      return l10n.onboardingFoodAvocado;
    case 'rice':
      return l10n.onboardingFoodRice;
    case 'legumes':
      return l10n.onboardingFoodLegumes;
    case 'pasta':
      return l10n.onboardingFoodPasta;
    case 'tofu':
      return l10n.onboardingFoodTofu;
    default:
      return id;
  }
}

/// Alimentos de B4 que todavía no tienen foto (ASSET-105 parcial): su tile
/// muestra el recuadro neutro de siempre en vez de una imagen inexistente.
const Set<String> _foodsWithoutPhoto = {'tofu'};

/// Foto de un alimento de B4, o `null` si aún no existe.
String? foodImageAsset(String id) => _foodsWithoutPhoto.contains(id) ? null : AppAssets.food(id);

/// Foto de cada objetivo en las tarjetas de B1.
String goalImageAsset(NutritionGoal goal) {
  return switch (goal) {
    NutritionGoal.loseFat => AppAssets.goalLoseFat,
    NutritionGoal.gainMuscle => AppAssets.goalGainMuscle,
    NutritionGoal.maintainWeight => AppAssets.goalMaintainWeight,
    NutritionGoal.eatHealthier => AppAssets.goalEatHealthier,
  };
}

String mealSlotLabel(AppLocalizations l10n, String labelKey) {
  switch (labelKey) {
    case 'breakfast':
      return l10n.onboardingMealSlotBreakfast;
    case 'lunch':
      return l10n.onboardingMealSlotLunch;
    case 'afternoonSnack':
      return l10n.onboardingMealSlotAfternoonSnack;
    case 'dinner':
      return l10n.onboardingMealSlotDinner;
    case 'midMorningSnack':
      return l10n.onboardingMealSlotMidMorningSnack;
    case 'eveningSnack':
      return l10n.onboardingMealSlotEveningSnack;
    default:
      return labelKey;
  }
}

/// Etiqueta corta (sin subtítulo) de un objetivo — B1 usa título+subtítulo
/// propios (`goal_step.dart`, tarjetas grandes); Perfil (Épica 11) solo
/// necesita el título para el resumen de cabecera y los chips de edición.
String goalLabel(AppLocalizations l10n, NutritionGoal goal) {
  return switch (goal) {
    NutritionGoal.loseFat => l10n.onboardingGoalLoseFatTitle,
    NutritionGoal.gainMuscle => l10n.onboardingGoalGainMuscleTitle,
    NutritionGoal.maintainWeight => l10n.onboardingGoalMaintainTitle,
    NutritionGoal.eatHealthier => l10n.onboardingGoalEatHealthierTitle,
  };
}

/// Subtítulo de un objetivo (B1 ya lo muestra junto al título en sus
/// tarjetas) — segundo consumidor real en B9 (`OnboardingPlanReadyPage`,
/// "Basado en tu objetivo de..."), igual que [goalLabel].
String goalSubtitle(AppLocalizations l10n, NutritionGoal goal) {
  return switch (goal) {
    NutritionGoal.loseFat => l10n.onboardingGoalLoseFatSubtitle,
    NutritionGoal.gainMuscle => l10n.onboardingGoalGainMuscleSubtitle,
    NutritionGoal.maintainWeight => l10n.onboardingGoalMaintainSubtitle,
    NutritionGoal.eatHealthier => l10n.onboardingGoalEatHealthierSubtitle,
  };
}

String activityLevelLabel(AppLocalizations l10n, ActivityLevel level) {
  return switch (level) {
    ActivityLevel.sedentary => l10n.onboardingActivitySedentaryTitle,
    ActivityLevel.light => l10n.onboardingActivityLightTitle,
    ActivityLevel.moderate => l10n.onboardingActivityModerateTitle,
    ActivityLevel.high => l10n.onboardingActivityHighTitle,
    ActivityLevel.athlete => l10n.onboardingActivityAthleteTitle,
  };
}

String cookingTimeLabel(AppLocalizations l10n, CookingTimePreference value) {
  return switch (value) {
    CookingTimePreference.quick => l10n.onboardingCookingTimeQuick,
    CookingTimePreference.medium => l10n.onboardingCookingTimeMedium,
    CookingTimePreference.relaxed => l10n.onboardingCookingTimeRelaxed,
  };
}

String budgetLabel(AppLocalizations l10n, BudgetLevel value) {
  return switch (value) {
    BudgetLevel.tight => l10n.onboardingBudgetTight,
    BudgetLevel.moderate => l10n.onboardingBudgetModerate,
    BudgetLevel.comfortable => l10n.onboardingBudgetComfortable,
    BudgetLevel.flexible => l10n.onboardingBudgetFlexible,
  };
}

String allergenLabel(AppLocalizations l10n, String id) {
  switch (id) {
    case 'lactose':
      return l10n.onboardingAllergenLactose;
    case 'gluten':
      return l10n.onboardingAllergenGluten;
    case 'nuts':
      return l10n.onboardingAllergenNuts;
    case 'shellfish':
      return l10n.onboardingAllergenShellfish;
    case 'egg':
      return l10n.onboardingAllergenEgg;
    case 'soy':
      return l10n.onboardingAllergenSoy;
    case 'fish':
      return l10n.onboardingAllergenFish;
    case 'sesame':
      return l10n.onboardingAllergenSesame;
    default:
      return id;
  }
}

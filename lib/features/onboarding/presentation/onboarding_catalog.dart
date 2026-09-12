import '../../../core/localization/generated/app_localizations.dart';

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

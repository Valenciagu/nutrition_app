/// Nombres de eventos de Analytics, centralizados en un solo lugar
/// (Instrucciones.md §48: "Analytics events should be centralized. Avoid
/// hard-coded event names throughout the application"). Solo lo usa
/// `FirebaseAnalyticsService` — ninguna feature debe llamar a
/// `FirebaseAnalytics.logEvent` directo ni referenciar estas constantes,
/// siempre a través de un método tipado de `AnalyticsService`.
abstract final class AnalyticsEvents {
  static const String signUp = 'sign_up';
  static const String login = 'login';
  static const String signOut = 'sign_out';
  static const String accountDeleted = 'account_deleted';

  static const String onboardingCompleted = 'onboarding_completed';

  static const String planGenerated = 'plan_generated';
  static const String planAdjusted = 'plan_adjusted';
  static const String mealRegistered = 'meal_registered';
  static const String mealReplaced = 'meal_replaced';

  static const String foodPhotoAnalyzed = 'food_photo_analyzed';

  static const String remindersEnabled = 'reminders_enabled';
}

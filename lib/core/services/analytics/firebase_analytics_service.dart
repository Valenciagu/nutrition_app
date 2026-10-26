import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/analytics_events.dart';
import '../firebase_instances.dart';
import 'analytics_service.dart';

/// Implementación de [AnalyticsService] sobre `firebase_analytics`. Única
/// frontera que conoce el SDK — `sign_up`/`login` usan los eventos
/// recomendados de GA4 (`logSignUp`/`logLogin`, reportes de embudo
/// integrados en la consola de Firebase); el resto son eventos propios,
/// nombrados desde `AnalyticsEvents`.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logSignUp({String method = 'email'}) => _analytics.logSignUp(signUpMethod: method);

  @override
  Future<void> logLogin({String method = 'email'}) => _analytics.logLogin(loginMethod: method);

  @override
  Future<void> logSignOut() => _analytics.logEvent(name: AnalyticsEvents.signOut);

  @override
  Future<void> logAccountDeleted() => _analytics.logEvent(name: AnalyticsEvents.accountDeleted);

  @override
  Future<void> logOnboardingCompleted() => _analytics.logEvent(name: AnalyticsEvents.onboardingCompleted);

  @override
  Future<void> logPlanGenerated() => _analytics.logEvent(name: AnalyticsEvents.planGenerated);

  @override
  Future<void> logPlanAdjusted() => _analytics.logEvent(name: AnalyticsEvents.planAdjusted);

  @override
  Future<void> logMealRegistered() => _analytics.logEvent(name: AnalyticsEvents.mealRegistered);

  @override
  Future<void> logMealReplaced() => _analytics.logEvent(name: AnalyticsEvents.mealReplaced);

  @override
  Future<void> logFoodPhotoAnalyzed({required bool isFoodPhoto}) {
    return _analytics.logEvent(
      name: AnalyticsEvents.foodPhotoAnalyzed,
      parameters: {'is_food_photo': isFoodPhoto ? 1 : 0},
    );
  }

  @override
  Future<void> logIngredientPhotoAnalyzed({required bool isIngredientPhoto, required int recipeCount}) {
    return _analytics.logEvent(
      name: AnalyticsEvents.ingredientPhotoAnalyzed,
      parameters: {'is_ingredient_photo': isIngredientPhoto ? 1 : 0, 'recipe_count': recipeCount},
    );
  }

  @override
  Future<void> logRemindersEnabled({required int activeTypeCount}) {
    return _analytics.logEvent(
      name: AnalyticsEvents.remindersEnabled,
      parameters: {'active_type_count': activeTypeCount},
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return FirebaseAnalyticsService(ref.watch(firebaseAnalyticsProvider));
});

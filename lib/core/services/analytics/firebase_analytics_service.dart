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
  Future<void> logSignUp() => _analytics.logSignUp(signUpMethod: 'email');

  @override
  Future<void> logLogin() => _analytics.logLogin(loginMethod: 'email');

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

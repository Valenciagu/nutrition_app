import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/analytics/firebase_analytics_service.dart';
import '../../../../core/services/firebase_instances.dart';
import '../../../../core/utils/date_key.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../plan/domain/entities/nutrition_plan.dart';
import '../../../plan/domain/entities/planned_meal.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import '../../data/repositories/firebase_extra_meal_repository.dart';
import '../../domain/entities/extra_meal.dart';
import '../../domain/repositories/extra_meal_repository.dart';

final extraMealRepositoryProvider = Provider<ExtraMealRepository>((ref) {
  return FirebaseExtraMealRepository(ref.watch(firestoreProvider), ref.watch(firebaseFunctionsProvider));
});

/// Comidas extra de un día (YYYY-MM-DD) — Home mira hoy, D1 el día
/// seleccionado. Vacía sin sesión.
final extraMealsForDateProvider = FutureProvider.autoDispose.family<List<ExtraMeal>, String>((ref, date) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const [];
  return ref.watch(extraMealRepositoryProvider).getForDate(userId: uid, date: date);
});

/// Suma lo comido de un día: comidas del plan registradas (si hay plan) +
/// comidas extra. Ver [DayIntake].
DayIntake dayIntake(NutritionPlan? plan, List<ExtraMeal> extraMeals) {
  final registered = plan?.meals.where((m) => m.status == MealStatus.registered).toList() ?? const <PlannedMeal>[];
  return DayIntake(
    planCalories: registered.fold(0, (sum, meal) => sum + meal.calories),
    planProteinGrams: registered.fold(0, (sum, meal) => sum + meal.proteinGrams),
    planMealsRegistered: registered.length,
    extraMeals: extraMeals,
  );
}

/// Registrar / cambiar porción / borrar una comida extra. Las cuatro
/// operaciones refrescan todas las lecturas por día (`extraMealsForDateProvider`
/// es una familia: invalidarla las invalida todas).
final extraMealControllerProvider = AsyncNotifierProvider<ExtraMealController, void>(ExtraMealController.new);

class ExtraMealController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  ExtraMealRepository get _repository => ref.read(extraMealRepositoryProvider);

  /// Devuelve `true` si quedó registrada (la pantalla decide si cerrarse).
  Future<bool> logManual({
    required DateTime date,
    required String name,
    required int calories,
    int? proteinGrams,
    int? carbsGrams,
    int? fatGrams,
  }) {
    return _run(
      () => _repository.logManual(
        date: dateKey(date),
        name: name,
        calories: calories,
        proteinGrams: proteinGrams,
        carbsGrams: carbsGrams,
        fatGrams: fatGrams,
      ),
      loggedSource: 'manual',
    );
  }

  Future<bool> logFromPhotoAnalysis({required DateTime date, required String analysisId}) {
    return _run(
      () => _repository.logFromPhotoAnalysis(date: dateKey(date), analysisId: analysisId),
      loggedSource: 'photo',
    );
  }

  Future<bool> setPortion(ExtraMeal meal, double portion) {
    return _run(() => _repository.setPortion(mealId: meal.id, portion: portion));
  }

  Future<bool> delete(ExtraMeal meal) {
    return _run(() => _repository.delete(mealId: meal.id));
  }

  Future<bool> _run(Future<Object?> Function() operation, {String? loggedSource}) async {
    if (ref.read(authStateChangesProvider).valueOrNull == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await operation();
    });
    if (state.hasError) return false;

    ref.invalidate(extraMealsForDateProvider);
    ref.invalidate(streakProvider);
    if (loggedSource != null) ref.read(analyticsServiceProvider).logExtraMealLogged(source: loggedSource);
    return true;
  }
}

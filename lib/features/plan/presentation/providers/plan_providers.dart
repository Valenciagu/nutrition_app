import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_instances.dart';
import '../../../../core/utils/date_key.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../data/repositories/firebase_plan_repository.dart';
import '../../domain/entities/meal_alternative.dart';
import '../../domain/entities/nutrition_plan.dart';
import '../../domain/repositories/plan_repository.dart';

/// D1 (día) / D2 (semana) — mismo toggle "Semana"/"Día" del diseño, sin
/// navegar a una ruta nueva: cambia qué contenido pinta `PlanPage` dentro
/// del mismo tab.
enum PlanViewMode { day, week }

final planViewModeProvider = StateProvider<PlanViewMode>((ref) => PlanViewMode.day);

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return FirebasePlanRepository(ref.watch(firestoreProvider), ref.watch(firebaseFunctionsProvider));
});

/// Día que muestra D1 — por defecto hoy. El `DayStrip` lo cambia; ningún
/// otro estado de la pantalla depende de la hora real salvo a través de
/// esto, así que "qué día es" tiene una sola fuente de verdad.
final selectedPlanDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// El plan del día seleccionado — `null` si el usuario no tiene sesión
/// (Plan requiere una cuenta real, a diferencia de Home: no hay ningún
/// camino de invitado porque tanto `generateDailyPlan` como las reglas de
/// Firestore exigen `request.auth`) o si todavía no generó un plan para
/// ese día (ambos casos se distinguen en la UI, ver `PlanPage`).
final planForDateProvider = FutureProvider.autoDispose<NutritionPlan?>((ref) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return null;

  final date = ref.watch(selectedPlanDateProvider);
  return ref.watch(planRepositoryProvider).getPlan(userId: uid, date: dateKey(date));
});

/// Orquesta "Generar plan" — mismo patrón `AsyncNotifier` que
/// `AuthController`/`OnboardingController`: el estado `AsyncValue<void>` le
/// da a la pantalla loading/error "gratis" vía `AsyncValue.guard`.
final generatePlanControllerProvider = AsyncNotifierProvider<GeneratePlanController, void>(GeneratePlanController.new);

class GeneratePlanController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> generateForSelectedDate() async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    final date = ref.read(selectedPlanDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(planRepositoryProvider).generatePlan(userId: uid, date: dateKey(date));
    });
    if (!state.hasError) {
      ref.invalidate(planForDateProvider);
    }
  }
}

/// Días lun-vie de la semana actual — misma lista que pinta `DayStrip`,
/// centralizada aquí para que D1 y D2 usen exactamente la misma semana.
List<DateTime> currentWeekdays() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return List.generate(5, (i) => monday.add(Duration(days: i)));
}

/// D2 — el plan de cada día lun-vie de la semana actual, `null` por día sin
/// plan generado. Una lectura de Firestore por día (5 en total), no una
/// query de rango — ver `PlanRepository.getPlansForDates`.
final weekPlansProvider = FutureProvider.autoDispose<Map<String, NutritionPlan?>>((ref) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return {};

  final dates = currentWeekdays().map(dateKey).toList();
  return ref.watch(planRepositoryProvider).getPlansForDates(userId: uid, dates: dates);
});

/// Orquesta "Ajustar mi plan" (PLAN-004, Instrucciones.md §9) — mismo
/// patrón `AsyncNotifier` que el resto de acciones de esta feature.
final adjustPlanControllerProvider = AsyncNotifierProvider<AdjustPlanController, void>(AdjustPlanController.new);

class AdjustPlanController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> adjustForSelectedDate(String message) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    final date = ref.read(selectedPlanDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(planRepositoryProvider).adjustPlan(userId: uid, date: dateKey(date), message: message);
    });
    if (!state.hasError) {
      ref.invalidate(planForDateProvider);
    }
  }
}

/// Orquesta "marcar como comido"/"deshacer" sobre una comida del día
/// seleccionado.
final mealRegistrationControllerProvider =
    AsyncNotifierProvider<MealRegistrationController, void>(MealRegistrationController.new);

class MealRegistrationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> setRegistered(String mealId, {required bool registered}) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    final date = ref.read(selectedPlanDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(planRepositoryProvider)
          .setMealRegistered(userId: uid, date: dateKey(date), mealId: mealId, registered: registered);
    });
    if (!state.hasError) {
      ref.invalidate(planForDateProvider);
    }
  }
}

/// D4 — sugerir/confirmar alternativas para UNA comida a la vez (solo una
/// hoja de reemplazo puede estar abierta). `alternatives` queda en `null`
/// mientras no se ha pedido nada; una vez confirmado el reemplazo, el
/// controlador invalida `planForDateProvider` y vuelve a `null`.
final mealAlternativesControllerProvider =
    AsyncNotifierProvider<MealAlternativesController, List<MealAlternative>?>(MealAlternativesController.new);

class MealAlternativesController extends AsyncNotifier<List<MealAlternative>?> {
  @override
  FutureOr<List<MealAlternative>?> build() => null;

  Future<void> fetchAlternatives(String mealId, {String? filterHint}) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    final date = ref.read(selectedPlanDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(planRepositoryProvider)
          .suggestMealAlternatives(userId: uid, date: dateKey(date), mealId: mealId, filterHint: filterHint);
    });
  }

  Future<void> confirmReplacement(String mealId, int candidateIndex) async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    final date = ref.read(selectedPlanDateProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(planRepositoryProvider)
          .replaceMeal(userId: uid, date: dateKey(date), mealId: mealId, candidateIndex: candidateIndex);
      return null;
    });
    if (!state.hasError) {
      ref.invalidate(planForDateProvider);
    }
  }

  /// Limpia las alternativas mostradas al cerrar la hoja sin confirmar
  /// nada, para que la próxima vez que se abra no muestre las de la
  /// comida anterior por una fracción de segundo.
  void reset() => state = const AsyncData(null);
}

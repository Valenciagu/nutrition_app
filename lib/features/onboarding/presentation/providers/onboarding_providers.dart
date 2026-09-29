import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_instances.dart';
import '../../data/datasources/onboarding_local_data_source.dart';
import '../../data/datasources/onboarding_remote_data_source.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_answers.dart';
import '../../domain/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(
    OnboardingLocalDataSource(),
    OnboardingRemoteDataSource(ref.watch(firestoreProvider)),
  );
});

/// Índice del paso actual dentro de B1-B7 (0-6). Vive separado de
/// [OnboardingAnswers] porque es puramente de navegación/UI, no un dato del
/// perfil que deba persistirse.
final onboardingStepIndexProvider = StateProvider<int>((ref) => 0);

const onboardingStepCount = 7;

/// Orquesta las respuestas del Onboarding conversacional. Cada `setXxx`
/// actualiza el estado en memoria y dispara un guardado local (fire-and
/// -forget: perder un guardado a mitad de un paso no es crítico, el usuario
/// puede repetirlo, y bloquear la UI en cada tecla sí sería perceptible).
class OnboardingController extends Notifier<OnboardingAnswers> {
  @override
  OnboardingAnswers build() {
    _loadDraft();
    return const OnboardingAnswers();
  }

  OnboardingRepository get _repository => ref.read(onboardingRepositoryProvider);

  Future<void> _loadDraft() async {
    final draft = await _repository.loadDraft();
    state = draft;
  }

  void _update(OnboardingAnswers Function(OnboardingAnswers) updater) {
    state = updater(state);
    unawaited(_repository.saveDraft(state));
  }

  void setGoal(NutritionGoal goal) => _update((s) => s.copyWith(goal: goal));

  void setPersonalData({Sex? sex, int? age, double? heightCm, double? weightKg, UnitSystem? unitSystem}) {
    _update((s) => s.copyWith(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg, unitSystem: unitSystem));
  }

  void setActivityLevel(ActivityLevel level) => _update((s) => s.copyWith(activityLevel: level));

  void toggleLikedFood(String foodId) {
    _update((s) {
      final updated = {...s.likedFoods};
      updated.contains(foodId) ? updated.remove(foodId) : updated.add(foodId);
      return s.copyWith(likedFoods: updated);
    });
  }

  void toggleAvoidFood(String foodId) {
    _update((s) {
      final updated = {...s.avoidFoods};
      updated.contains(foodId) ? updated.remove(foodId) : updated.add(foodId);
      return s.copyWith(avoidFoods: updated);
    });
  }

  void clearAvoidFoods() => _update((s) => s.copyWith(avoidFoods: const {}));

  void setMealsPerDay(int count) => _update((s) => s.copyWith(mealSlots: defaultMealSlotsFor(count)));

  /// Defensivo a propósito: `meal_rhythm_step.dart` (B6) muestra 4 filas por
  /// defecto (`defaultMealSlotsFor(4)`) ANTES de que el usuario toque
  /// ningún chip de "comidas por día" — solo un valor de pantalla, nunca
  /// guardado en `state.mealSlots` (que sigue en `[]` hasta que se llama
  /// `setMealsPerDay`). Tocar el horario de una de esas filas sin haber
  /// tocado un chip antes indexaba sobre esa lista vacía y lanzaba
  /// `RangeError` (crash real reportado por el usuario 2026-09-29) — mismo
  /// bug que ONBOARD-104 arregló en B2 (lo mostrado y lo guardado deben
  /// coincidir), aquí no se puede resolver con un valor por defecto
  /// constante en el constructor porque `defaultMealSlotsFor` es una lista
  /// computada, así que se resuelve aquí: si el estado real está vacío, se
  /// siembra con el mismo fallback de 4 que ya usa la pantalla antes de
  /// aplicar el cambio.
  void setMealSlotTime(int index, {required int hour, required int minute}) {
    _update((s) {
      final base = s.mealSlots.isEmpty ? defaultMealSlotsFor(4) : s.mealSlots;
      final updated = [...base];
      updated[index] = updated[index].copyWith(hour: hour, minute: minute);
      return s.copyWith(mealSlots: updated);
    });
  }

  void setCookingTimePreference(CookingTimePreference value) => _update((s) => s.copyWith(cookingTimePreference: value));

  void setCookingSkillLevel(CookingSkillLevel value) => _update((s) => s.copyWith(cookingSkillLevel: value));

  void setBudgetLevel(BudgetLevel value) => _update((s) => s.copyWith(budgetLevel: value));

  /// Marca el borrador como completo al terminar B7. La generación real del
  /// plan (B8/B9 del diseño) depende de la IA de backend (Épica 5/6, no
  /// construida todavía) — por ahora esto solo persiste el borrador
  /// completo localmente para que `migrateDraftToProfile` lo suba a
  /// Firestore en cuanto exista un usuario (ver `app_router.dart`).
  void complete() => _update((s) => s.copyWith(isComplete: true));

  Future<void> reset() async {
    await _repository.clearDraft();
    state = const OnboardingAnswers();
  }
}

final onboardingControllerProvider = NotifierProvider<OnboardingController, OnboardingAnswers>(
  OnboardingController.new,
);

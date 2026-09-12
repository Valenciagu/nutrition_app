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

  void setMealSlotTime(int index, {required int hour, required int minute}) {
    _update((s) {
      final updated = [...s.mealSlots];
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

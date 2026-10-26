import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/analytics/firebase_analytics_service.dart';
import '../../../../core/services/firebase_instances.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../onboarding/domain/entities/onboarding_answers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../data/repositories/firebase_account_repository.dart';
import '../../domain/repositories/account_repository.dart';

/// Perfil COMPLETO del usuario autenticado, leído directo de Firestore — a
/// propósito NO es `onboardingControllerProvider` (ese es el borrador del
/// flujo de registro: cada cambio dispara un guardado local en
/// `shared_preferences` y puede migrarse a Firestore en el próximo login,
/// Épica 3). Mezclar ambos ciclos de vida en un solo provider global habría
/// sido un acoplamiento frágil — Perfil edita el documento real directo, sin
/// esa maquinaria.
final userProfileProvider = FutureProvider.autoDispose<OnboardingAnswers>((ref) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const OnboardingAnswers();

  final doc = await ref.watch(firestoreProvider).collection('users').doc(uid).get();
  final raw = doc.data()?['onboarding'];
  return raw is Map ? OnboardingAnswers.fromJson(Map<String, dynamic>.from(raw)) : const OnboardingAnswers();
});

/// Estado en edición de una pantalla de "Objetivo y datos"/"Preferencias y
/// alergias" — vive solo mientras la pantalla está abierta (`.autoDispose`,
/// sin guardado local ni migración: salir sin guardar descarta a propósito).
final profileEditControllerProvider =
    NotifierProvider.autoDispose<ProfileEditController, OnboardingAnswers>(ProfileEditController.new);

class ProfileEditController extends AutoDisposeNotifier<OnboardingAnswers> {
  bool _isSeeded = false;

  /// `false` si se creó sin el perfil cargado: guardar ese estado vacío
  /// sobrescribiría objetivo, biométricos y ALERGIAS en Firestore (BUG-P01),
  /// así que [ProfileSaveController] se niega a hacerlo.
  bool get isSeeded => _isSeeded;

  /// Nace con el perfil que YA está cargado. Antes se sembraba con un
  /// `ref.listen` en la pantalla, que solo se dispara cuando el valor CAMBIA:
  /// como `ProfilePage` ya mantiene vivo [userProfileProvider], al abrir la
  /// edición el valor no cambiaba, nunca se sembraba y el formulario salía
  /// vacío (BUG-P01). Las pantallas solo muestran el formulario en el estado
  /// `data` de ese provider, así que al crearse este controlador el perfil
  /// siempre está disponible. `read` y no `watch`: recargar el perfil no
  /// debe pisar lo que el usuario está editando.
  @override
  OnboardingAnswers build() {
    final loaded = ref.read(userProfileProvider).valueOrNull;
    _isSeeded = loaded != null;
    return loaded ?? const OnboardingAnswers();
  }

  void setGoal(NutritionGoal goal) => state = state.copyWith(goal: goal);

  void setPersonalData({Sex? sex, int? age, double? heightCm, double? weightKg, UnitSystem? unitSystem}) {
    state = state.copyWith(sex: sex, age: age, heightCm: heightCm, weightKg: weightKg, unitSystem: unitSystem);
  }

  void setActivityLevel(ActivityLevel level) => state = state.copyWith(activityLevel: level);

  void toggleLikedFood(String foodId) {
    final updated = {...state.likedFoods};
    updated.contains(foodId) ? updated.remove(foodId) : updated.add(foodId);
    state = state.copyWith(likedFoods: updated);
  }

  void toggleAvoidFood(String foodId) {
    final updated = {...state.avoidFoods};
    updated.contains(foodId) ? updated.remove(foodId) : updated.add(foodId);
    state = state.copyWith(avoidFoods: updated);
  }

  void setCookingTimePreference(CookingTimePreference value) => state = state.copyWith(cookingTimePreference: value);

  void setBudgetLevel(BudgetLevel value) => state = state.copyWith(budgetLevel: value);
}

/// Guarda [profileEditControllerProvider] en Firestore vía
/// `OnboardingRepository.updateProfile` (mismo destino que escribe
/// Onboarding, sin su ciclo de vida de borrador).
final profileSaveControllerProvider = AsyncNotifierProvider.autoDispose<ProfileSaveController, void>(ProfileSaveController.new);

class ProfileSaveController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> save() async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    if (!ref.read(profileEditControllerProvider.notifier).isSeeded) {
      state = AsyncError(StateError('Profile edit form was never seeded; refusing to overwrite the profile'), StackTrace.current);
      return;
    }
    final answers = ref.read(profileEditControllerProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(onboardingRepositoryProvider).updateProfile(uid, answers);
    });
    if (!state.hasError) {
      ref.invalidate(userProfileProvider);
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return FirebaseAccountRepository(ref.watch(firebaseFunctionsProvider));
});

final deleteAccountControllerProvider =
    AsyncNotifierProvider.autoDispose<DeleteAccountController, void>(DeleteAccountController.new);

class DeleteAccountController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(accountRepositoryProvider).deleteAccount());
    if (!state.hasError) {
      ref.read(analyticsServiceProvider).logAccountDeleted();
      // El usuario de Firebase Auth ya no existe server-side tras
      // `deleteAccount` (Admin SDK) — se cierra sesión local explícitamente
      // en vez de esperar a que el SDK de cliente note el token inválido en
      // su próximo refresh, para que el router reaccione de inmediato.
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}

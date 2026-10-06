import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_key.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../plan/domain/entities/nutrition_plan.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import 'onboarding_providers.dart';

/// Orquesta B8 (Fase 2 · Bloque B): asegura una sesión — anónima si todavía
/// no hay ninguna, ver `AuthController.ensureAnonymousSession` — sube el
/// borrador YA completo de Onboarding a Firestore bajo ese `uid`
/// (`OnboardingRepository.updateProfile`, NO `migrateDraftToProfile`: ese
/// borraría el borrador local, y A4 todavía lo necesita vivo para mostrar
/// "tu plan ya está calculado" — ver `documentation/onboarding.md`) y genera
/// el plan de hoy reusando `PlanRepository.generatePlan` (Épica 6, el mismo
/// Cloud Function que ya usa el botón "Generar" del tab Plan) — ningún
/// backend nuevo para esto.
final planGenerationControllerProvider =
    AsyncNotifierProvider.autoDispose<PlanGenerationController, NutritionPlan?>(PlanGenerationController.new);

class PlanGenerationController extends AutoDisposeAsyncNotifier<NutritionPlan?> {
  @override
  FutureOr<NutritionPlan?> build() => null;

  Future<void> generate() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authControllerProvider.notifier).ensureAnonymousSession();
      // Lectura síncrona a propósito (no el stream de `authStateChangesProvider`,
      // que no garantiza haberse refrescado ya en el mismo microtask tras el
      // `await` anterior) — mismo motivo que usa el `redirect` del router.
      final uid = ref.read(authRepositoryProvider).currentUser!.uid;

      final answers = ref.read(onboardingControllerProvider);
      await ref.read(onboardingRepositoryProvider).updateProfile(uid, answers);

      return ref.read(planRepositoryProvider).generatePlan(userId: uid, date: dateKey(DateTime.now()));
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/step_header.dart';
import 'steps/activity_level_step.dart';
import 'steps/allergies_step.dart';
import 'steps/cooking_budget_step.dart';
import 'steps/goal_step.dart';
import 'steps/liked_foods_step.dart';
import 'steps/meal_rhythm_step.dart';
import 'steps/personal_data_step.dart';

/// Bloque B (B1-B7) del Onboarding conversacional: mismo esqueleto en los 7
/// pasos (`StepHeader` + contenido + CTA), un solo `GoRoute` — la
/// navegación entre pasos es interna (`onboardingStepIndexProvider`), no
/// rutas separadas, porque es un único flujo lineal sin deep-linking a un
/// paso específico.
///
/// Al terminar B7 se marca el borrador completo y se navega a B8
/// (`/onboarding/generating`, ruta propia — ver `route_paths.dart`), que
/// genera el plan real antes de pedir cuenta (ONBOARD-101, construido
/// 2026-10-05 con autenticación anónima — ver `documentation/onboarding.md`).
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final stepIndex = ref.watch(onboardingStepIndexProvider);

    void goNext() {
      if (stepIndex < onboardingStepCount - 1) {
        ref.read(onboardingStepIndexProvider.notifier).state = stepIndex + 1;
      } else {
        ref.read(onboardingControllerProvider.notifier).complete();
        ref.read(guestModeProvider.notifier).state = true;
        context.go(RoutePaths.onboardingGenerating);
      }
    }

    void goBack() {
      if (stepIndex > 0) {
        ref.read(onboardingStepIndexProvider.notifier).state = stepIndex - 1;
      } else {
        context.go(RoutePaths.welcome);
      }
    }

    final steps = [
      GoalStep(onNext: goNext),
      PersonalDataStep(onNext: goNext),
      ActivityLevelStep(onNext: goNext),
      LikedFoodsStep(onNext: goNext),
      AllergiesStep(onNext: goNext),
      MealRhythmStep(onNext: goNext),
      CookingBudgetStep(onSubmit: goNext),
    ];

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space16, AppSpacing.space20, 0),
              child: StepHeader(currentStep: stepIndex + 1, totalSteps: onboardingStepCount, onBack: goBack),
            ),
            const SizedBox(height: AppSpacing.space20),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(key: ValueKey(stepIndex), child: steps[stepIndex]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

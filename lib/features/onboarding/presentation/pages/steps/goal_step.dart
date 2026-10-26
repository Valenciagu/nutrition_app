import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/localization/app_localizations_ext.dart';
import '../../../../../core/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/onboarding_answers.dart';
import '../../onboarding_catalog.dart';
import '../../providers/onboarding_providers.dart';
import '../../widgets/onboarding_option_card.dart';

/// B1 · Objetivo, selección única. Al elegir una opción, avanza sola tras
/// 180 ms (se ve la selección antes de cambiar de pantalla) — regla del
/// diseño para preguntas de selección única pura.
class GoalStep extends ConsumerStatefulWidget {
  const GoalStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<GoalStep> createState() => _GoalStepState();
}

class _GoalStepState extends ConsumerState<GoalStep> {
  NutritionGoal? _pendingSelection;

  void _select(NutritionGoal goal) {
    setState(() => _pendingSelection = goal);
    ref.read(onboardingControllerProvider.notifier).setGoal(goal);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) widget.onNext();
    });
  }

  ({String title, String subtitle}) _copyFor(AppLocalizations l10n, NutritionGoal goal) {
    return switch (goal) {
      NutritionGoal.loseFat => (title: l10n.onboardingGoalLoseFatTitle, subtitle: l10n.onboardingGoalLoseFatSubtitle),
      NutritionGoal.gainMuscle => (
          title: l10n.onboardingGoalGainMuscleTitle,
          subtitle: l10n.onboardingGoalGainMuscleSubtitle,
        ),
      NutritionGoal.maintainWeight => (
          title: l10n.onboardingGoalMaintainTitle,
          subtitle: l10n.onboardingGoalMaintainSubtitle,
        ),
      NutritionGoal.eatHealthier => (
          title: l10n.onboardingGoalEatHealthierTitle,
          subtitle: l10n.onboardingGoalEatHealthierSubtitle,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final selected = _pendingSelection ?? ref.watch(onboardingControllerProvider).goal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingGoalTitle, style: AppTypography.display.copyWith(fontSize: 29, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text(l10n.onboardingGoalSubtitle, style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary)),
          const SizedBox(height: 20),
          for (final goal in NutritionGoal.values) ...[
            Builder(builder: (context) {
              final copy = _copyFor(l10n, goal);
              return OnboardingOptionCard(
                title: copy.title,
                subtitle: copy.subtitle,
                selected: selected == goal,
                imageAsset: goalImageAsset(goal),
                onTap: () => _select(goal),
              );
            }),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

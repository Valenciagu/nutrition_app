import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/localization/app_localizations_ext.dart';
import '../../../../../core/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/calorie_estimate.dart';
import '../../../domain/entities/onboarding_answers.dart';
import '../../providers/onboarding_providers.dart';
import '../../widgets/onboarding_option_card.dart';

/// B3 · Nivel de actividad, selección única con auto-avance (180 ms) —
/// misma regla que B1. Primera aparición de un cálculo "vivo" (estimación de
/// calorías) que reacciona a la respuesta, ver `calorie_estimate.dart`.
class ActivityLevelStep extends ConsumerStatefulWidget {
  const ActivityLevelStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<ActivityLevelStep> createState() => _ActivityLevelStepState();
}

class _ActivityLevelStepState extends ConsumerState<ActivityLevelStep> {
  ActivityLevel? _pendingSelection;

  void _select(ActivityLevel level) {
    setState(() => _pendingSelection = level);
    ref.read(onboardingControllerProvider.notifier).setActivityLevel(level);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) widget.onNext();
    });
  }

  ({String title, String subtitle}) _copyFor(AppLocalizations l10n, ActivityLevel level) {
    return switch (level) {
      ActivityLevel.sedentary => (
          title: l10n.onboardingActivitySedentaryTitle,
          subtitle: l10n.onboardingActivitySedentarySubtitle,
        ),
      ActivityLevel.light => (title: l10n.onboardingActivityLightTitle, subtitle: l10n.onboardingActivityLightSubtitle),
      ActivityLevel.moderate => (
          title: l10n.onboardingActivityModerateTitle,
          subtitle: l10n.onboardingActivityModerateSubtitle,
        ),
      ActivityLevel.high => (title: l10n.onboardingActivityHighTitle, subtitle: l10n.onboardingActivityHighSubtitle),
      ActivityLevel.athlete => (
          title: l10n.onboardingActivityAthleteTitle,
          subtitle: l10n.onboardingActivityAthleteSubtitle,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final answers = ref.watch(onboardingControllerProvider);
    final selected = _pendingSelection ?? answers.activityLevel;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingActivityTitle, style: AppTypography.display.copyWith(fontSize: 29, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingActivitySubtitle,
            style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 20),
          for (final level in ActivityLevel.values) ...[
            Builder(builder: (context) {
              final copy = _copyFor(l10n, level);
              return OnboardingOptionCard(
                title: copy.title,
                subtitle: copy.subtitle,
                selected: selected == level,
                onTap: () => _select(level),
              );
            }),
            const SizedBox(height: 10),
          ],
          if (selected != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: colors.aiActionSurface, borderRadius: BorderRadius.circular(16)),
              child: Text(
                l10n.onboardingActivityEstimateMessage(
                  _copyFor(l10n, selected).title,
                  estimateDailyCalories(
                    sex: answers.sex,
                    age: answers.age,
                    heightCm: answers.heightCm,
                    weightKg: answers.weightKg,
                    activityLevel: selected,
                  ),
                ),
                style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.onAiAction),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

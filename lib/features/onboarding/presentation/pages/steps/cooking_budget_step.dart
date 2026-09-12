import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/localization/app_localizations_ext.dart';
import '../../../../../core/localization/generated/app_localizations.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/selectable_chip.dart';
import '../../../domain/entities/onboarding_answers.dart';
import '../../providers/onboarding_providers.dart';

/// B7 · Cocina y presupuesto — último paso, CTA cambia a "Crear mi plan".
/// Tres preguntas ligeras en una sola pantalla porque ninguna merece un
/// paso propio (nota del propio diseño).
class CookingBudgetStep extends ConsumerWidget {
  const CookingBudgetStep({super.key, required this.onSubmit});

  final VoidCallback onSubmit;

  String _timeLabel(AppLocalizations l10n, CookingTimePreference v) => switch (v) {
        CookingTimePreference.quick => l10n.onboardingCookingTimeQuick,
        CookingTimePreference.medium => l10n.onboardingCookingTimeMedium,
        CookingTimePreference.relaxed => l10n.onboardingCookingTimeRelaxed,
      };

  String _skillLabel(AppLocalizations l10n, CookingSkillLevel v) => switch (v) {
        CookingSkillLevel.basic => l10n.onboardingCookingSkillBasic,
        CookingSkillLevel.intermediate => l10n.onboardingCookingSkillIntermediate,
        CookingSkillLevel.advanced => l10n.onboardingCookingSkillAdvanced,
      };

  String _budgetLabel(AppLocalizations l10n, BudgetLevel v) => switch (v) {
        BudgetLevel.tight => l10n.onboardingBudgetTight,
        BudgetLevel.moderate => l10n.onboardingBudgetModerate,
        BudgetLevel.comfortable => l10n.onboardingBudgetComfortable,
        BudgetLevel.flexible => l10n.onboardingBudgetFlexible,
      };

  String _budgetRange(AppLocalizations l10n, BudgetLevel v) => switch (v) {
        BudgetLevel.tight => l10n.onboardingBudgetRangeTight,
        BudgetLevel.moderate => l10n.onboardingBudgetRangeModerate,
        BudgetLevel.comfortable => l10n.onboardingBudgetRangeComfortable,
        BudgetLevel.flexible => l10n.onboardingBudgetRangeFlexible,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final answers = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final budget = answers.budgetLevel ?? BudgetLevel.tight;
    final isValid = answers.cookingTimePreference != null && answers.cookingSkillLevel != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onboardingCookingTitle, style: AppTypography.display.copyWith(fontSize: 29, color: colors.textPrimary)),
          const SizedBox(height: 8),
          Text(l10n.onboardingCookingSubtitle, style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary)),
          const SizedBox(height: 20),
          _sectionLabel(l10n.onboardingCookingTimeLabel, colors),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final value in CookingTimePreference.values)
                SelectableChip(
                  label: _timeLabel(l10n, value),
                  selected: answers.cookingTimePreference == value,
                  showCheckWhenSelected: false,
                  onTap: () => controller.setCookingTimePreference(value),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionLabel(l10n.onboardingCookingSkillLabel, colors),
          const SizedBox(height: 10),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final value in CookingSkillLevel.values)
                SelectableChip(
                  label: _skillLabel(l10n, value),
                  selected: answers.cookingSkillLevel == value,
                  showCheckWhenSelected: false,
                  onTap: () => controller.setCookingSkillLevel(value),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _sectionLabel(l10n.onboardingBudgetLabel, colors),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_budgetLabel(l10n, budget), style: AppTypography.label.copyWith(fontSize: 13, color: colors.textSecondary)),
                    Text(
                      _budgetRange(l10n, budget),
                      style: AppTypography.bodyL.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Slider(
                  value: BudgetLevel.values.indexOf(budget).toDouble(),
                  min: 0,
                  max: (BudgetLevel.values.length - 1).toDouble(),
                  divisions: BudgetLevel.values.length - 1,
                  activeColor: colors.actionPrimary,
                  onChanged: (v) => controller.setBudgetLevel(BudgetLevel.values[v.round()]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: l10n.onboardingSubmitButton, fullWidth: true, onPressed: isValid ? onSubmit : null),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, AppColorTokens colors) {
    return Text(text.toUpperCase(), style: AppTypography.label.copyWith(fontSize: 11.5, letterSpacing: 1, color: colors.textSecondary));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/localization/app_localizations_ext.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/onboarding_answers.dart';
import '../../onboarding_catalog.dart';
import '../../providers/onboarding_providers.dart';
import '../../widgets/wheel_value_field.dart';

/// B6 · Ritmo de comidas. El número de comidas genera las filas de horario
/// en vivo — cambiar el conteo reemplaza los horarios por los valores por
/// defecto de `defaultMealSlotsFor` (el usuario puede ajustarlos después).
class MealRhythmStep extends ConsumerWidget {
  const MealRhythmStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final answers = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final mealSlots = answers.mealSlots.isEmpty ? defaultMealSlotsFor(4) : answers.mealSlots;
    final mealsPerDay = mealSlots.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingMealRhythmTitle,
            style: AppTypography.display.copyWith(fontSize: 29, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingMealRhythmSubtitle,
            style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingMealsPerDayLabel.toUpperCase(),
            style: AppTypography.label.copyWith(fontSize: 11.5, letterSpacing: 1, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final count in [3, 4, 5, 6]) ...[
                Expanded(
                  child: _CountOption(
                    count: count,
                    selected: mealsPerDay == count,
                    onTap: () => controller.setMealsPerDay(count),
                  ),
                ),
                if (count != 6) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.onboardingSchedulesLabel.toUpperCase(),
            style: AppTypography.label.copyWith(fontSize: 11.5, letterSpacing: 1, color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < mealSlots.length; i++) ...[
            _MealTimeRow(
              label: mealSlotLabel(l10n, mealSlots[i].labelKey),
              hour: mealSlots[i].hour,
              minute: mealSlots[i].minute,
              onTap: () async {
                final picked = await showIntWheelPicker(
                  context,
                  min: 0,
                  max: 23 * 60 + 45,
                  step: 15,
                  initialValue: mealSlots[i].hour * 60 + (mealSlots[i].minute ~/ 15) * 15,
                  labelBuilder: (v) => '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}',
                );
                if (picked != null) controller.setMealSlotTime(i, hour: picked ~/ 60, minute: picked % 60);
              },
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          AppButton(label: l10n.continueButtonLabel, fullWidth: true, onPressed: onNext),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _CountOption extends StatelessWidget {
  const _CountOption({required this.count, required this.selected, required this.onTap});

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.actionPrimarySurface : null,
          border: Border.all(color: selected ? colors.actionPrimary : colors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$count',
          style: AppTypography.bodyL.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: selected ? colors.actionPrimaryPressed : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MealTimeRow extends StatelessWidget {
  const _MealTimeRow({required this.label, required this.hour, required this.minute, required this.onTap});

  final String label;
  final int hour;
  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final time = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyM.copyWith(fontSize: 14.5)),
            Text(
              time,
              style: AppTypography.label.copyWith(fontSize: 14.5, color: colors.actionPrimary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

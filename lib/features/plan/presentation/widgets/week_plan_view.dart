import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_key.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../onboarding/presentation/onboarding_catalog.dart';
import '../../domain/entities/nutrition_plan.dart';
import '../../domain/entities/planned_meal.dart';
import '../providers/plan_providers.dart';

/// D2 · Plan semanal — simplificada respecto al mock (sin la tarjeta de
/// sugerencia "el jueves repites 3 comidas", que necesitaría detectar
/// repeticiones entre días; deferido, no fingido, ver
/// `documentation/plan.md`). Tocar un día cambia a la vista de día (D1) con
/// esa fecha seleccionada — mismo criterio de interacción que el diseño.
class WeekPlanView extends ConsumerWidget {
  const WeekPlanView({super.key, required this.onSelectDay});

  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final weekAsync = ref.watch(weekPlansProvider);

    return weekAsync.when(
      loading: () => const AppStateBlock.loading(),
      error: (error, _) => AppStateBlock.error(
        title: l10n.genericErrorTitle,
        message: l10n.genericErrorMessage,
        onAction: () => ref.invalidate(weekPlansProvider),
      ),
      data: (plansByDate) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final day in currentWeekdays()) ...[
            _WeekDayRow(day: day, plan: plansByDate[dateKey(day)], onTap: () => onSelectDay(day)),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _WeekDayRow extends StatelessWidget {
  const _WeekDayRow({required this.day, required this.plan, required this.onTap});

  final DateTime day;
  final NutritionPlan? plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).languageCode;
    final dayLabel = DateFormat.EEEE(locale).format(day);
    final totalCalories = plan?.meals.fold<int>(0, (sum, meal) => sum + meal.calories);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${dayLabel[0].toUpperCase()}${dayLabel.substring(1)}',
                style: AppTypography.bodyL.copyWith(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
              Text(
                totalCalories == null ? l10n.planWeekEmptyDay : l10n.planCaloriesValue(totalCalories),
                style: AppTypography.label.copyWith(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (plan == null)
            Container(
              height: 56,
              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(13)),
            )
          else
            Row(
              children: [
                for (final meal in plan!.meals) ...[
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: meal.status == MealStatus.registered ? colors.actionPrimarySurface : colors.surface,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        mealSlotLabel(l10n, meal.slotLabelKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(fontSize: 9, fontWeight: FontWeight.w600, color: colors.textSecondary),
                      ),
                    ),
                  ),
                  if (meal != plan!.meals.last) const SizedBox(width: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

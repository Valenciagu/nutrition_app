import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/date_key.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../onboarding/presentation/onboarding_catalog.dart';
import '../../domain/entities/nutrition_plan.dart';
import '../../domain/entities/planned_meal.dart';
import '../../domain/repeated_meals_detector.dart';
import '../providers/plan_providers.dart';
import 'adjust_plan_sheet.dart';

/// D2 · Plan semanal. Tocar un día cambia a la vista de día (D1) con esa
/// fecha seleccionada — mismo criterio de interacción que el diseño. Desde
/// PLAN-006 (2026-09-29) incluye la tarjeta de sugerencia del mock ("el
/// jueves repites N comidas de esta semana"), antes deferida por necesitar
/// justo la detección de repeticiones que ahora vive en
/// `detectRepeatedMealsDay` — ver `documentation/plan.md`.
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
      data: (plansByDate) {
        final weekdays = currentWeekdays();
        final suggestion = detectRepeatedMealsDay(plansByDate, weekdays);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final day in weekdays) ...[
              _WeekDayRow(day: day, plan: plansByDate[dateKey(day)], onTap: () => onSelectDay(day)),
              const SizedBox(height: 14),
            ],
            if (suggestion != null)
              _RepeatedMealsSuggestionCard(
                suggestion: suggestion,
                onRenew: () => _renewDay(context, ref, suggestion),
              ),
          ],
        );
      },
    );
  }

  /// Navega a D1 con [suggestion.date] seleccionada (mismo camino que tocar
  /// el día en la lista) y abre la hoja de ajuste ya existente (PLAN-004)
  /// precargada con un mensaje que nombra las comidas repetidas reales —
  /// el usuario sigue viendo y confirmando el texto exacto antes de que se
  /// gaste una llamada a la IA, no es un botón que dispara algo a ciegas.
  void _renewDay(BuildContext context, WidgetRef ref, RepeatedMealsSuggestion suggestion) {
    ref.read(selectedPlanDateProvider.notifier).state = suggestion.date;
    ref.read(planViewModeProvider.notifier).state = PlanViewMode.day;
    final message = context.l10n.planWeekRepeatAdjustMessage(suggestion.repeatedMealNames.join(', '));
    showAdjustPlanSheet(context, initialMessage: message);
  }
}

class _RepeatedMealsSuggestionCard extends StatelessWidget {
  const _RepeatedMealsSuggestionCard({required this.suggestion, required this.onRenew});

  final RepeatedMealsSuggestion suggestion;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).languageCode;
    final dayLabel = DateFormat.EEEE(locale).format(suggestion.date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: colors.aiActionSurface,
        border: Border.all(color: colors.aiActionSurface),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.planWeekRepeatMessage(dayLabel, suggestion.repeatedMealNames.length),
            style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.onAiAction),
          ),
          const SizedBox(height: AppSpacing.space12),
          // No se usa `AppButtonVariant.aiAction` aquí: su fondo es
          // exactamente `aiActionSurface`, el mismo color que esta tarjeta
          // (mock: "fondo aiActionSurface, borde a juego") — quedaría
          // invisible encima. Ningún token del canvas confirma todavía el
          // "indigo sólido" que pide el mock para AIMessage (componente
          // deferido, ver `app_color_tokens.dart`), así que en vez de
          // inventar un hex nuevo se invierten los dos tokens de IA ya
          // confirmados (fondo `onAiAction`, texto `aiActionSurface`) para
          // lograr el mismo contraste "sólido sobre claro" sin salir del
          // sistema de color ya validado.
          GestureDetector(
            onTap: onRenew,
            child: Container(
              width: double.infinity,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: colors.onAiAction, borderRadius: BorderRadius.circular(999)),
              child: Text(
                l10n.planWeekRepeatCta(dayLabel),
                style: AppTypography.label.copyWith(fontSize: 13, fontWeight: FontWeight.w600, color: colors.aiActionSurface),
              ),
            ),
          ),
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

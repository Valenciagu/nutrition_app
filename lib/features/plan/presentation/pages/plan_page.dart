import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/meal_card.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../onboarding/presentation/onboarding_catalog.dart';
import '../../domain/entities/nutrition_plan.dart';
import '../../domain/entities/planned_meal.dart';
import '../providers/plan_providers.dart';
import '../widgets/adjust_plan_sheet.dart';
import '../widgets/day_strip.dart';
import '../widgets/replace_meal_sheet.dart';
import '../widgets/week_plan_view.dart';

/// D1/D2 · Plan del día / Plan semanal (Fase 4). Reemplaza el
/// `ComingSoonPage` de la Épica 4. Ver `documentation/plan.md` para el
/// detalle completo de qué incluye y qué queda fuera (D5/modo cocina vive
/// en la Épica 7).
class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;

    ref.listen(generatePlanControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      }
    });
    ref.listen(adjustPlanControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      }
    });
    ref.listen(mealRegistrationControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: uid == null ? _GuestState(l10n: l10n) : const _PlanContent(),
      ),
    );
  }
}

/// Plan requiere una cuenta real (a diferencia de Home): tanto las Cloud
/// Functions de `functions/src/plan/` como las reglas de Firestore exigen
/// `request.auth`, y no hay ningún camino de invitado con datos locales —
/// no tendría sentido inventar uno solo para esta pantalla.
class _GuestState extends StatelessWidget {
  const _GuestState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space20),
        child: AppStateBlock.empty(
          title: l10n.planGuestTitle,
          message: l10n.planGuestMessage,
          actionLabel: l10n.planGuestCta,
          onAction: () => context.go(RoutePaths.signUp),
        ),
      ),
    );
  }
}

class _PlanContent extends ConsumerWidget {
  const _PlanContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final selectedDate = ref.watch(selectedPlanDateProvider);
    final viewMode = ref.watch(planViewModeProvider);
    final planAsync = ref.watch(planForDateProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space16, AppSpacing.space20, AppSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.planTitle, style: AppTypography.display.copyWith(fontSize: 25, color: colors.textPrimary)),
              GestureDetector(
                onTap: () => ref.read(planViewModeProvider.notifier).state =
                    viewMode == PlanViewMode.day ? PlanViewMode.week : PlanViewMode.day,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: viewMode == PlanViewMode.week ? colors.actionPrimary : colors.surface,
                    border: viewMode == PlanViewMode.week ? null : Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    viewMode == PlanViewMode.day ? l10n.planWeekToggleLabel : l10n.planDayToggleLabel,
                    style: AppTypography.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: viewMode == PlanViewMode.week ? colors.onActionPrimary : colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          if (viewMode == PlanViewMode.week)
            WeekPlanView(
              onSelectDay: (date) {
                ref.read(selectedPlanDateProvider.notifier).state = date;
                ref.read(planViewModeProvider.notifier).state = PlanViewMode.day;
              },
            )
          else ...[
            DayStrip(
              days: currentWeekdays(),
              selectedDate: selectedDate,
              onSelect: (date) => ref.read(selectedPlanDateProvider.notifier).state = date,
            ),
            const SizedBox(height: AppSpacing.space16),
            planAsync.when(
              loading: () => const AppStateBlock.loading(),
              error: (error, _) => AppStateBlock.error(
                title: l10n.genericErrorTitle,
                message: l10n.genericErrorMessage,
                onAction: () => ref.invalidate(planForDateProvider),
              ),
              data: (plan) => plan == null ? _EmptyPlan(l10n: l10n) : _PopulatedPlan(l10n: l10n, plan: plan),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPlan extends ConsumerWidget {
  const _EmptyPlan({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGenerating = ref.watch(generatePlanControllerProvider).isLoading;

    return AppStateBlock.empty(
      title: l10n.planEmptyTitle,
      message: l10n.planEmptyMessage,
      actionLabel: l10n.planEmptyCta,
      isActionLoading: isGenerating,
      onAction: isGenerating ? null : () => ref.read(generatePlanControllerProvider.notifier).generateForSelectedDate(),
    );
  }
}

class _PopulatedPlan extends ConsumerWidget {
  const _PopulatedPlan({required this.l10n, required this.plan});

  final AppLocalizations l10n;
  final NutritionPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final registeredCount = plan.meals.where((m) => m.status == MealStatus.registered).length;

    // La primera comida pendiente (en el orden en que vienen del plan, que
    // ya sigue el horario del día) es "la próxima" — la única con
    // tratamiento elevado (D1). No depende de la hora actual del
    // dispositivo, a propósito: evita que el estado visual cambie solo
    // porque pasó un minuto mientras la pantalla está abierta.
    final pendingMeals = plan.meals.where((m) => m.status == MealStatus.pending);
    final nextUpId = pendingMeals.isEmpty ? null : pendingMeals.first.id;

    void onMealTap(PlannedMeal meal) {
      if (meal.status == MealStatus.registered) {
        ref.read(mealRegistrationControllerProvider.notifier).setRegistered(meal.id, registered: false);
      } else {
        _showMealActionsSheet(context, ref, meal);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.planMealsRegisteredCounter(registeredCount, plan.meals.length),
                style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textSecondary),
              ),
              Text(
                l10n.planCaloriesValue(plan.registeredCalories),
                style: AppTypography.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: colors.actionPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final meal in plan.meals) ...[
          MealCard(
            overlineText: meal.status == MealStatus.registered
                ? l10n.planMealOverlineRegistered(mealSlotLabel(l10n, meal.slotLabelKey))
                : l10n.planMealOverlineScheduled(mealSlotLabel(l10n, meal.slotLabelKey), meal.timeLabel),
            title: meal.name,
            detailText: meal.status == MealStatus.registered
                ? l10n.planCaloriesValue(meal.calories)
                : l10n.planMealDetailPending(meal.calories, meal.proteinGrams),
            isRegistered: meal.status == MealStatus.registered,
            isElevated: meal.id == nextUpId,
            onTap: () => onMealTap(meal),
          ),
          const SizedBox(height: 10),
        ],
        QuickActionTile(
          svgIcon: AppAssets.iconRecalculateDay,
          title: l10n.planAdjustRowTitle,
          iconBackgroundColor: colors.aiActionSurface,
          onTap: () => showAdjustPlanSheet(context),
        ),
        const SizedBox(height: 10),
        QuickActionTile(
          icon: AppIcons.groceryList,
          title: l10n.planGroceryRowTitle,
          iconBackgroundColor: colors.background,
          onTap: () => context.push(RoutePaths.groceryListPath()),
        ),
      ],
    );
  }

  void _showMealActionsSheet(BuildContext context, WidgetRef ref, PlannedMeal meal) {
    showAppBottomSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickActionTile(
            icon: AppIcons.recipe,
            title: l10n.planMealViewRecipeAction,
            iconBackgroundColor: context.colors.background,
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.push(RoutePaths.recipeDetailPath(plan.date, meal.id));
            },
          ),
          const SizedBox(height: 8),
          QuickActionTile(
            icon: AppIcons.check,
            title: l10n.planMealMarkDoneAction,
            iconBackgroundColor: context.colors.actionPrimarySurface,
            onTap: () {
              Navigator.of(sheetContext).pop();
              ref.read(mealRegistrationControllerProvider.notifier).setRegistered(meal.id, registered: true);
            },
          ),
          const SizedBox(height: 8),
          QuickActionTile(
            icon: AppIcons.swap,
            title: l10n.planMealFindAlternativeAction,
            iconBackgroundColor: context.colors.background,
            onTap: () {
              Navigator.of(sheetContext).pop();
              showReplaceMealSheet(context, meal);
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/date_key.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import '../../../../core/widgets/macro_stat_tile.dart';
import '../../../../core/widgets/meal_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../meal_log/domain/entities/extra_meal.dart';
import '../../../meal_log/presentation/providers/extra_meal_providers.dart';
import '../../../onboarding/presentation/onboarding_catalog.dart';
import '../../../plan/domain/entities/nutrition_plan.dart';
import '../../../plan/domain/entities/planned_meal.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import '../../../plan/presentation/widgets/replace_meal_sheet.dart';
import '../providers/home_providers.dart';
import '../widgets/camera_action_sheet.dart';
import '../../../recipes/presentation/dish_images.dart';
import '../../../../core/widgets/ai_suggestion_card.dart';
import '../providers/ai_suggestion_providers.dart';

/// Home (Fase 3). Dos estados según haya o no un plan para HOY:
/// - **C1** (poblado): anillo con las kcal libres reales (meta − lo comido:
///   comidas del plan registradas + comidas extra, ver [DayIntake]),
///   lo consumido, "Ahora toca" con la próxima comida pendiente del plan y
///   acciones rápidas.
/// - **C3** (primer día / sin plan hoy): anillo apagado con la meta.
///
/// C2 (`AISuggestionCard` tras una comida imprevista) sigue sin construirse:
/// no existe todavía un evento guardado de "comida imprevista" que la
/// dispare. Ver `documentation/home.md`.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final goalAsync = ref.watch(homeDailyCalorieGoalProvider);
    final todayPlanAsync = ref.watch(todayPlanProvider);
    // Comidas fuera del plan (LOG-101): suman al anillo aunque hoy no haya plan.
    final extrasAsync = ref.watch(extraMealsForDateProvider(dateKey(DateTime.now())));
    // La racha nunca bloquea la pantalla: mientras carga (o si falla) no se
    // muestra el badge, nada más.
    final streak = ref.watch(streakProvider).valueOrNull ?? 0;

    void retry() {
      ref.invalidate(homeDailyCalorieGoalProvider);
      ref.invalidate(todayPlanProvider);
      ref.invalidate(extraMealsForDateProvider);
    }

    Widget body;
    if (goalAsync.isLoading || todayPlanAsync.isLoading || (extrasAsync.isLoading && !extrasAsync.hasValue)) {
      body = const _HomeSkeleton();
    } else if (goalAsync.hasError || todayPlanAsync.hasError || extrasAsync.hasError) {
      body = Center(
        child: AppStateBlock.error(
          title: l10n.genericErrorTitle,
          message: l10n.messageForError(goalAsync.error ?? todayPlanAsync.error ?? extrasAsync.error!),
          onAction: retry,
        ),
      );
    } else {
      final dailyGoal = goalAsync.requireValue;
      final plan = todayPlanAsync.requireValue;
      final intake = dayIntake(plan, extrasAsync.requireValue);
      body = RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayPlanProvider);
          ref.invalidate(streakProvider);
          ref.invalidate(extraMealsForDateProvider);
          await ref.read(todayPlanProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space16, AppSpacing.space20, AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(streak: streak),
              const SizedBox(height: AppSpacing.space16),
              if (plan != null && plan.meals.isNotEmpty)
                _PopulatedHome(plan: plan, dailyGoal: dailyGoal, intake: intake)
              else
                _EmptyHome(dailyGoal: dailyGoal, intake: intake),
            ],
          ),
        ),
      );
    }

    return Scaffold(backgroundColor: colors.background, body: SafeArea(child: body));
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.streak});

  final int streak;

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 19) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final user = ref.watch(authStateChangesProvider).valueOrNull;
    final displayName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.split('@').first ?? l10n.homeGuestName);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(l10n), style: AppTypography.bodyM.copyWith(fontSize: 14, color: colors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleL.copyWith(fontSize: 24, color: colors.textPrimary),
              ),
            ],
          ),
        ),
        // Racha en ámbar, no en verde: es constancia, no un estado de salud
        // (decisión del canvas `Marca e iconos`, ver design_system.md).
        if (streak > 0) ...[
          Semantics(
            label: l10n.homeStreakSemantics(streak),
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: colors.warningSurface, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(AppAssets.iconStreakFill, size: 16, color: colors.warning),
                  const SizedBox(width: 4),
                  Text('$streak', style: AppTypography.label.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.actionPrimarySurface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.actionPrimary.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(initial, style: AppTypography.label.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onActionPrimarySurface)),
        ),
      ],
    );
  }
}

/// C1 — solo cifras que existen de verdad en el plan: kcal y proteína (los
/// únicos macros que `generateDailyPlan` guarda por comida, mismo criterio
/// que B9). Por eso no hay barras de carbos/grasas: serían inventadas.
class _PopulatedHome extends ConsumerWidget {
  const _PopulatedHome({required this.plan, required this.dailyGoal, required this.intake});

  final NutritionPlan plan;
  final int dailyGoal;
  final DayIntake intake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;

    final eatenCalories = intake.calories;
    final eatenProtein = intake.proteinGrams;
    // Al pasarse de la meta el anillo se queda lleno y la cifra en 0 — nunca
    // un número negativo ni rojo ("progreso, nunca culpa").
    final caloriesLeft = math.max(dailyGoal - eatenCalories, 0);
    final progress = dailyGoal == 0 ? 0.0 : (eatenCalories / dailyGoal).clamp(0.0, 1.0);

    // Misma regla que D1: la primera pendiente en el orden del plan es "la
    // próxima", sin depender de la hora del dispositivo.
    final nextMeal = plan.meals.where((m) => m.status == MealStatus.pending).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // C2 — propuesta de la IA, arriba del anillo y solo si existe.
        const _AiSuggestion(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(22)),
          child: Column(
            children: [
              ProgressRing(progress: progress, centerNumber: caloriesLeft, centerLabel: l10n.homeCaloriesLeftLabel),
              const SizedBox(height: AppSpacing.space16),
              Row(
                children: [
                  MacroStatTile(value: eatenCalories, label: l10n.homeCaloriesEatenLabel, color: colors.textPrimary),
                  MacroStatTile(value: eatenProtein, label: l10n.homeProteinEatenLabel, color: colors.macroProtein),
                  MacroStatTile(value: intake.mealsCount, label: l10n.homeMealsRegisteredLabel, color: colors.textPrimary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space20),
        _SectionLabel(l10n.homeUpNextLabel),
        const SizedBox(height: 10),
        if (nextMeal != null)
          _UpNextMeal(plan: plan, meal: nextMeal)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeDayCompleteTitle, style: AppTypography.titleM.copyWith(fontSize: 16, color: colors.textPrimary)),
                const SizedBox(height: 4),
                Text(l10n.homeDayCompleteSubtitle, style: AppTypography.bodyM.copyWith(fontSize: 13.5, color: colors.textSecondary)),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.space20),
        _SectionLabel(l10n.homeQuickActionsLabel),
        const SizedBox(height: 10),
        QuickActionTile(
          svgIcon: AppAssets.iconFoodScanner,
          title: l10n.cameraSheetAnalyzeMealTitle,
          subtitle: l10n.homeAnalyzeRowSubtitle,
          iconBackgroundColor: colors.actionPrimarySurface,
          onTap: () => showCameraActionSheet(context, ref),
        ),
        const SizedBox(height: 10),
        QuickActionTile(
          svgIcon: AppAssets.iconIngredientsPhoto,
          title: l10n.cameraSheetIngredientsTitle,
          subtitle: l10n.cameraSheetIngredientsSubtitle,
          iconBackgroundColor: colors.actionPrimarySurface,
          onTap: () => startIngredientAnalysis(context, ref),
        ),
        const SizedBox(height: 10),
        const _GroceryRow(),
        const SizedBox(height: 10),
        const _AiRow(),
      ],
    );
  }
}

/// C2 · tras una comida fuera del plan (LOG-101), la IA propone equilibrar
/// lo que queda del día. "Recalcular mi día" es el mismo `adjustDailyPlan`
/// de D1 (que ya descuenta las comidas extra del presupuesto), con un
/// mensaje armado aquí; "Ahora no" la descarta hasta la próxima comida extra.
class _AiSuggestion extends ConsumerWidget {
  const _AiSuggestion();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final meal = ref.watch(homeAiSuggestionProvider);
    final isAdjusting = ref.watch(adjustPlanControllerProvider).isLoading;
    if (meal == null) return const SizedBox.shrink();

    Future<void> recalculate() async {
      // `adjustForSelectedDate` ajusta el día que mira Plan: se alinea a hoy.
      ref.read(selectedPlanDateProvider.notifier).state = DateTime.now();
      await ref
          .read(adjustPlanControllerProvider.notifier)
          .adjustForSelectedDate(l10n.homeAiSuggestionAdjustMessage(meal.name, meal.calories));
      if (!context.mounted) return;
      final result = ref.read(adjustPlanControllerProvider);
      if (result.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.messageForError(result.error!))));
        return;
      }
      await ref.read(handledSuggestionMealIdProvider.notifier).markHandled(meal.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.homeAiSuggestionDone)));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space16),
      child: AISuggestionCard(
        message: l10n.homeAiSuggestionMessage(meal.name),
        primaryLabel: l10n.homeAiSuggestionRecalculate,
        isPrimaryLoading: isAdjusting,
        onPrimary: isAdjusting ? null : recalculate,
        dismissLabel: l10n.homeAiSuggestionDismiss,
        onDismiss: () => ref.read(handledSuggestionMealIdProvider.notifier).markHandled(meal.id),
      ),
    );
  }
}

class _UpNextMeal extends ConsumerWidget {
  const _UpNextMeal({required this.plan, required this.meal});

  final NutritionPlan plan;
  final PlannedMeal meal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    // "Registrar" en D3/D5 opera sobre el día que mira Plan
    // (`selectedPlanDateProvider`), no sobre la fecha de la ruta — se alinea
    // a hoy antes de abrir, igual que "Cambiar".
    void alignPlanToToday() => ref.read(selectedPlanDateProvider.notifier).state = DateTime.now();
    void openRecipe() {
      alignPlanToToday();
      context.go(RoutePaths.recipeDetailPath(plan.date, meal.id));
    }

    return Column(
      children: [
        MealCard(
          overlineText: l10n.planMealOverlineScheduled(mealSlotLabel(l10n, meal.slotLabelKey), meal.timeLabel),
          title: meal.name,
          detailText: l10n.planMealDetailPending(meal.calories, meal.proteinGrams),
          isRegistered: false,
          isElevated: true,
          imageAsset: dishImageAsset(meal.dishCategory),
          onTap: openRecipe,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppButton(label: l10n.homeCookAction, size: AppButtonSize.md, fullWidth: true, onPressed: openRecipe),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: l10n.homeSwapAction,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.md,
                fullWidth: true,
                onPressed: () {
                  alignPlanToToday();
                  showReplaceMealSheet(context, meal);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// C3 — sin plan para hoy. El anillo apagado muestra solo la meta; las
/// filas llevan a las pantallas reales (antes eran un snackbar "Muy pronto").
class _EmptyHome extends ConsumerWidget {
  const _EmptyHome({required this.dailyGoal, required this.intake});

  final int dailyGoal;

  /// Sin plan hoy puede haber igual comidas extra: entonces el anillo se
  /// enciende con lo comido, como en C1.
  final DayIntake intake;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(22)),
          child: Column(
            children: [
              if (intake.mealsCount == 0)
                ProgressRing(progress: 0, centerNumber: dailyGoal, centerLabel: l10n.homeCaloriesAheadLabel, dimmed: true)
              else
                ProgressRing(
                  progress: dailyGoal == 0 ? 0.0 : (intake.calories / dailyGoal).clamp(0.0, 1.0),
                  centerNumber: math.max(dailyGoal - intake.calories, 0),
                  centerLabel: l10n.homeCaloriesLeftLabel,
                ),
              const SizedBox(height: 12),
              Text(l10n.homeEmptyTitle, style: AppTypography.titleM.copyWith(fontSize: 17, color: colors.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                l10n.homeEmptySubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyM.copyWith(fontSize: 13.5, color: colors.textSecondary),
              ),
              const SizedBox(height: 4),
              AppButton(label: l10n.homeEmptyCta, onPressed: () => showCameraActionSheet(context, ref)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space20),
        _SectionLabel(l10n.homeStartHereLabel),
        const SizedBox(height: 10),
        QuickActionTile(
          icon: AppIcons.plan,
          title: l10n.homePlanRowTitle,
          subtitle: l10n.homePlanRowSubtitle,
          iconBackgroundColor: colors.actionPrimarySurface,
          onTap: () => context.go(RoutePaths.plan),
        ),
        const SizedBox(height: 10),
        const _GroceryRow(),
        const SizedBox(height: 10),
        const _AiRow(),
      ],
    );
  }
}

class _GroceryRow extends StatelessWidget {
  const _GroceryRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuickActionTile(
      icon: AppIcons.groceryList,
      title: l10n.homeGroceryRowTitle,
      subtitle: l10n.homeGroceryRowSubtitle,
      iconBackgroundColor: context.colors.background,
      onTap: () => context.go(RoutePaths.groceryListPath()),
    );
  }
}

class _AiRow extends StatelessWidget {
  const _AiRow();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return QuickActionTile(
      svgIcon: AppAssets.iconAiSparkle,
      title: l10n.homeAiRowTitle,
      subtitle: l10n.homeAiRowSubtitle,
      iconBackgroundColor: context.colors.aiActionSurface,
      onTap: () => context.go(RoutePaths.ai),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.label.copyWith(fontSize: 11.5, letterSpacing: 1, color: context.colors.textSecondary),
    );
  }
}

/// C4 · Home cargando. El esqueleto respeta la silueta real (mismo anillo,
/// misma card) para que nada "salte" al llegar los datos.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20, vertical: AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBar(width: 84, height: 14),
          const SizedBox(height: 8),
          const AppSkeletonBar(width: 140, height: 22),
          const SizedBox(height: 20),
          Container(
            height: 190,
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(22)),
          ),
          const SizedBox(height: 20),
          const AppSkeletonBar(width: double.infinity, height: 60),
        ],
      ),
    );
  }
}

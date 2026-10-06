import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/macro_stat_tile.dart';
import '../../../../core/widgets/meal_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../plan/domain/entities/nutrition_plan.dart';
import '../../../plan/domain/entities/planned_meal.dart';
import '../../domain/entities/onboarding_answers.dart';
import '../onboarding_catalog.dart';
import '../providers/onboarding_providers.dart';

/// B9 · Tu plan está listo (Fase 2 · Bloque B). "Recompensa antes que la
/// cuenta" (nota del propio diseño): el usuario ve su plan real ANTES de
/// que se le pida registrarse — por eso "Empezar mi día" navega a SignUp
/// (A4, que ya muestra el banner "tu plan ya está calculado"), no a Home
/// directo; Home solo se alcanza después de A4 (registro o "Seguir sin
/// cuenta"), igual que ya funcionaba antes de esta pantalla existir.
///
/// Solo se muestran calorías y proteína: son los únicos macros que
/// `generateDailyPlan` calcula a esta altura (carbohidratos/grasa solo
/// existen por receta, Épica 7, generada bajo demanda más adelante) —
/// mostrar barras de carbos/grasa aquí sería inventar un dato que el
/// backend no devolvió todavía, lo mismo que ya se evitó en la Épica 4.
/// El saludo del mock dice "Listo, Juan." — a esta altura del flujo todavía
/// no existe ningún nombre real (se pide en A4, que viene DESPUÉS), así que
/// se omite en vez de inventar uno.
class OnboardingPlanReadyPage extends ConsumerWidget {
  const OnboardingPlanReadyPage({super.key, required this.plan});

  final NutritionPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final goal = ref.watch(onboardingControllerProvider).goal ?? NutritionGoal.loseFat;

    final totalCalories = plan.meals.fold(0, (sum, meal) => sum + meal.calories);
    final totalProtein = plan.meals.fold(0, (sum, meal) => sum + meal.proteinGrams);
    final preview = plan.meals.take(2).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space20,
            AppSpacing.space24,
            AppSpacing.space20,
            AppSpacing.space20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.onboardingPlanReadyTitle, style: AppTypography.display.copyWith(fontSize: 29, color: colors.textPrimary)),
              const SizedBox(height: 6),
              Text(
                l10n.onboardingPlanReadySubtitle(goalSubtitle(l10n, goal)),
                style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: 1,
                      centerValue: '$totalCalories',
                      centerLabel: l10n.onboardingPlanReadyCaloriesUnit,
                      size: 110,
                      strokeWidth: 10,
                    ),
                    const SizedBox(width: 20),
                    MacroStatTile(value: totalProtein, label: l10n.onboardingPlanReadyProteinLabel, color: colors.macroProtein),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final meal in preview) ...[
                MealCard(
                  overlineText: '${mealSlotLabel(l10n, meal.slotLabelKey)} · ${_timeLabel(meal)}',
                  title: meal.name,
                  detailText: l10n.planMealDetailPending(meal.calories, meal.proteinGrams),
                  isRegistered: false,
                  onTap: () {},
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              AppButton(
                label: l10n.onboardingPlanReadyStartButton,
                fullWidth: true,
                onPressed: () => context.go(RoutePaths.signUp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeLabel(PlannedMeal meal) {
    final hour = meal.scheduledHour.toString().padLeft(2, '0');
    final minute = meal.scheduledMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

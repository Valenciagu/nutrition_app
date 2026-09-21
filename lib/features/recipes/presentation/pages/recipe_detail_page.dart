import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/hatched_placeholder.dart';
import '../../../../core/widgets/macro_stat_tile.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_ingredient.dart';
import '../providers/recipe_providers.dart';

/// D3 · Detalle de receta (Fase 4). Anidada bajo el tab Plan
/// (`RoutePaths.recipeDetailPath`), no una tab propia. Ver
/// `documentation/design_screens_plan.md` y `documentation/recipes.md`.
///
/// Usa `mealRegistrationControllerProvider` de `features/plan` directo
/// (import cruzado deliberado, presentación-a-presentación) — mismo
/// precedente que `plan_page.dart` importando `onboarding_catalog.dart`: D3
/// opera sobre una comida que sigue siendo del dominio de Plan, no tendría
/// sentido duplicar ese controlador aquí.
///
/// Sin botón de favorito (♡ en el mock): no existe ningún concepto de
/// "favorito" en el backend/dominio hoy — agregar el botón sin persistencia
/// real sería una función que aparenta hacer algo y no hace nada,
/// exactamente lo que este proyecto evita (ver notas de alcance en
/// `documentation/recipes.md`).
class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.date, required this.mealId});

  final String date;
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final recipeAsync = ref.watch(recipeProvider((date: date, mealId: mealId)));

    ref.listen(mealRegistrationControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      } else if (previous is AsyncLoading && next is AsyncData && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: recipeAsync.when(
              loading: () => const AppStateBlock.loading(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.space20),
                child: AppStateBlock.error(
                  title: l10n.genericErrorTitle,
                  message: l10n.genericErrorMessage,
                  onAction: () => ref.invalidate(recipeProvider((date: date, mealId: mealId))),
                ),
              ),
              data: (recipe) => _RecipeDetailContent(recipe: recipe, date: date, mealId: mealId),
            ),
          ),
          Positioned(
            top: AppSpacing.space12,
            left: AppSpacing.space12,
            child: RoundIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }
}

class _RecipeDetailContent extends ConsumerWidget {
  const _RecipeDetailContent({required this.recipe, required this.date, required this.mealId});

  final Recipe recipe;
  final String date;
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isRegistering = ref.watch(mealRegistrationControllerProvider).isLoading;
    // Umbral de "alta en proteína" (≥30% de las calorías) — juicio de
    // presentación, no un hecho de dominio, así que vive aquí y no en
    // `Recipe`.
    final isHighProtein = recipe.calories > 0 && (recipe.proteinGrams * 4 / recipe.calories) >= 0.3;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: HatchedPlaceholder(),
                ),
                Transform.translate(
                  // Esquinas superiores redondeadas montadas sobre la foto
                  // (mock: `margin-top:-28px`) — `Transform.translate`, NUNCA
                  // un `margin` negativo (`Container.margin` lo rechaza con
                  // un assertion error, ver `documentation/bug_fixes_log.md`
                  // BUG-H01).
                  offset: const Offset(0, -AppRadius.sheet),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space20,
                      AppSpacing.space24,
                      AppSpacing.space20,
                      AppSpacing.space20,
                    ),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.sheet),
                        topRight: Radius.circular(AppRadius.sheet),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.name, style: AppTypography.titleL.copyWith(fontSize: 25, color: colors.textPrimary)),
                        const SizedBox(height: AppSpacing.space12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InfoTag(label: l10n.recipePrepTimeMinutes(recipe.prepTimeMinutes)),
                            _InfoTag(label: _difficultyLabel(l10n, recipe.difficulty)),
                            if (isHighProtein)
                              _InfoTag(
                                label: l10n.recipeInsightHighProtein,
                                background: colors.actionPrimarySurface,
                                foreground: colors.onActionPrimarySurface,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space20),
                        Row(
                          children: [
                            MacroStatTile(
                              value: recipe.calories,
                              label: l10n.recipeMacroKcalLabel,
                              color: colors.actionPrimary,
                            ),
                            MacroStatTile(
                              value: recipe.proteinGrams,
                              label: l10n.recipeMacroProteinLabel,
                              color: colors.macroProtein,
                            ),
                            MacroStatTile(
                              value: recipe.carbsGrams,
                              label: l10n.recipeMacroCarbsLabel,
                              color: colors.macroCarbs,
                            ),
                            MacroStatTile(
                              value: recipe.fatGrams,
                              label: l10n.recipeMacroFatLabel,
                              color: colors.macroFat,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space24),
                        Text(
                          l10n.recipeIngredientsSectionTitle(recipe.servings),
                          style: AppTypography.titleS.copyWith(fontSize: 15, color: colors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        for (final ingredient in recipe.ingredients) ...[
                          _IngredientRow(ingredient: ingredient),
                          const SizedBox(height: AppSpacing.space8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _RecipeFooter(
          isRegistering: isRegistering,
          onStartCooking: recipe.steps.isEmpty
              ? null
              : () => context.push(RoutePaths.cookingModePath(date, mealId), extra: recipe),
          onRegister: () => ref.read(mealRegistrationControllerProvider.notifier).setRegistered(mealId, registered: true),
        ),
      ],
    );
  }

  String _difficultyLabel(AppLocalizations l10n, RecipeDifficulty difficulty) {
    return switch (difficulty) {
      RecipeDifficulty.easy => l10n.recipeDifficultyEasy,
      RecipeDifficulty.medium => l10n.recipeDifficultyMedium,
      RecipeDifficulty.hard => l10n.recipeDifficultyHard,
    };
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient});

  final RecipeIngredient ingredient;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(ingredient.name, style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textPrimary)),
            ),
            Text(
              ingredient.quantity,
              style: AppTypography.bodyM.copyWith(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
        if (ingredient.substitutes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              l10n.recipeSubstitutesLabel(ingredient.substitutes.join(', ')),
              style: AppTypography.bodyM.copyWith(fontSize: 12, color: colors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, this.background, this.foreground});

  final String label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background ?? colors.surface,
        border: background == null ? Border.all(color: colors.border) : null,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: foreground ?? colors.textPrimary,
        ),
      ),
    );
  }
}

class _RecipeFooter extends StatelessWidget {
  const _RecipeFooter({required this.isRegistering, required this.onStartCooking, required this.onRegister});

  final bool isRegistering;
  final VoidCallback? onStartCooking;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space20,
        AppSpacing.space12,
        AppSpacing.space20,
        AppSpacing.space12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: l10n.recipeStartCookingCta,
              onPressed: isRegistering ? null : onStartCooking,
              fullWidth: true,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: AppButton(
              label: l10n.recipeRegisterCta,
              onPressed: isRegistering ? null : onRegister,
              variant: AppButtonVariant.secondary,
              isLoading: isRegistering,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}

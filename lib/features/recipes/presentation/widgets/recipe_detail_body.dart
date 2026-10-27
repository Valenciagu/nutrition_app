import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/macro_stat_tile.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_ingredient.dart';
import '../../../../core/widgets/food_photo.dart';
import '../dish_images.dart';

/// Cuerpo desplazable de D3 (foto, nombre, etiquetas, macros, ingredientes),
/// sin acciones. Extraído de `RecipeDetailPage` (Épica 7) al aparecer su
/// segundo consumidor: la receta sugerida desde una foto de ingredientes
/// (Épica 9), que no pertenece a ningún plan y por eso no puede usar el pie
/// de D3 ("Registrar" opera sobre una comida del plan). Cada página pone su
/// propio pie debajo.
class RecipeDetailBody extends StatelessWidget {
  const RecipeDetailBody({super.key, required this.recipe, this.trailing});

  final Recipe recipe;

  /// Contenido extra al final de la hoja (p. ej. "Te falta comprar").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    // Umbral de "alta en proteína" (≥30% de las calorías) — juicio de
    // presentación, no un hecho de dominio, así que vive aquí y no en
    // `Recipe`.
    final isHighProtein = recipe.calories > 0 && (recipe.proteinGrams * 4 / recipe.calories) >= 0.3;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 300, width: double.infinity, child: FoodPhoto(imageAsset: dishImageAsset(recipe.dishCategory))),
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
                      RecipeInfoTag(label: l10n.recipePrepTimeMinutes(recipe.prepTimeMinutes)),
                      RecipeInfoTag(label: recipeDifficultyLabel(l10n, recipe.difficulty)),
                      if (isHighProtein)
                        RecipeInfoTag(
                          label: l10n.recipeInsightHighProtein,
                          background: colors.actionPrimarySurface,
                          foreground: colors.onActionPrimarySurface,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space20),
                  Row(
                    children: [
                      MacroStatTile(value: recipe.calories, label: l10n.recipeMacroKcalLabel, color: colors.actionPrimary),
                      MacroStatTile(
                        value: recipe.proteinGrams,
                        label: l10n.recipeMacroProteinLabel,
                        color: colors.macroProtein,
                      ),
                      MacroStatTile(value: recipe.carbsGrams, label: l10n.recipeMacroCarbsLabel, color: colors.macroCarbs),
                      MacroStatTile(value: recipe.fatGrams, label: l10n.recipeMacroFatLabel, color: colors.macroFat),
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
                  if (trailing != null) ...[const SizedBox(height: AppSpacing.space16), trailing!],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// Etiqueta visible de [RecipeDifficulty] — la comparten D3 y la lista de
/// recetas sugeridas (Épica 9).
String recipeDifficultyLabel(AppLocalizations l10n, RecipeDifficulty difficulty) {
  return switch (difficulty) {
    RecipeDifficulty.easy => l10n.recipeDifficultyEasy,
    RecipeDifficulty.medium => l10n.recipeDifficultyMedium,
    RecipeDifficulty.hard => l10n.recipeDifficultyHard,
  };
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

/// Píldora de dato de una receta (tiempo, dificultad, "alta en proteína").
/// Pública porque la pantalla de ingredientes (Épica 9) la usa también para
/// listar lo que se detectó en la foto.
class RecipeInfoTag extends StatelessWidget {
  const RecipeInfoTag({super.key, required this.label, this.background, this.foreground});

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

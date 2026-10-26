import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../recipes/presentation/widgets/recipe_detail_body.dart';
import '../../domain/entities/ingredient_suggestions.dart';

/// Detalle de una receta sugerida desde una foto de ingredientes (Épica 9).
/// Mismo cuerpo que D3 (`RecipeDetailBody`) más "Te falta conseguir". El pie
/// solo tiene "Empezar a cocinar": "Registrar" de D3 marca una comida del
/// plan, y esta receta no pertenece a ninguno.
class SuggestedRecipePage extends StatelessWidget {
  const SuggestedRecipePage({super.key, required this.suggestion});

  final SuggestedRecipe suggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final recipe = suggestion.recipe;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: RecipeDetailBody(
                    recipe: recipe,
                    trailing: suggestion.missingIngredients.isEmpty
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.ingredientsMissingSectionTitle,
                                style: AppTypography.titleS.copyWith(fontSize: 15, color: colors.textPrimary),
                              ),
                              const SizedBox(height: AppSpacing.space12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [for (final item in suggestion.missingIngredients) RecipeInfoTag(label: item)],
                              ),
                            ],
                          ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.space20,
                    AppSpacing.space12,
                    AppSpacing.space20,
                    AppSpacing.space12 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
                  child: AppButton(
                    label: l10n.recipeStartCookingCta,
                    fullWidth: true,
                    onPressed: recipe.steps.isEmpty
                        ? null
                        : () => context.push(RoutePaths.ingredientRecipeCooking, extra: recipe),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.space12 + MediaQuery.of(context).padding.top,
            left: AppSpacing.space12,
            child: RoundIconButton(icon: AppIcons.back, onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }
}

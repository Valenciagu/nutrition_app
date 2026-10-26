import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/route_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/meal_card.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../recipes/presentation/widgets/recipe_detail_body.dart';
import '../../domain/entities/ingredient_suggestions.dart';
import '../providers/ingredient_analysis_providers.dart';

/// Épica 9 — resultado de "Tengo ingredientes". Misma estructura que
/// `FoodAnalysisPage` (Épica 8): la foto arriba y una hoja montada encima con
/// el estado (cargando / error / resultado). La foto ya viene tomada
/// (`imageBytes`, desde la hoja de cámara) y el análisis arranca solo.
///
/// El canvas de Fase 6 (Ingredientes) no se pudo leer al construir esto
/// (sin acceso a Claude Design en esa sesión): se arma solo con componentes
/// existentes — `MealCard` para cada receta, `RecipeInfoTag` para los
/// ingredientes detectados. Revisar contra el canvas cuando haya acceso.
class IngredientAnalysisPage extends ConsumerStatefulWidget {
  const IngredientAnalysisPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  ConsumerState<IngredientAnalysisPage> createState() => _IngredientAnalysisPageState();
}

class _IngredientAnalysisPageState extends ConsumerState<IngredientAnalysisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ingredientAnalysisControllerProvider.notifier).analyze(widget.imageBytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final resultAsync = ref.watch(ingredientAnalysisControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 260, width: double.infinity, child: Image.memory(widget.imageBytes, fit: BoxFit.cover)),
                  Transform.translate(
                    // Sheet sobre la foto vía `Transform.translate`, nunca un
                    // `margin` negativo (BUG-H01).
                    offset: const Offset(0, -AppRadius.sheet),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 260 + AppRadius.sheet),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.sheet),
                          topRight: Radius.circular(AppRadius.sheet),
                        ),
                      ),
                      child: resultAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.space24),
                          child: AppStateBlock.loading(),
                        ),
                        error: (error, _) {
                          debugPrint(
                            'suggestRecipesFromIngredients failed: $error (cause: ${error is Failure ? error.cause : null})',
                          );
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.space20),
                            child: AppStateBlock.error(
                              title: l10n.genericErrorTitle,
                              message: l10n.messageForError(error),
                              onAction: () =>
                                  ref.read(ingredientAnalysisControllerProvider.notifier).analyze(widget.imageBytes),
                            ),
                          );
                        },
                        data: (result) {
                          if (result == null) return const SizedBox.shrink();
                          if (!result.isIngredientPhoto) {
                            return Padding(
                              padding: const EdgeInsets.all(AppSpacing.space20),
                              child: AppStateBlock.empty(
                                title: l10n.ingredientsNotDetectedTitle,
                                message: l10n.ingredientsNotDetectedMessage,
                                actionLabel: l10n.ingredientsCloseAction,
                                onAction: () => context.pop(),
                              ),
                            );
                          }
                          return _Suggestions(result: result);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.space12 + MediaQuery.of(context).padding.top,
            left: AppSpacing.space12,
            child: RoundIconButton(icon: AppIcons.close, onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.result});

  final IngredientSuggestions result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space24, AppSpacing.space20, AppSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l10n.ingredientsDetectedTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final ingredient in result.detectedIngredients) RecipeInfoTag(label: ingredient)],
          ),
          const SizedBox(height: AppSpacing.space24),
          _SectionLabel(l10n.ingredientsRecipesTitle),
          const SizedBox(height: 10),
          for (final suggestion in result.recipes) ...[
            MealCard(
              overlineText:
                  '${l10n.recipePrepTimeMinutes(suggestion.recipe.prepTimeMinutes)} · ${recipeDifficultyLabel(l10n, suggestion.recipe.difficulty)}',
              title: suggestion.recipe.name,
              detailText:
                  '${l10n.planMealDetailPending(suggestion.recipe.calories, suggestion.recipe.proteinGrams)} · ${suggestion.missingIngredients.isEmpty ? l10n.ingredientsHaveEverything : l10n.ingredientsMissingCount(suggestion.missingIngredients.length)}',
              isRegistered: false,
              onTap: () => context.push(RoutePaths.ingredientRecipe, extra: suggestion),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: AppSpacing.space8),
          // La IA nunca habla sin marca de "esto es una sugerencia" (regla de
          // diseño "la IA tiene voz, no control", design_system.md).
          Text(l10n.ingredientsAiNote, style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textSecondary)),
        ],
      ),
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

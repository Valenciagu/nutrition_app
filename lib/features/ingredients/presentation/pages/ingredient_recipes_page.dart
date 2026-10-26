import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/route_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/hatched_placeholder.dart';
import '../../../grocery_list/presentation/providers/grocery_list_providers.dart';
import '../../domain/entities/ingredient_suggestions.dart';
import '../providers/ingredient_analysis_providers.dart';

/// F2 · Recetas con lo que tienes (Fase 6). Pide las recetas al entrar, con
/// los ingredientes confirmados en F1. Cada tarjeta lleva un badge ("Tienes
/// todo" / "Te falta N") y, si falta algo, "Añadir … a la lista de compra"
/// en un toque. "Pedir más ideas a la IA" trae otras recetas distintas.
///
/// Jerarquía del canvas: las dos primeras recetas en tarjeta grande con
/// foto, el resto en fila compacta. Sin foto real de receta (ninguna
/// función las genera), la zona de foto es el placeholder rayado — igual
/// que D3.
class IngredientRecipesPage extends ConsumerStatefulWidget {
  const IngredientRecipesPage({super.key});

  @override
  ConsumerState<IngredientRecipesPage> createState() => _IngredientRecipesPageState();
}

class _IngredientRecipesPageState extends ConsumerState<IngredientRecipesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ingredientRecipesControllerProvider.notifier).suggest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final recipesAsync = ref.watch(ingredientRecipesControllerProvider);

    ref.listen(addToGroceryListControllerProvider, (previous, next) {
      if (previous is! AsyncLoading) return;
      final message = next.hasError ? l10n.genericErrorMessage : l10n.ingredientsAddedToList;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });

    final recipes = recipesAsync.valueOrNull?.recipes;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space16, AppSpacing.space20, AppSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkResponse(
                    onTap: () => context.pop(),
                    radius: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(AppIcons.back, size: 20, color: colors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (recipes != null)
                    Expanded(
                      child: Text(
                        l10n.ingredientsRecipesCount(recipes.length),
                        style: AppTypography.display.copyWith(fontSize: 22, color: colors.textPrimary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
              Expanded(
                child: recipesAsync.when(
                  loading: () => const AppStateBlock.loading(),
                  error: (error, _) {
                    debugPrint(
                      'suggestRecipesFromIngredients failed: $error (cause: ${error is Failure ? error.cause : null})',
                    );
                    return AppStateBlock.error(
                      title: l10n.genericErrorTitle,
                      message: l10n.messageForError(error),
                      onAction: () => ref.read(ingredientRecipesControllerProvider.notifier).suggest(),
                    );
                  },
                  data: (result) => result == null
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          itemCount: result.recipes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space16),
                          itemBuilder: (context, index) {
                            final suggestion = result.recipes[index];
                            void open() => context.push(RoutePaths.ingredientRecipe, extra: suggestion);
                            return index < 2
                                ? _LargeRecipeCard(suggestion: suggestion, onTap: open)
                                : _CompactRecipeCard(suggestion: suggestion, onTap: open);
                          },
                        ),
                ),
              ),
              if (recipes != null) ...[
                const SizedBox(height: AppSpacing.space16),
                AppButton(
                  label: l10n.ingredientsMoreIdeasCta,
                  variant: AppButtonVariant.aiAction,
                  fullWidth: true,
                  onPressed: () => ref.read(ingredientRecipesControllerProvider.notifier).moreIdeas(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeRecipeCard extends ConsumerWidget {
  const _LargeRecipeCard({required this.suggestion, required this.onTap});

  final SuggestedRecipe suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final recipe = suggestion.recipe;
    final missing = suggestion.missingIngredients;
    final isAdding = ref.watch(addToGroceryListControllerProvider).isLoading;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const HatchedPlaceholder(),
                  Positioned(top: 10, left: 10, child: _AvailabilityBadge(missingCount: missing.length)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: AppTypography.bodyL.copyWith(fontSize: 16.5, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                  const SizedBox(height: 5),
                  Text(
                    l10n.ingredientsRecipeMeta(recipe.calories, recipe.proteinGrams, recipe.prepTimeMinutes),
                    style: AppTypography.bodyM.copyWith(fontSize: 12.5, fontWeight: FontWeight.w500, color: colors.textSecondary),
                  ),
                  if (missing.isNotEmpty)
                    InkWell(
                      onTap: isAdding ? null : () => ref.read(addToGroceryListControllerProvider.notifier).add(missing),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 7, bottom: 2),
                        child: Text(
                          missing.length == 1
                              ? l10n.ingredientsAddOneToList(missing.single.toLowerCase())
                              : l10n.ingredientsAddManyToList(missing.length),
                          style: AppTypography.label.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: colors.actionPrimary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactRecipeCard extends StatelessWidget {
  const _CompactRecipeCard({required this.suggestion, required this.onTap});

  final SuggestedRecipe suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final recipe = suggestion.recipe;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              SizedBox.square(dimension: 66, child: HatchedPlaceholder(borderRadius: BorderRadius.circular(13))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name, style: AppTypography.bodyL.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      l10n.planMealDetailPending(recipe.calories, recipe.proteinGrams),
                      style: AppTypography.bodyM.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Tienes todo" (verde) / "Te falta N" (ámbar). El texto dice lo mismo que
/// el color — nunca solo color (Fase 12 · accesibilidad).
class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.missingCount});

  final int missingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final hasEverything = missingCount == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: hasEverything ? colors.actionPrimary : colors.warning,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        hasEverything ? l10n.ingredientsHaveEverything : l10n.ingredientsMissingCount(missingCount),
        style: AppTypography.label.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: colors.onActionPrimary),
      ),
    );
  }
}

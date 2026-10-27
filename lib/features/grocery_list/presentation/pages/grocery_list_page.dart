import '../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../onboarding/presentation/onboarding_catalog.dart';
import '../../domain/entities/grocery_item.dart';
import '../providers/grocery_list_providers.dart';
import '../../../../core/widgets/motion/app_entrance.dart';

/// Lista de compra semanal (Épica 10). Sin mock propio en el canvas de
/// diseño (Fase 4 solo define la fila "Generar lista de compra" en D1, que
/// navega aquí) — construida con los tokens ya sincronizados del sistema de
/// diseño, no una pantalla inventada desde cero.
class GroceryListPage extends ConsumerWidget {
  const GroceryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final dataAsync = ref.watch(groceryListProvider);

    void showErrorOnFailure(AsyncValue<void>? previous, AsyncValue<void> next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      }
    }

    ref.listen(groceryItemCheckControllerProvider, showErrorOnFailure);
    ref.listen(removeGroceryItemControllerProvider, showErrorOnFailure);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space12, AppSpacing.space8, AppSpacing.space20, AppSpacing.space8),
              child: Row(
                children: [
                  RoundIconButton(icon: AppIcons.back, onTap: () => context.pop()),
                  const SizedBox(width: AppSpacing.space12),
                  Text(l10n.groceryListTitle, style: AppTypography.titleL.copyWith(fontSize: 22, color: colors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: dataAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.space20), child: AppStateBlock.loading()),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.space20),
                  child: AppStateBlock.error(
                    title: l10n.genericErrorTitle,
                    message: l10n.genericErrorMessage,
                    onAction: () => ref.invalidate(groceryListProvider),
                  ),
                ),
                data: (data) => data.items.isEmpty && data.mealsWithoutRecipe.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.space20),
                        child: AppStateBlock.empty(title: l10n.groceryEmptyTitle, message: l10n.groceryEmptyMessage),
                      )
                    : _GroceryListContent(data: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroceryListContent extends ConsumerWidget {
  const _GroceryListContent({required this.data});

  final GroceryListData data;

  static const _categoryOrder = [
    GroceryCategory.protein,
    GroceryCategory.carbs,
    GroceryCategory.fruit,
    GroceryCategory.vegetable,
    GroceryCategory.dairy,
    GroceryCategory.other,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;

    final byCategory = <GroceryCategory, List<GroceryItem>>{
      for (final category in _categoryOrder) category: data.items.where((i) => i.category == category).toList(),
    };

    // M04 (catálogo "Motion patterns"): encabezados y filas entran en orden;
    // el scope evita que se repita al volver a hacer scroll hacia arriba.
    var entranceIndex = 0;
    return AppEntranceScope(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.space20, 0, AppSpacing.space20, AppSpacing.space24),
        children: [
          for (final category in _categoryOrder)
            if (byCategory[category]!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.space16, bottom: AppSpacing.space8),
                child: Text(
                  _categoryLabel(l10n, category),
                  style: AppTypography.label.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary),
                ),
              ).appListEntrance(entranceIndex++),
              for (final item in byCategory[category]!) ...[
                _GroceryItemRow(item: item).appListEntrance(entranceIndex++),
                const SizedBox(height: 8),
              ],
            ],
          if (data.mealsWithoutRecipe.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space16, bottom: AppSpacing.space4),
              child: Text(
                l10n.groceryMissingRecipesTitle,
                style: AppTypography.label.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700, color: colors.textSecondary),
              ),
            ),
            Text(
              l10n.groceryMissingRecipesHint,
              style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space8),
            for (final meal in data.mealsWithoutRecipe) ...[
              _MissingRecipeRow(meal: meal),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, GroceryCategory category) {
    return switch (category) {
      GroceryCategory.protein => l10n.groceryCategoryProtein,
      GroceryCategory.carbs => l10n.groceryCategoryCarbs,
      GroceryCategory.fruit => l10n.groceryCategoryFruit,
      GroceryCategory.vegetable => l10n.groceryCategoryVegetable,
      GroceryCategory.dairy => l10n.groceryCategoryDairy,
      GroceryCategory.other => l10n.groceryCategoryOther,
    };
  }
}

class _GroceryItemRow extends ConsumerWidget {
  const _GroceryItemRow({required this.item});

  final GroceryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).languageCode;
    final sourcesLabel = item.sources
        .map((s) => l10n.grocerySourceLabel(s.quantity, mealSlotLabel(l10n, s.slotLabelKey), DateFormat.E(locale).format(s.date)))
        .join(' · ');

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => ref.read(groceryItemCheckControllerProvider.notifier).toggle(item),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: item.checked ? colors.actionPrimary : null,
                  shape: BoxShape.circle,
                  border: item.checked ? null : Border.all(color: colors.border, width: 1.5),
                ),
                alignment: Alignment.center,
                child: item.checked ? Icon(AppIcons.check, size: 14, color: colors.onActionPrimary) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.bodyL.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: item.checked ? colors.textSecondary : colors.textPrimary,
                        decoration: item.checked ? TextDecoration.lineThrough : null,
                        decorationColor: colors.textDisabled,
                      ),
                    ),
                    // Un ítem añadido a mano (Épica 9) no viene de ninguna
                    // receta del plan: sin línea de origen.
                    if (sourcesLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(sourcesLabel, style: AppTypography.bodyM.copyWith(fontSize: 12, color: colors.textSecondary)),
                    ],
                  ],
                ),
              ),
              // Solo lo añadido a mano se puede quitar; lo que pide una
              // receta del plan sale de la lista al registrar esa comida.
              if (item.isRemovable)
                Semantics(
                  button: true,
                  label: l10n.groceryRemoveItemSemantics(item.name),
                  excludeSemantics: true,
                  child: InkResponse(
                    onTap: () => ref.read(removeGroceryItemControllerProvider.notifier).remove(item),
                    radius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space8),
                      child: Icon(AppIcons.close, size: 18, color: colors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingRecipeRow extends StatelessWidget {
  const _MissingRecipeRow({required this.meal});

  final MissingRecipeMeal meal;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RoutePaths.recipeDetailPath(meal.date, meal.mealId)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(
            children: [
              Expanded(
                child: Text(meal.name, style: AppTypography.bodyM.copyWith(fontSize: 14, color: colors.textPrimary)),
              ),
              Icon(AppIcons.chevronRight, color: colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/selectable_chip.dart';
import '../../domain/entities/meal_alternative.dart';
import '../../domain/entities/planned_meal.dart';
import '../providers/plan_providers.dart';

/// D4 · Reemplazar comida (sheet) — uno de los casos de uso explícitamente
/// aprobados de `showAppBottomSheet`. Pide 3 alternativas al abrir; los
/// chips de filtro vuelven a pedir con un `filterHint` distinto (Épica 6,
/// PLAN-006 — ver `documentation/plan.md`).
Future<void> showReplaceMealSheet(BuildContext context, PlannedMeal meal) {
  return showAppBottomSheet<void>(
    context,
    title: context.l10n.planReplaceMealTitle,
    height: AppBottomSheetHeight.half,
    builder: (sheetContext) => _ReplaceMealSheetContent(meal: meal),
  );
}

class _ReplaceMealSheetContent extends ConsumerStatefulWidget {
  const _ReplaceMealSheetContent({required this.meal});

  final PlannedMeal meal;

  @override
  ConsumerState<_ReplaceMealSheetContent> createState() => _ReplaceMealSheetContentState();
}

class _ReplaceMealSheetContentState extends ConsumerState<_ReplaceMealSheetContent> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mealAlternativesControllerProvider.notifier).fetchAlternatives(widget.meal.id));
  }

  @override
  void dispose() {
    ref.read(mealAlternativesControllerProvider.notifier).reset();
    super.dispose();
  }

  void _requestWithFilter(String filterHint) {
    setState(() => _selectedIndex = 0);
    ref.read(mealAlternativesControllerProvider.notifier).fetchAlternatives(widget.meal.id, filterHint: filterHint);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final alternativesAsync = ref.watch(mealAlternativesControllerProvider);
    final isConfirming = alternativesAsync.isLoading && alternativesAsync.hasValue;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.planReplaceMealSubtitle, style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary)),
          const SizedBox(height: AppSpacing.space16),
          alternativesAsync.when(
            loading: () => const AppStateBlock.loading(),
            error: (error, _) => AppStateBlock.error(
              title: l10n.genericErrorTitle,
              message: l10n.genericErrorMessage,
              onAction: () => ref.read(mealAlternativesControllerProvider.notifier).fetchAlternatives(widget.meal.id),
            ),
            data: (alternatives) {
              final items = alternatives ?? const <MealAlternative>[];
              if (items.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    _AlternativeCard(
                      alternative: items[i],
                      selected: i == _selectedIndex,
                      onTap: () => setState(() => _selectedIndex = i),
                    ),
                    if (i != items.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: AppSpacing.space12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      SelectableChip(label: l10n.planFilterFaster, selected: false, onTap: () => _requestWithFilter(l10n.planFilterFaster)),
                      SelectableChip(label: l10n.planFilterLighter, selected: false, onTap: () => _requestWithFilter(l10n.planFilterLighter)),
                      SelectableChip(label: l10n.planFilterAskAi, selected: false, onTap: () => _requestWithFilter(l10n.planFilterAskAi)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space16),
                  AppButton(
                    label: l10n.planReplaceMealCta,
                    fullWidth: true,
                    isLoading: isConfirming,
                    onPressed: isConfirming
                        ? null
                        : () async {
                            await ref
                                .read(mealAlternativesControllerProvider.notifier)
                                .confirmReplacement(widget.meal.id, _selectedIndex);
                            if (context.mounted) Navigator.of(context).pop();
                          },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.alternative, required this.selected, required this.onTap});

  final MealAlternative alternative;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? colors.actionPrimarySurface : null,
            border: Border.all(color: selected ? colors.actionPrimary : colors.border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alternative.name,
                      style: AppTypography.bodyL.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? colors.onActionPrimarySurface : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.planMealDetailPending(alternative.calories, alternative.proteinGrams),
                      style: AppTypography.bodyM.copyWith(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: colors.actionPrimary, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(Icons.check, size: 13, color: colors.onActionPrimary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

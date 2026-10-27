import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/meal_card.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../domain/entities/extra_meal.dart';
import '../providers/extra_meal_providers.dart';

/// Comidas extra de [date] en D1, debajo de las del plan (LOG-101). Ya se
/// comieron, así que usan el tratamiento "registrada" de `MealCard`. Tocar
/// una abre la hoja de porción/eliminar. Sin nada que mostrar (o mientras
/// carga) no ocupa espacio: D1 se ve igual que antes.
class ExtraMealsSection extends ConsumerWidget {
  const ExtraMealsSection({super.key, required this.date});

  /// YYYY-MM-DD.
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final meals = ref.watch(extraMealsForDateProvider(date)).valueOrNull ?? const <ExtraMeal>[];
    if (meals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space8, bottom: 10),
          child: Text(
            l10n.extraMealsSectionTitle.toUpperCase(),
            style: AppTypography.label.copyWith(fontSize: 11.5, letterSpacing: 1, color: colors.textSecondary),
          ),
        ),
        for (final meal in meals) ...[
          MealCard(
            overlineText: meal.portion == 1
                ? l10n.extraMealsSectionTitle
                : l10n.extraMealOverlineWithPortion(formatPortion(context, meal.portion)),
            title: meal.name,
            detailText: l10n.planMealDetailPending(meal.calories, meal.proteinGrams),
            isRegistered: true,
            onTap: () => showExtraMealSheet(context, meal),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// "1,5" / "1.5" según el idioma — nunca un decimal armado a mano.
String formatPortion(BuildContext context, double portion) {
  return NumberFormat('0.##', Localizations.localeOf(context).toLanguageTag()).format(portion);
}

/// Ajustar la porción (uso aprobado de la hoja: "adjusting a quantity") o
/// eliminar, con confirmación en diálogo centrado (regla de `showAppBottomSheet`).
Future<void> showExtraMealSheet(BuildContext context, ExtraMeal meal) {
  return showAppBottomSheet<void>(
    context,
    title: meal.name,
    builder: (sheetContext) => _ExtraMealSheet(meal: meal, hostContext: context),
  );
}

class _ExtraMealSheet extends ConsumerStatefulWidget {
  const _ExtraMealSheet({required this.meal, required this.hostContext});

  final ExtraMeal meal;

  /// El contexto de la pantalla: los snackbars sobreviven al cierre de la hoja.
  final BuildContext hostContext;

  @override
  ConsumerState<_ExtraMealSheet> createState() => _ExtraMealSheetState();
}

class _ExtraMealSheetState extends ConsumerState<_ExtraMealSheet> {
  static const _step = 0.25;
  static const _min = 0.25;
  static const _max = 5.0;

  late double _portion = widget.meal.portion;

  ExtraMeal get _preview => ExtraMeal(
        id: widget.meal.id,
        date: widget.meal.date,
        name: widget.meal.name,
        source: widget.meal.source,
        baseCalories: widget.meal.baseCalories,
        baseProteinGrams: widget.meal.baseProteinGrams,
        baseCarbsGrams: widget.meal.baseCarbsGrams,
        baseFatGrams: widget.meal.baseFatGrams,
        portion: _portion,
      );

  void _showResult(bool ok) {
    final host = widget.hostContext;
    if (!host.mounted) return;
    if (!ok) {
      final error = ref.read(extraMealControllerProvider).error;
      ScaffoldMessenger.of(host).showSnackBar(
        SnackBar(content: Text(error == null ? host.l10n.genericErrorMessage : host.l10n.messageForError(error))),
      );
    }
  }

  Future<void> _save() async {
    if (_portion == widget.meal.portion) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await ref.read(extraMealControllerProvider.notifier).setPortion(widget.meal, _portion);
    if (mounted) Navigator.of(context).pop();
    _showResult(ok);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmationDialog(
      context,
      title: l10n.extraMealDeleteConfirmTitle,
      message: l10n.extraMealDeleteConfirmMessage,
      confirmLabel: l10n.extraMealDeleteAction,
      cancelLabel: l10n.cancelButtonLabel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    final ok = await ref.read(extraMealControllerProvider.notifier).delete(widget.meal);
    if (mounted) Navigator.of(context).pop();
    _showResult(ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isBusy = ref.watch(extraMealControllerProvider).isLoading;
    final preview = _preview;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planMealDetailPending(preview.calories, preview.proteinGrams),
          style: AppTypography.bodyL.copyWith(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textPrimary),
        ),
        if (widget.meal.allergenWarning) ...[
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              Icon(AppIcons.warning, size: 16, color: colors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.extraMealAllergenWarning,
                  style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.space16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.extraMealPortionLabel, style: AppTypography.label.copyWith(fontSize: 13, color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(l10n.extraMealPortionHint, style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.space12),
            Semantics(
              label: l10n.extraMealPortionDecreaseSemantics,
              button: true,
              excludeSemantics: true,
              child: RoundIconButton(
                icon: AppIcons.minus,
                onTap: () => setState(() => _portion = (_portion - _step).clamp(_min, _max)),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                l10n.extraMealPortionValue(formatPortion(context, _portion)),
                textAlign: TextAlign.center,
                style: AppTypography.titleM.copyWith(fontSize: 16, color: colors.textPrimary),
              ),
            ),
            Semantics(
              label: l10n.extraMealPortionIncreaseSemantics,
              button: true,
              excludeSemantics: true,
              child: RoundIconButton(
                icon: AppIcons.plus,
                onTap: () => setState(() => _portion = (_portion + _step).clamp(_min, _max)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space20),
        AppButton(label: l10n.extraMealSaveAction, fullWidth: true, isLoading: isBusy, onPressed: isBusy ? null : _save),
        const SizedBox(height: AppSpacing.space8),
        AppButton(
          label: l10n.extraMealDeleteAction,
          variant: AppButtonVariant.text,
          fullWidth: true,
          accentColorOverride: colors.error,
          onPressed: isBusy ? null : _delete,
        ),
      ],
    );
  }
}

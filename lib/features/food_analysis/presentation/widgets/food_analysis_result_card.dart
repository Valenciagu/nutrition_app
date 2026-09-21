import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/macro_stat_tile.dart';
import '../../domain/entities/food_analysis_result.dart';

/// Muestra el resultado de `analyzeFoodPhoto` (Épica 8). Dos formas, según
/// [FoodAnalysisResult.isFoodPhoto]:
/// - `false`: mensaje "no reconocimos comida", sin macros (el backend
///   deliberadamente no inventó una estimación).
/// - `true`: nombre + porción + macros + nota de incertidumbre SIEMPRE
///   visible (Instrucciones.md §6 — nunca presentar esto como medición
///   exacta) + advertencia de alérgeno si aplica.
///
/// Vive en `features/food_analysis/`, no en `core/widgets/`: un solo
/// consumidor real hoy (la pantalla de análisis), sin ficha propia en el
/// sistema de diseño base — mismo criterio que `WeekPlanView`/`DayStrip`.
class FoodAnalysisResultCard extends StatelessWidget {
  const FoodAnalysisResultCard({super.key, required this.result});

  final FoodAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    if (!result.isFoodPhoto) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.foodAnalysisNotFoodTitle,
              style: AppTypography.titleS.copyWith(fontSize: 16, color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              l10n.foodAnalysisNotFoodMessage,
              style: AppTypography.bodyM.copyWith(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.foodName ?? '',
            style: AppTypography.titleL.copyWith(fontSize: 22, color: colors.textPrimary),
          ),
          if (result.portionDescription != null) ...[
            const SizedBox(height: 2),
            Text(
              result.portionDescription!,
              style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary),
            ),
          ],
          if (result.confidence != null) ...[
            const SizedBox(height: AppSpacing.space8),
            _ConfidenceBadge(confidence: result.confidence!),
          ],
          const SizedBox(height: AppSpacing.space20),
          Row(
            children: [
              MacroStatTile(value: result.calories ?? 0, label: l10n.recipeMacroKcalLabel, color: colors.actionPrimary),
              MacroStatTile(value: result.proteinGrams ?? 0, label: l10n.recipeMacroProteinLabel, color: colors.macroProtein),
              MacroStatTile(value: result.carbsGrams ?? 0, label: l10n.recipeMacroCarbsLabel, color: colors.macroCarbs),
              MacroStatTile(value: result.fatGrams ?? 0, label: l10n.recipeMacroFatLabel, color: colors.macroFat),
            ],
          ),
          if (result.allergenWarning) ...[
            const SizedBox(height: AppSpacing.space16),
            _Banner(text: l10n.foodAnalysisAllergenWarning, background: colors.errorSurface, foreground: colors.error),
          ],
          if (result.uncertaintyNote != null) ...[
            const SizedBox(height: AppSpacing.space12),
            _Banner(text: result.uncertaintyNote!, background: colors.surface, foreground: colors.textSecondary),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final FoodAnalysisConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final label = switch (confidence) {
      FoodAnalysisConfidence.low => l10n.foodAnalysisConfidenceLow,
      FoodAnalysisConfidence.medium => l10n.foodAnalysisConfidenceMedium,
      FoodAnalysisConfidence.high => l10n.foodAnalysisConfidenceHigh,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(label, style: AppTypography.label.copyWith(fontSize: 11.5, color: colors.textSecondary)),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.background, required this.foreground});

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Text(text, style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: foreground)),
    );
  }
}

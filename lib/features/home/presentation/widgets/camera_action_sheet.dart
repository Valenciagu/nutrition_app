import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';

/// C5 · Acción central (Fase 3 · Home). El botón de cámara no abre la
/// cámara directamente — ofrece 3 caminos, cada uno hacia una épica que
/// todavía no existe (Analizar/Ingredientes → Épica 8/9, Registrar sin foto
/// → Épica 6). Por ahora cada opción confirma la intención con un snackbar
/// en vez de fallar en silencio (la misma clase de bug que "Empezar" tenía
/// en Welcome antes de la Épica 3 — un tap sin ningún feedback).
Future<void> showCameraActionSheet(BuildContext context) {
  final l10n = context.l10n;
  final colors = context.colors;

  void handleOption(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoonSnackbarMessage)));
  }

  return showAppBottomSheet(
    context,
    title: l10n.cameraSheetTitle,
    builder: (sheetContext) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetOption(
            iconBackgroundColor: colors.actionPrimarySurface,
            title: l10n.cameraSheetAnalyzeMealTitle,
            subtitle: l10n.cameraSheetAnalyzeMealSubtitle,
            onTap: () => handleOption(sheetContext),
          ),
          const SizedBox(height: 10),
          _SheetOption(
            iconBackgroundColor: colors.actionPrimarySurface,
            title: l10n.cameraSheetIngredientsTitle,
            subtitle: l10n.cameraSheetIngredientsSubtitle,
            onTap: () => handleOption(sheetContext),
          ),
          const SizedBox(height: 10),
          _SheetOption(
            iconBackgroundColor: colors.background,
            title: l10n.cameraSheetLogManualTitle,
            subtitle: l10n.cameraSheetLogManualSubtitle,
            onTap: () => handleOption(sheetContext),
          ),
          const SizedBox(height: AppSpacing.space16),
          AppButton(
            label: l10n.cancelButtonLabel,
            variant: AppButtonVariant.neutral,
            fullWidth: true,
            onPressed: () => Navigator.of(sheetContext).pop(),
          ),
        ],
      );
    },
  );
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: iconBackgroundColor, borderRadius: BorderRadius.circular(13))),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyL.copyWith(fontSize: 15.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textSecondary)),
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

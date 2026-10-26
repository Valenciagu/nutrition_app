import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';

/// Pide una foto (cámara o galería) y abre [route] con sus bytes por
/// `extra`. Lo comparten "Analizar mi comida" (Épica 8) y "Tengo
/// ingredientes" (Épica 9), desde esta hoja o directo desde Home.
///
/// Las dos exigen subir a Storage y llamar a una Cloud Function
/// autenticada (Instrucciones.md §70) — sin camino de invitado, mismo
/// criterio que Plan (Épica 6). Se revisa la sesión ANTES de abrir la
/// cámara/galería: pedirle una foto a un invitado para recién ahí decirle
/// que necesita una cuenta sería peor UX que no pedírsela.
Future<void> pickPhotoAndOpen(BuildContext context, WidgetRef ref, {required String route, required String title}) async {
  final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) {
    if (context.mounted) context.go(RoutePaths.signUp);
    return;
  }

  final source = await _showImageSourceSheet(context, title);
  if (source == null || !context.mounted) return;

  final picked = await ImagePicker().pickImage(
    source: source,
    // Compresión del lado del cliente (Instrucciones.md §68) — la
    // validación real de tamaño/tipo la hace `storage.rules` server-side,
    // esto es solo para no subir una foto de cámara sin comprimir.
    imageQuality: 70,
    maxWidth: 1600,
  );
  if (picked == null || !context.mounted) return;

  final bytes = await picked.readAsBytes();
  if (context.mounted) context.push(route, extra: bytes);
}

Future<void> startIngredientAnalysis(BuildContext context, WidgetRef ref) {
  return pickPhotoAndOpen(
    context,
    ref,
    route: RoutePaths.ingredientAnalysis,
    title: context.l10n.cameraSheetIngredientsTitle,
  );
}

/// C5 · Acción central (Fase 3 · Home). "Analizar mi comida" (Épica 8) y
/// "Tengo ingredientes" (Épica 9) abren la cámara/galería; "Registrar sin
/// foto" (sin épica dueña todavía) sigue confirmando la intención con un
/// snackbar.
Future<void> showCameraActionSheet(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final colors = context.colors;

  void handleComingSoon(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoonSnackbarMessage)));
  }

  void handleAnalyzeMeal(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    pickPhotoAndOpen(context, ref, route: RoutePaths.foodAnalysis, title: l10n.cameraSheetAnalyzeMealTitle);
  }

  void handleIngredients(BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    startIngredientAnalysis(context, ref);
  }

  return showAppBottomSheet(
    context,
    title: l10n.cameraSheetTitle,
    builder: (sheetContext) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetOption(
            svgIcon: AppAssets.iconFoodScanner,
            iconBackgroundColor: colors.actionPrimarySurface,
            title: l10n.cameraSheetAnalyzeMealTitle,
            subtitle: l10n.cameraSheetAnalyzeMealSubtitle,
            onTap: () => handleAnalyzeMeal(sheetContext),
          ),
          const SizedBox(height: 10),
          _SheetOption(
            svgIcon: AppAssets.iconIngredientsPhoto,
            iconBackgroundColor: colors.actionPrimarySurface,
            title: l10n.cameraSheetIngredientsTitle,
            subtitle: l10n.cameraSheetIngredientsSubtitle,
            onTap: () => handleIngredients(sheetContext),
          ),
          const SizedBox(height: 10),
          _SheetOption(
            icon: AppIcons.manualLog,
            iconBackgroundColor: colors.background,
            title: l10n.cameraSheetLogManualTitle,
            subtitle: l10n.cameraSheetLogManualSubtitle,
            onTap: () => handleComingSoon(sheetContext),
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

/// "Tomar foto" / "Elegir de la galería" (Instrucciones.md §6: el usuario
/// debe poder "tomar O subir" una foto de comida) — una segunda hoja, en vez
/// de forzar la elección dentro de la primera, para no complicar la opción
/// que no la necesita.
Future<ImageSource?> _showImageSourceSheet(BuildContext context, String title) {
  final l10n = context.l10n;
  final colors = context.colors;

  return showAppBottomSheet<ImageSource>(
    context,
    title: title,
    builder: (sheetContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QuickActionTile(
            icon: AppIcons.camera,
            title: l10n.cameraSourceCameraOption,
            iconBackgroundColor: colors.actionPrimarySurface,
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
          ),
          const SizedBox(height: 8),
          QuickActionTile(
            icon: AppIcons.gallery,
            title: l10n.cameraSourceGalleryOption,
            iconBackgroundColor: colors.background,
            onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
          ),
        ],
      );
    },
  );
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    this.icon,
    this.svgIcon,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData? icon;
  final String? svgIcon;
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
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconBackgroundColor, borderRadius: BorderRadius.circular(13)),
                child: svgIcon != null
                    ? AppSvgIcon(svgIcon!, size: 22, color: colors.textPrimary)
                    : Icon(icon, size: 22, color: colors.textPrimary),
              ),
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
